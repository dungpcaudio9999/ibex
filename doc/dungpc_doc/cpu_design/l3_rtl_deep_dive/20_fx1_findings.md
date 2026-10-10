# 20 — FX1 findings và verification backlog

## 1. Executive conclusion

Static L3 review không thấy đủ bằng chứng để gọi FX1 configuration sai, nhưng
nó xác định các điểm phải được chứng minh trước sign-off. Rủi ro cao nhất là tổ
hợp `SecureIbex=1`, lockstep active, `ResetAll=0`, `MemECC=0`; tiếp theo là ISA/
firmware compatibility do `RV32BNone` và Zca-only.

## 2. Priority findings

### FX1-H1 — Lockstep với `ResetAll=0`

- **Fact:** Shadow reset/compare enable có sequencing riêng; payload flops có thể
  không reset.
- **Risk:** X/mismatch hoặc dependence on uninitialized payload trước first write.
- **Required evidence:** 4-state X-prop, randomized reset release, gate-level if
  available, compare DEV versus DEV-resetall.
- **Exit:** no spurious/missed compare across defined reset assumptions.

### FX1-H2 — Memory integrity disabled

- **Fact:** Main/shadow can receive same corrupted bus response; MemECC logic is
  generated out.
- **Risk:** Common-input data/instruction corruption not detected by lockstep.
- **Required decision:** External fabric ECC or accepted security reduction.
- **Exit:** documented threat coverage and integration test.

### FX1-H3 — Firmware ISA compatibility

- **Fact:** FX1 removes OTEarlGrey bitmanip and Zcb/Zcmp, changes M latency.
- **Risk:** Existing OpenTitan firmware binary traps or build libraries emit
  unsupported instructions.
- **Required evidence:** binary disassembly audit, toolchain `-march`, boot ROM/
  library regression.
- **Exit:** zero unsupported opcodes or explicit emulation/rebuild plan.

### FX1-H4 — Missing design record

- **Fact:** YAML references nonexistent `doc/fx1_secure_config_eval.md`.
- **Risk:** Requirements/rationale for countermeasure overrides cannot be audited.
- **Exit:** restore/create reviewed decision record and link tests to each choice.

## 3. Medium findings

### FX1-M1 — DEV/PROD debug delta

DEV enables two triggers; PROD disables triggers while keeping count field. Need
CSR read/write, trigger match and debug-module integration tests for both.

### FX1-M2 — HPM delta

DEV has four optional counters, PROD zero. Verify absent counters read zero,
writes ignored/illegal as designed, and software does not assume availability.

### FX1-M3 — CHERIoT/PMP mode boundary

PMP errors/address switching gate off in CHERIoT mode. Verify one-way enable
transition has no access-control gap and invalid MuBi encoding alerts/fails safe.

### FX1-M4 — TRVK integration assumptions

Interconnect must preserve two-beat capability ordering and maximum two
outstanding responses. Add integration assertions at SoC boundary.

### FX1-M5 — No I-cache

Functional risk low, but cache-control CSR/FENCE.I/software expectations and
performance targets require explicit verification.

## 4. Low/maintenance findings

- Config optional fields require TB/top defaults kept synchronized.
- Existing Vietnamese docs mostly describe OpenTitan; labels must not imply FX1.
- Large untracked output directories are not reproducible evidence.
- ShadowCSR is disabled despite SecureIbex; security matrix should say so.

## 5. FX1 feature matrix

| Mechanism | DEV | PROD | Evidence status |
|---|---:|---:|---|
| Lockstep | on | on | static traced; dynamic pending |
| Split RF ECC | on | on | static traced; injection pending |
| MemECC | off | off | config confirmed; threat decision pending |
| ResetAll | off | off | config confirmed; X-prop pending |
| Dummy instructions | off | off | config confirmed |
| DIT support | on | on | runtime timing tests pending |
| PC increment check | on | on | injection test pending |
| PMP RV32 | on | on | boundary regression pending |
| CHERIoT/TRVK | on | on | directed/integration pending |
| Debug triggers | 2 | off | delta tests pending |
| Optional HPM | 4 | 0 | CSR tests pending |

## 6. Recommended L4 order

1. Freeze tool/config manifest and smoke both DEV/PROD.
2. Reset/lockstep/X-prop comparison with DEV-resetall.
3. ISA binary audit and arithmetic/branch/MUL-DIV smoke.
4. LSU grant/response/misaligned matrix.
5. Exception/IRQ/debug precision.
6. PMP boundaries and mode switch.
7. CHERIoT authority/CLC/CSC.
8. TRVK/error/fault injection.
9. Differential regression and final accepted-risk record.

