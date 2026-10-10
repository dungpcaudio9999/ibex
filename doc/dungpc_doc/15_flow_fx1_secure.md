# 15 — Flow cấu hình `fx1_secure`: config → lint → compile → mô phỏng

> Toàn bộ nội dung dưới đây **đã chạy thành công** trên máy này (VCS X-2025.06,
> Verilator 5.008, 2026-09-28): lint sạch, compile OK, **5/5 test PASS**
> (`riscv_arithmetic_basic_test`, `riscv_rand_instr_test`, `riscv_debug_basic_test`,
> `mcounteren_test`, `mcounteren_lock_test`).
>
> Đây là flow **gộp** cho riêng profile `fx1_secure` — không lặp lại chi tiết đã có ở
> [13_mo_phong_vcs.md](13_mo_phong_vcs.md) (kiến trúc luồng mô phỏng UVM, cách dump
> waveform, coverage…), chỉ trích những gì khác biệt/quan trọng khi làm việc với
> `fx1_secure`. Nguồn quyết định cấu hình: `doc/info/FTEL_FX1_Secure_CPU.xlsx`, sheet
> `FX1-Config2`, cột "Final FX1"; xem rationale đầy đủ ở
> [20_fx1_findings.md](cpu_design/l3_rtl_deep_dive/20_fx1_findings.md) mục 9–10.

---

## 1. Bước 0 — Cấu hình (`ibex_configs.yaml`)

Profile `fx1_secure` đã có sẵn trong [`ibex_configs.yaml`](../../ibex_configs.yaml):

```yaml
fx1_secure:
  BaseIsa                  : "ibex_pkg::BaseIsaRV32I"
  RV32E                    : 0
  RV32M                    : "ibex_pkg::RV32MFast"
  RV32B                    : "ibex_pkg::RV32BNone"
  RV32ZC                   : "ibex_pkg::RV32ZcaZcb"
  RegFile                  : "ibex_pkg::RegFileFF"
  BranchTargetALU          : 1
  WritebackStage           : 1
  ICache                   : 0
  ICacheECC                : 0
  ICacheScramble           : 0
  BranchPredictor          : 0
  DbgTriggerEn             : 1
  SecureIbex               : 1
  PMPEnable                : 1
  PMPGranularity           : 0
  PMPNumRegions            : 16
  MHPMCounterNum           : 2
  MHPMCounterWidth         : 32
  MemECC                   : 1
  DbgHwBreakNum            : 4
```

Khác các profile `fx1_secure_dev/prod/adj` cũ hơn ở: `BaseIsa=RV32I` (bỏ hẳn
CHERIoT), `RV32ZC=ZcaZcb`, `MemECC=1`, `DbgHwBreakNum=4`, và **không** ghi đè
`ResetAll`/`DummyInstructions` (mặc định theo `SecureIbex=1`).

**Tham số CHƯA cấu hình được qua yaml** (không phải thiếu sót — phụ thuộc dữ
liệu chưa tồn tại trong repo): `PMPRstCfg`/`PMPRstAddr` (cần memory map FX1 SoC
thật), `CsrMvendorId`/`CsrMimpId`, `RndCnstLfsrSeed/Perm`/`RndCnstIbexKey/Nonce`
(bí mật trước tape-out). Plumbing cho `PMPRstMsecCfg`/`CsrMvendorId`/`CsrMimpId`
đã có trong `util/ibex_config.py` + `rtl/ibex_top_tracing.sv` +
`dv/uvm/core_ibex/tb/core_ibex_tb_top.sv`, sẵn sàng dùng khi có giá trị thật.

> ⚠️ **Đừng bật `PMPRstMsecCfg.mmwp=1` một mình.** Đã kiểm chứng bằng simulation:
> nếu bật `mmwp=1` mà `PMPRstCfg` vẫn "tất cả OFF" (chưa có entry ROM/MMIO
> permissive), core bị default-deny toàn bộ M-mode ngay từ reset → fail ngay
> lệnh đầu tiên (`Cosim mismatch ... register x10`). Xem FX1-H5 trong
> `20_fx1_findings.md`.

Đổi cấu hình bằng cách sửa file trên, hoặc thêm profile mới cùng cấu trúc.
Kiểm tra nhanh config có parse được không, không cần build gì:

```bash
cd /home/dungpc/projects/cpu_fx1/ibex
python3 util/ibex_config.py fx1_secure query_fields BaseIsa RV32ZC MemECC DbgHwBreakNum
```

---

## 2. Bước 1 — Lint

### 2.1 Điều kiện công cụ trên máy này

Máy **không có sẵn** `verilator`/`verible-verilog-lint` trong PATH mặc định, và
gói `edalize` cài qua pip (0.3.3) **thiếu** `edalize/version.py` khiến
`util/check_tool_requirements.py` báo lỗi `Unable to import edalize to check
version` dù `edalize` import được bình thường. Cách giải quyết đã kiểm chứng:

```bash
# 1. Verilator build sẵn (cần PERL5LIB để tránh lỗi FindBin.pm)
export PATH=/tmp/opencode/verilator-build-v5.008/bin:$PATH
export PERL5LIB=/tmp/opencode/perllib

# 2. venv riêng với edalize mới hơn (không đụng gói pip toàn máy)
python3 -m venv /path/to/lint_venv
source /path/to/lint_venv/bin/activate
pip install -q fusesoc "edalize>=0.4" packaging pyyaml pathlib3x mako pydantic

# 3. Kiểm tra
cd /home/dungpc/projects/cpu_fx1/ibex
python3 util/check_tool_requirements.py
# → INFO: Tool verilator present ...
# → INFO: Tool edalize present ...
```

### 2.2 Chạy lint

```bash
source /path/to/lint_venv/bin/activate
export PATH=/tmp/opencode/verilator-build-v5.008/bin:$PATH
export PERL5LIB=/tmp/opencode/perllib
cd /home/dungpc/projects/cpu_fx1/ibex

fusesoc --cores-root . run --target=lint --tool=verilator lowrisc:ibex:ibex_top_tracing \
  --BaseIsa=ibex_pkg::BaseIsaRV32I --RV32E=0 --RV32M=ibex_pkg::RV32MFast \
  --RV32B=ibex_pkg::RV32BNone --RV32ZC=ibex_pkg::RV32ZcaZcb \
  --RegFile=ibex_pkg::RegFileFF --BranchTargetALU=1 --WritebackStage=1 \
  --ICache=0 --ICacheECC=0 --BranchPredictor=0 --DbgTriggerEn=1 --SecureIbex=1 \
  --PMPEnable=1 --PMPGranularity=0 --PMPNumRegions=16 \
  --MHPMCounterNum=2 --MHPMCounterWidth=32
```

Các giá trị `--Field=` chính là output của
`python3 util/ibex_config.py fx1_secure fusesoc_opts` (chỉ gồm các field trong
`Config.known_fields` — `MemECC`/`DbgHwBreakNum` optional không nằm trong danh
sách tham số fusesoc lint của `ibex_top.core`, không ảnh hưởng kết quả lint).

**Kết quả trên máy này:** `verilator --lint-only -Wall --unroll-count 72` →
**exit 0, không warning.**

> Verible không có sẵn trên máy này (không tìm thấy `verible-verilog-lint`
> trong PATH lẫn filesystem) — chưa chạy được bước lint Verible, chỉ Verilator.

---

## 3. Bước 2 — Compile testbench (UVM `core_ibex`, VCS)

```bash
cd /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex
make IBEX_CONFIG=fx1_secure SIMULATOR=vcs GOAL=rtl_tb_compile
```

### ⚠️ Gotcha bắt buộc phải biết: cache metadata không invalidate theo tham số

`out/metadata/metadata.pickle` chỉ được tạo **một lần**; mọi lần `make` sau đó
trong cùng thư mục `out/` — dù đổi `IBEX_CONFIG`, `TEST`, hay bất kỳ tham số
nào khác — **đều bị bỏ qua lặng lẽ**, dùng lại config/test-list cũ
(`scripts/metadata.py:363` chỉ kiểm tra file đã tồn tại, không so sánh args).
Log sẽ vẫn in `Repeating ... because variable ... has changed value` nhưng
thực chất **không** regenerate.