## 7. Sign-off artifacts required

- Versioned FX1 configuration rationale.
- Parameter/elaborated hierarchy report.
- Firmware ISA compatibility report.
- Reset/X-prop report.
- Security-countermeasure coverage matrix.
- Protocol assumption list signed by interconnect owner.
- Reproducible regression commands/seeds/results.
- Waivers for every open formal/coverage hole.

## 8. Scope statement

These are L3 findings, not confirmed silicon defects. Items labeled risk/open
become conclusions only after L4 simulation, formal proof, synthesis/netlist or
system-integration evidence as appropriate.

## 9. Cập nhật 2026-09-28 — profile `fx1_secure` theo xlsx Final FX1

`doc/info/FTEL_FX1_Secure_CPU.xlsx` (sheet `FX1-Config2`, cột "Final FX1") là
design record chính thức thay thế `doc/fx1_secure_config_eval.md` bị thiếu
(đóng **FX1-H4**). Đã thêm profile `fx1_secure` trong `ibex_configs.yaml`,
khác các profile `fx1_secure_dev/prod/adj` cũ ở:

- `BaseIsa = BaseIsaRV32I` (bỏ hẳn CHERIoT, không chỉ tắt runtime).
- `RV32ZC = RV32ZcaZcb` (giữ Zcb, bỏ Zcmp).
- `MemECC = 1` — **đóng FX1-H2** (bus integrity bật lại thay vì tắt).
- `DbgHwBreakNum = 4`, `MHPMCounterNum = 2`.
- `ResetAll`/`DummyInstructions` không bị ghi đè → mặc định theo `SecureIbex = 1`
  (khác `fx1_secure_dev` vốn tắt hai cái này để cô lập lỗi X-prop ở FX1-H1 —
  **FX1-H1 vẫn mở**, cần L4 X-prop trước khi tin `ResetAll = 1` an toàn).
- `PMPRstMsecCfg` — tham số mới thêm vào `rtl/ibex_top_tracing.sv` +
  `tb/core_ibex_tb_top.sv`, ghi đè được qua yaml (`util/ibex_config.py`), nhưng
  **KHÔNG bật** trong profile này (xem finding FX1-H5 bên dưới).

**Sửa lỗi phát hiện khi thêm profile:** macro `` `define IBEX_CFG_BaseIsa ``/
`` IBEX_CFG_RegFile `` do `ibex_config.py` sinh ra không khớp với
`` `ifndef IBEX_CFG_BASE_ISA ``/`` IBEX_CFG_REG_FILE `` cũ trong
`core_ibex_tb_top.sv` → override `BaseIsa`/`RegFile` bị lặng lẽ bỏ qua, VCS luôn
mô phỏng `BaseIsaRV32IorCHERIoT`/`RegFileFF` bất kể yaml. Vô hại với các profile
cũ (giá trị mặc định trùng ý muốn) nhưng sẽ khiến `fx1_secure` (BaseIsa=RV32I)
mô phỏng sai cấu hình nếu không sửa. Đã đổi tên macro khớp nhau.

**Vẫn chưa cấu hình được (chờ input, không tự đặt giá trị):**

- `PMPRstCfg[16]`/`PMPRstAddr[16]` (ROM NAPOT, MMIO TOR) — phụ thuộc memory map
  thật của FX1 SoC, hiện chưa tồn tại trong repo (`Ref-MemoryMap` chỉ có tham
  chiếu Simple System/OpenTitan Earl Grey). Đã thêm 2 tham số này vào
  `ibex_top_tracing.sv` (default = `ibex_pkg::PmpCfgRst`/`PmpAddrRst`, tức mọi
  region OFF) để sẵn sàng override thủ công qua `-pvalue+` khi có memory map.
- `CsrMvendorId`/`CsrMimpId` — đã wiring xuyên suốt (mặc định 0), chờ quyết định
  JEDEC ID / RTL version encoding.
- `RndCnstLfsrSeed/Perm`, `RndCnstIbexKey/Nonce` — giữ default công khai cho mô
  phỏng (không ảnh hưởng chức năng); phải sinh giá trị bí mật riêng trước
  tape-out, không phải trước sign-off chức năng.