**Luôn `make clean` trước khi đổi `IBEX_CONFIG` hoặc `TEST` trong cùng thư mục:**

```bash
make clean   # xoá out/ + riscv_dv_extension/riscv_core_setting.sv
```

Kiểm tra config nào thực sự được compile vào TB (sau khi build xong):

```bash
grep -o "+define+IBEX_CFG_[A-Za-z0-9_]*=[^ ]*" out/build/tb/compile_tb_stdstreams.log | sort -u
grep -o "\-pvalue+core_ibex_tb_top\.[A-Za-z0-9_]*=[^ ]*" out/build/tb/compile_tb_stdstreams.log | sort -u
```

Với `fx1_secure`, kỳ vọng thấy `IBEX_CFG_BaseIsa=ibex_pkg::BaseIsaRV32I` (không
phải `BaseIsaRV32IorCHERIoT`) và `-pvalue+core_ibex_tb_top.MemECC=1`.

---

## 4. Bước 3 — Mô phỏng smoke test

```bash
cd /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex
make clean   # nếu vừa đổi IBEX_CONFIG — xem cảnh báo mục 3
make IBEX_CONFIG=fx1_secure SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test ITERATIONS=1 SEED=1 WAVES=0 COV=0
cat out/run/regr.log
```

Kết quả trên máy này: `100.00% PASS 1 PASSED, 0 FAILED`.

## 5. Bước 4 — Regression mở rộng (đã chạy, khuyến nghị làm trước mọi thay đổi cấu hình khác)

```bash
make clean
make --keep-going IBEX_CONFIG=fx1_secure SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test,riscv_rand_instr_test,riscv_debug_basic_test,mcounteren_test,mcounteren_lock_test \
     ITERATIONS=1
cat out/run/regr.log
```

Kết quả trên máy này: **5/5 PASS**, không cosim mismatch. Bộ test này cố tình
chọn để chạm vào đúng những gì `fx1_secure` thay đổi so với `opentitan`:
`riscv_rand_instr_test` (decode path với `BaseIsa`/`RV32ZC`/`RV32B` mới),
`riscv_debug_basic_test` (`DbgTriggerEn`/`DbgHwBreakNum`), `mcounteren_test`/
`mcounteren_lock_test` (`MHPMCounterNum=2`).

Dump waveform (`WAVES=1`), coverage (`COV=1`), test khác… xem chi tiết đầy đủ
tại [13_mo_phong_vcs.md](13_mo_phong_vcs.md) mục 3.4–3.6 — cơ chế giống hệt,
chỉ đổi `IBEX_CONFIG=fx1_secure`.

---

## 6. Việc còn lại trước khi coi `fx1_secure` là "sign-off ready"

Đây là smoke test L3→L4 sơ bộ, **không** thay thế backlog đầy đủ. Xem
[20_fx1_findings.md](cpu_design/l3_rtl_deep_dive/20_fx1_findings.md) mục 6–10:

1. **FX1-H1** (lockstep + `ResetAll=1`, X-prop) — vẫn mở, cần L4 riêng.
2. **PMPRstCfg/PMPRstAddr thật** — chờ memory map FX1 SoC, sau đó mới bật lại
   `PMPRstMsecCfg.mmwp=1` (không được bật riêng lẻ — xem FX1-H5).
3. **CsrMvendorId/CsrMimpId** — chờ quyết định JEDEC ID / version encoding.
4. **RndCnstLfsrSeed/Perm, RndCnstIbexKey/Nonce** — sinh giá trị bí mật riêng
   trước tape-out (không ảnh hưởng smoke test chức năng ở trên).
5. Regression đầy đủ (`TEST=all`), coverage, và các test `*_intg_*`/
   `core_ibex_fetch_en_chk_test` kiểm chứng countermeasure (ECC, PC mismatch,
   RF glitch) riêng cho `fx1_secure`.