### FX1-H5 — `PMPRstMsecCfg.mmwp=1` không thể bật độc lập với `PMPRstCfg`

- **Fact (kiểm chứng bằng simulation, không phải suy đoán):** thử bật
  `PMPRstMsecCfg = rlb=1,mmwp=1,mml=0` trong khi `PMPRstCfg` vẫn ở default
  "tất cả 16 region OFF" (vì chưa có memory map FX1 để định nghĩa entry ROM/
  MMIO) → `riscv_arithmetic_basic_test` FAIL ngay từ lệnh gần đầu tiên:
  `UVM_FATAL ... Cosim mismatch DUT didn't write to register x10, but a write
  was expected` (`out/run/tests/riscv_arithmetic_basic_test.1/rtl_sim_stdstreams.log`,
  build với `IBEX_CONFIG=fx1_secure`, VCS X-2025.06, 2026-09-28).
- **Nguyên nhân:** `mmwp=1` (ePMP Machine Mode Whitelist Policy) chuyển M-mode
  sang default-deny — nếu không có bất kỳ PMP entry nào permissive, mọi truy
  cập lệnh/dữ liệu của M-mode bị chặn ngay từ reset, kể cả fetch instruction
  đầu tiên. Đây chính xác là điều dòng 11 của xlsx đã cảnh báo ("Tất cả OFF +
  MMWP = 0: ROM phải tự cấu hình PMP, có cửa sổ không bảo vệ") — hàm ý ngược
  lại: MMWP = 1 mà "tất cả OFF" thì core không boot được, không phải "có cửa
  sổ không bảo vệ" mà là "không chạy được gì cả".
- **Đã revert:** bỏ `PMPRstMsecCfg` khỏi profile `fx1_secure` trong
  `ibex_configs.yaml`, quay lại default RTL (`rlb=mmwp=mml=0`). Plumbing
  (`ibex_config.py`/`ibex_top_tracing.sv`/`core_ibex_tb_top.sv`) vẫn giữ
  nguyên để dùng khi có `PMPRstCfg`/`PMPRstAddr` thật.
- **Exit:** không bật `PMPRstMsecCfg.mmwp=1` cho tới khi `PMPRstCfg`/
  `PMPRstAddr` được cấu hình cùng lúc với ít nhất 1 entry permissive bao phủ
  vùng chạy code + `signature_addr` của testbench (hoặc ROM/MMIO thật của FX1
  SoC). Coi đây là điều kiện tiên quyết bắt buộc, không phải tuỳ chọn độc lập.

## 10. Kết quả lint/compile/sim với `fx1_secure` (máy này, 2026-09-28)

- **Lint (Verilator, `fusesoc --target=lint --tool=verilator lowrisc:ibex:ibex_top_tracing`
  với tham số fx1_secure):** sạch, exit 0, không warning.
- **Compile TB (VCS X-2025.06, `make IBEX_CONFIG=fx1_secure SIMULATOR=vcs
  GOAL=rtl_tb_compile`):** thành công. **Lưu ý vận hành:** đổi `IBEX_CONFIG`
  trong một `out/` đã tồn tại (từ lần chạy `opentitan` trước) KHÔNG tự làm mới
  `out/metadata/metadata.pickle` (`scripts/metadata.py:363` chỉ kiểm tra file
  đã tồn tại chưa, không so sánh args) → compile âm thầm dùng lại config cũ dù
  `IBEX_CONFIG` mới được truyền. Bắt buộc `make clean` trước khi đổi
  `IBEX_CONFIG` trong cùng thư mục `dv/uvm/core_ibex`.
- **Sim smoke test sau khi bỏ `PMPRstMsecCfg`** (`make clean` bắt buộc trước mỗi
  lần đổi `IBEX_CONFIG`/`TEST`, xem cảnh báo ở trên): 5/5 PASS —
  `riscv_arithmetic_basic_test`, `riscv_rand_instr_test` (rand-instr, exercise
  decode path với `BaseIsa=RV32I`/`RV32ZC=ZcaZcb`/`RV32B=None`),
  `riscv_debug_basic_test` (`DbgTriggerEn=1`/`DbgHwBreakNum=4`),
  `mcounteren_test`, `mcounteren_lock_test` (`MHPMCounterNum=2`). Không có
  cosim mismatch. Đây là bằng chứng L4 sơ bộ đầu tiên hợp lệ cho `fx1_secure`;
  chưa thay thế được backlog L4 đầy đủ ở mục 6.

