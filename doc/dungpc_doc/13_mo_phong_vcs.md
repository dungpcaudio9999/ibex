# 13 — Mô phỏng cấu hình `opentitan` bằng VCS

> Toàn bộ nội dung dưới đây **đã được chạy thử thành công** trên chính máy này
> (VCS X-2025.06, ngày 2026-09-16): build testbench + chạy `riscv_arithmetic_basic_test`
> → kết quả `100.00% PASS 1 PASSED, 0 FAILED`.

---

## 1. Chọn luồng mô phỏng

Repo có 3 môi trường, nhưng **chỉ một** hỗ trợ VCS:

| Môi trường | Đường dẫn | Simulator hỗ trợ | Dùng được cho opentitan? |
|---|---|---|---|
| **UVM `core_ibex`** | `dv/uvm/core_ibex` | xlm, **vcs**, questa, riviera, dsim | ✅ **Đây là luồng cần dùng** |
| `simple_system` | `examples/simple_system` | **Chỉ Verilator** (harness C++ `ibex_simple_system.cc`) | ❌ |
| `tb_cs_registers` | `dv/cs_registers` | Chỉ Verilator | ❌ (chỉ test CSR) |

Môi trường UVM `core_ibex` mặc định đã đặt `IBEX_CONFIG := opentitan`
(`dv/uvm/core_ibex/Makefile:48`), nên đây là cấu hình "first-class" của repo.

Kiến trúc luồng:

```
riscv-dv (SystemVerilog generator, chạy bằng chính VCS)
    │ sinh test.S ngẫu nhiên có ràng buộc
    ▼
riscv32-unknown-elf-gcc  →  test.o → test.bin
    │
    ├──────────────────────────────┐
    ▼                              ▼
VCS simv (UVM TB + ibex_top)   Spike cosim (DPI, link thẳng vào simv)
    │ RVFI                          │
    └──────────► ibex_cosim_scoreboard so khớp từng lệnh ◄──┘
                         │
                         ▼
                  trr.yaml → regr.log
```

Spike **không** chạy như tiến trình riêng — nó được link vào `simv` qua DPI
(`dv/uvm/core_ibex/ibex_dv_cosim_dpi.f`) và so khớp **từng lệnh retire** qua RVFI.

---

## 2. Điều kiện cần

Máy này **đã có sẵn tất cả**:

| Thành phần | Yêu cầu | Trạng thái trên máy |
|---|---|---|
| VCS | ≥ 2020.03-SP2 (`util/tool_requirements.py:10`) | ✅ `X-2025.06` tại `/opt/synopsys/vcs/X-2025.06` |
| Verdi (tuỳ chọn, để dump FSDB) | — | ✅ `VERDI_HOME=/opt/synopsys/verdi/X-2025.06` |
| Spike bản lowRISC cosim | nhánh `ibex_cosim` | ✅ `/home/dungpc/tools/spike-cosim` |
| `PKG_CONFIG_PATH` trỏ tới spike | `riscv-riscv`, `riscv-disasm`, `riscv-fdt`, `riscv-fesvr` | ✅ đã set |
| RISC-V toolchain | `RISCV_GCC`, `RISCV_OBJCOPY` | ✅ `lowrisc-toolchain-rv32imcb` |
| Python deps | `python-requirements.txt` | ✅ (`fusesoc`, `pathlib3x`, `mako`, `pydantic`, …) |
| UVM 1.2 | đi kèm VCS | ✅ `$VCS_HOME/etc/uvm-1.2` |

Kiểm tra nhanh lại trước khi chạy:

```bash
vcs -ID | head -3
spike --help 2>&1 | head -2
pkg-config --exists riscv-riscv riscv-disasm riscv-fdt riscv-fesvr && echo "spike pkgconfig OK"
echo "$RISCV_GCC"; echo "$RISCV_OBJCOPY"
python3 -c "import pathlib3x, mako, pydantic, yaml; print('py deps OK')"
```

Nếu máy khác chưa có, cần export:

```bash
export SPIKE_PATH=$SPIKE_INSTALL_DIR/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$SPIKE_INSTALL_DIR/lib/pkgconfig
export RISCV_TOOLCHAIN=/duong/dan/toolchain
export RISCV_GCC=$RISCV_TOOLCHAIN/bin/riscv32-unknown-elf-gcc
export RISCV_OBJCOPY=$RISCV_TOOLCHAIN/bin/riscv32-unknown-elf-objcopy
```

---

## 3. Lệnh chạy

Tất cả chạy từ `dv/uvm/core_ibex`:

```bash
cd /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex
```

### 3.1 Chạy một test (đã kiểm chứng)

```bash
make IBEX_CONFIG=opentitan \
     SIMULATOR=vcs \
     ISS=spike \
     TEST=riscv_arithmetic_basic_test \
     ITERATIONS=1 \
     SEED=1 \
     WAVES=0 COV=0
```

Kết quả thực tế:

```
Building RTL testbench
Generating core configuration file
Building randomized test generator
Running randomized test generator to create assembly file .../test.S
Compiling riscvdv test assembly to create binary at .../test.bin
Running RTL simulation at .../riscv_arithmetic_basic_test.1
Collecting simulation results and checking logs ...
Collecting up results of tests into report regr.log
100.00% PASS 1 PASSED, 0 FAILED
```

> Lần đầu mất ~10–15 phút (build VCS toàn bộ UVM env + riscv-dv generator).
> Các lần sau chỉ chạy lại phần cần thiết.

### 3.2 Chỉ build testbench (không chạy test)

```bash
make IBEX_CONFIG=opentitan SIMULATOR=vcs GOAL=rtl_tb_compile
```

Sinh ra `out/build/tb/vcs_simv` (~225 MB).

### 3.3 Chạy nhiều test / regression

```bash
# Nhiều test, phân tách bằng dấu phẩy
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test,riscv_rand_instr_test,riscv_debug_basic_test \
     ITERATIONS=2

# Toàn bộ regression (TEST=all là mặc định) — RẤT lâu
make --keep-going IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike TEST=all
```

`--keep-going` để một test fail không dừng cả regression.

### 3.4 Dump waveform

```bash
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test SEED=1 WAVES=1
```

Cơ chế (`dv/uvm/core_ibex/vcs.tcl`):
* Có `VERDI_HOME` (máy này có) → dump **FSDB**: `out/run/tests/<test>.<seed>/waves.fsdb`,
  gồm `fsdbDumpvars 0 core_ibex_tb_top +all` và `fsdbDumpSVA 0 core_ibex_tb_top.dut`.
* Không có Verdi → dump **VPD**: `waves.vpd`.

Mở bằng Verdi:
```bash
verdi -ssf out/run/tests/riscv_arithmetic_basic_test.1/waves.fsdb &
```

> `WAVES=1` thêm `-debug_access+all` lúc compile nên **bắt buộc build lại** TB
> (stamp phụ thuộc `SIMULATOR COV WAVES` — `scripts/ibex_sim.mk:8`).

### 3.5 Coverage

```bash
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike TEST=all COV=1
```

VCS coverage options (`yaml/rtl_simulation.yaml`):
* Compile: `-cm line+tgl+assert+fsm+branch -cm_tgl portsonly -cm_tgl structarr -cm_hier cover.cfg`
* Run: `-cm_dir <dir_shared_cov>/test.vdb -cm_name test_<test>_<seed> +enable_ibex_fcov=1`
* Merge: `scripts/merge_cov.py` gọi `urg` — **có hỗ trợ vcs**

⚠️ Một hạn chế đã quan sát được: `collect_results.py` in
`Warning: Not generating coverage summary, unsupported simulator vcs`
→ phần **tóm tắt coverage trong `regr.log`** chưa hỗ trợ VCS (chỉ xlm).
Database `.vdb` vẫn được tạo và merge bình thường; xem báo cáo bằng `urg`/`dve` trực tiếp.

### 3.6 Chạy directed test (không qua riscv-dv)

```bash
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike TEST=mcounteren_test
```

Danh sách ở `directed_tests/directed_testlist.yaml` (gồm `empty`, `mcounteren_test`,
`mcounteren_lock_test`, `pmp_mseccfg_test_*`, `access_pmp_overlap`, `u_mode_exec_test`).

### 3.7 Dọn dẹp

```bash
make clean     # xoá out/ và riscv_dv_extension/riscv_core_setting.sv
```

---

## 4. Các knob của Makefile

`dv/uvm/core_ibex/Makefile:20-56`:

| Biến | Mặc định | Ý nghĩa |
|---|---|---|
| `IBEX_CONFIG` | `opentitan` | Tên config trong `ibex_configs.yaml` |
| `SIMULATOR` | `xlm` | → **đặt `vcs`** |
| `ISS` | `spike` | ISS để cosim (`spike` \| `ovpsim`) |
| `TEST` | `all` | Tên test, hoặc danh sách phân tách bằng dấu phẩy |
| `ITERATIONS` | (theo testlist) | Số seed mỗi test; ghi đè `iterations:` trong yaml |
| `SEED` | `$RANDOM` | Seed cho cả generator và RTL sim |
| `WAVES` | `0` | Dump sóng |
| `COV` | `0` | Bật coverage |
| `VERBOSE` | `0` | Log chi tiết |
| `GOAL` | `all` | Dừng ở một stage: `rtl_tb_compile`, `rtl_sim_run`, `check_logs`, `collect_results`… |
| `SIGNATURE_ADDR` | `8ffffffc` | Địa chỉ handshake pass/fail |

Các stage (`wrapper.mk` + `scripts/ibex_sim.mk`):
```
core_config → instr_gen_build → instr_gen_run → compile_riscvdv_tests
            → rtl_tb_compile → rtl_sim_run → check_logs
            → riscv_dv_fcov → merge_cov → collect_results
```

---

## 5. Cấu trúc thư mục kết quả

```
dv/uvm/core_ibex/out/
├── metadata/                       # trạng thái build (stamp files)
├── build/
│   ├── tb/
│   │   ├── vcs_simv                # ← file thực thi
│   │   ├── vcs_simv.csrc/  .daidir/
│   │   ├── compile_tb.log          # log compile của VCS
│   │   └── compile_tb_stdstreams.log
│   └── instr_gen/                  # riscv-dv generator
└── run/
    ├── regr.log                    # ← BÁO CÁO TỔNG HỢP
    └── tests/riscv_arithmetic_basic_test.1/
        ├── test.S                  # assembly sinh ra
        ├── test.o / test.bin
        ├── gen.log                 # log generator
        ├── rtl_sim.log             # (vcs: dùng rtl_sim_stdstreams.log)
        ├── rtl_sim_stdstreams.log  # ← LOG MÔ PHỎNG CHÍNH
        ├── trace_core_00000000.log # trace RTL (ibex_tracer)
        ├── rtl_trace.csv
        ├── spike_cosim_trace_core_00000000.log   # trace Spike
        ├── trr.yaml                # kết quả dạng máy đọc
        └── waves.fsdb              # nếu WAVES=1
```

Xem kết quả:
```bash
cat out/run/regr.log
tail -50 out/run/tests/<test>.<seed>/rtl_sim_stdstreams.log
diff <(cut -d' ' -f2- out/run/tests/<test>.<seed>/trace_core_00000000.log) \
     out/run/tests/<test>.<seed>/spike_cosim_trace_core_00000000.log | head
```

Tiện ích có sẵn:
```bash
make dump       # objdump binary của test
make prettify   # format lại log
```

---

## 6. Tham số cấu hình được truyền vào VCS như thế nào

`scripts/ibex_cmd.py` gọi `util/ibex_config.py opentitan vcs_opts` với hai tuỳ chọn thêm:
`--ins_hier_path core_ibex_tb_top --string_define_prefix IBEX_CFG_`.

VCS **không override được parameter kiểu enum/string** qua command line, nên có hai cơ chế:

**(a) Parameter `int`/`bit` → `-pvalue+`:**
```
-pvalue+core_ibex_tb_top.RV32E=0
-pvalue+core_ibex_tb_top.BranchTargetALU=1
-pvalue+core_ibex_tb_top.WritebackStage=1
-pvalue+core_ibex_tb_top.ICache=1
-pvalue+core_ibex_tb_top.ICacheECC=1
-pvalue+core_ibex_tb_top.ICacheScramble=1
-pvalue+core_ibex_tb_top.BranchPredictor=0
-pvalue+core_ibex_tb_top.DbgTriggerEn=1
-pvalue+core_ibex_tb_top.SecureIbex=1
-pvalue+core_ibex_tb_top.PMPEnable=1
-pvalue+core_ibex_tb_top.PMPGranularity=0
-pvalue+core_ibex_tb_top.PMPNumRegions=16
-pvalue+core_ibex_tb_top.MHPMCounterNum=10
-pvalue+core_ibex_tb_top.MHPMCounterWidth=32
```

**(b) Parameter enum → `+define+IBEX_CFG_*`**, TB đọc lại bằng `` `ifndef ``
(`tb/core_ibex_tb_top.sv:43-69`).

Ngoài ra `compile_tb.py` thêm các define địa chỉ cố định:
```
+define+DM_ADDR=1A11_0000  +define+DM_ADDR_MASK=0000_0FFF
+define+BOOT_ADDR=8000_0000
+define+DEBUG_MODE_HALT_ADDR=8000_0000  +define+DEBUG_MODE_EXCEPTION_ADDR=8000_0008
```
và `ibex_dv_defines.f` thêm `+define+TRACE_EXECUTION +define+RVFI +define+UVM`.

> **Lưu ý:** `BOOT_ADDR=8000_0000` nên PC reset = `0x8000_0080`
> (xem `ibex_if_stage.sv` `PC_BOOT: fetch_addr_n = {boot_addr_i[31:8], 8'h80}`).
> `DmHaltAddr`/`DmExceptionAddr` ở đây **khác** giá trị mặc định `0x1A1108xx` của RTL —
> chúng bị ép về `0x8000_0000`/`0x8000_0008` để khớp Spike (Spike hard-code
> `DEBUG_ROM_ENTRY`/`DEBUG_ROM_TVEC`).

### ⚠️ Sai lệch tên macro (cần biết nếu đổi config)

Đối chiếu tên macro **truyền vào** với tên macro **TB kiểm tra**:

| Truyền vào VCS | TB kiểm tra (`ifndef`) | Khớp? | Giá trị TB thực dùng |
|---|---|---|---|
| `IBEX_CFG_BaseIsa` | `IBEX_CFG_BASE_ISA` | ❌ | default `BaseIsaRV32IorCHERIoT` |
| `IBEX_CFG_RV32M` | `IBEX_CFG_RV32M` | ✅ | `RV32MSingleCycle` |
| `IBEX_CFG_RV32B` | `IBEX_CFG_RV32B` | ✅ | `RV32BOTEarlGrey` |
| `IBEX_CFG_RegFile` | `IBEX_CFG_REG_FILE` | ❌ | default `RegFileFF` |
| `IBEX_CFG_RV32ZC` | (TB **không có** parameter `RV32ZC`) | ❌ | `ibex_top` default `RV32ZcaZcbZcmp` |

Macro Verilog **phân biệt hoa/thường**, nên `IBEX_CFG_BaseIsa` ≠ `IBEX_CFG_BASE_ISA`.

**Với riêng `opentitan` thì vô hại** — cả ba giá trị mặc định đều **trùng khớp** giá trị
mong muốn (`BaseIsaRV32IorCHERIoT`, `RegFileFF`, `RV32ZcaZcbZcmp`). Nhưng nếu bạn chuyển
sang config khác (ví dụ `small` cần `BaseIsaRV32I` + `RV32Zca`) thì **VCS sẽ âm thầm mô
phỏng sai cấu hình**. Muốn sửa: đổi tên macro trong `tb/core_ibex_tb_top.sv` thành
`IBEX_CFG_BaseIsa`/`IBEX_CFG_RegFile` và thêm parameter `RV32ZC` vào TB + instantiation.

Kiểm tra lại bất cứ lúc nào:
```bash
grep -o "+define+IBEX_CFG_[A-Za-z0-9_]*=[^ ]*" out/build/tb/compile_tb_stdstreams.log | sort -u
grep -n "IBEX_CFG" tb/core_ibex_tb_top.sv
```

---

## 7. Lệnh VCS thật được sinh ra

Nếu muốn chạy VCS tay (debug build), đây là lệnh compile thực tế (rút gọn):

```bash
vcs -full64 \
    -f dv/uvm/core_ibex/ibex_dv_defines.f \
    -f dv/uvm/core_ibex/ibex_dv.f \
    -l out/build/tb/compile_tb.log \
    -sverilog -ntb_opts uvm-1.2 \
    +define+UVM +define+UVM_REGEX_NO_DPI \
    -timescale=1ns/10ps -licqueue \
    -LDFLAGS '-Wl,--no-as-needed' \
    -Mdir=out/build/tb/vcs_simv.csrc -o out/build/tb/vcs_simv \
    -debug_access+pp -xlrm uniq_prior_final \
    -CFLAGS '--std=c99 -fno-extended-identifiers' \
    -lca -kdb -debug_access+f \
    <các -pvalue+ và +define+IBEX_CFG_* ở §6> \
    -f dv/uvm/core_ibex/ibex_dv_cosim_dpi.f \
    -LDFLAGS '-Wl,-rpath,$SPIKE/lib' \
    -CFLAGS '-I$SPIKE/include -I$SPIKE/include/softfloat -Idv/cosim' \
    -lriscv -lsoftfloat -ldl -ldisasm -lfdt -lfesvr -L$SPIKE/lib -lstdc++
```

Và lệnh chạy:

```bash
env SIM_DIR=out/run/tests/<test>.<seed> \
  out/build/tb/vcs_simv \
    +vcs+lic+wait \
    +ntb_random_seed=<seed> \
    +UVM_TESTNAME=core_ibex_base_test \
    +UVM_VERBOSITY=UVM_LOW \
    +bin=out/run/tests/<test>.<seed>/test.bin \
    +ibex_tracer_file_base=out/run/tests/<test>.<seed>/trace_core \
    +cosim_log_file=out/run/tests/<test>.<seed>/spike_cosim_trace_core_00000000.log \
    +signature_addr=8ffffffc \
    +test_timeout_s=<timeout> \
    -l out/run/tests/<test>.<seed>/rtl_sim.log
```

Định nghĩa gốc: `dv/uvm/core_ibex/yaml/rtl_simulation.yaml`, mục `- tool: vcs`.

Danh sách file RTL: `dv/uvm/core_ibex/ibex_dv.f`, dùng biến môi trường
`${PRJ_DIR}` (gốc repo) và `${LOWRISC_IP_DIR}` (`vendor/lowrisc_ip`).
File này **là nguồn chính xác** cho danh sách RTL — lưu ý `src_files.yml` ở gốc repo
đã lỗi thời (thiếu file CHERIoT, còn tham chiếu `ibex_counters.sv` không tồn tại).

---

## 8. Danh sách test

### RISC-V DV (ngẫu nhiên có ràng buộc) — `riscv_dv_extension/testlist.yaml`

`riscv_arithmetic_basic_test`, `riscv_machine_mode_rand_test`, `riscv_rand_instr_test`,
`riscv_rand_jump_test`, `riscv_jump_stress_test`, `riscv_loop_test`,
`riscv_mmu_stress_test`, `riscv_illegal_instr_test`, `riscv_hint_instr_test`,
`riscv_ebreak_test`, `riscv_debug_basic_test`, `riscv_debug_triggers_test`,
`riscv_debug_stress_test`, `riscv_debug_branch_jump_test`, `riscv_debug_instr_test`,
`riscv_debug_wfi_test`, `riscv_dret_test`, `riscv_debug_ebreak_test`,
`riscv_debug_ebreakmu_test`, `riscv_debug_csr_entry_test`, …

### UVM test class — `tests/*.sv`

`core_ibex_base_test`, `core_ibex_csr_test`, `core_ibex_debug_*`, `core_ibex_irq_*`,
`core_ibex_mem_error_test`, `core_ibex_icache_intg_test`, `core_ibex_pc_intg_test`,
`core_ibex_rf_intg_test`, `core_ibex_rf_addr_intg_test`, `core_ibex_ram_intg_test`,
`core_ibex_fetch_en_chk_test`, `core_ibex_reset_test`, `core_ibex_perf_test`,
`core_ibex_directed_test`, …

Các test `*_intg_*` và `core_ibex_fetch_en_chk_test` chính là để kiểm chứng những
countermeasure mô tả trong [11_security.md](11_security.md) — chúng chủ động bơm lỗi
(ECC, PC mismatch, register-file glitch) và kiểm tra alert được phát ra đúng.

---

## 9. Xử lý sự cố

| Triệu chứng | Nguyên nhân / cách xử lý |
|---|---|
| `Failed to find [...] pkg-config packages` | `PKG_CONFIG_PATH` chưa trỏ tới `$SPIKE/lib/pkgconfig` (`scripts/compile_tb.py:94-99`) |
| `The environment variable 'PRJ_DIR' is not set` | Phải chạy `make` từ `dv/uvm/core_ibex` (wrapper.mk tự export) |
| TB build lại dù không sửa gì | Stamp phụ thuộc `SIMULATOR COV WAVES`; đổi bất kỳ biến nào → rebuild |
| Lỗi license VCS | `+vcs+lic+wait` đã có sẵn trong lệnh sim; compile dùng `-licqueue` |
| `regr.log` không có mục coverage | Đã biết: `collect_results.py` chưa hỗ trợ summary cho vcs (xem §3.5) |
| Cosim mismatch | So `trace_core_00000000.log` với `spike_cosim_trace_core_00000000.log` |
| Muốn tắt cosim | Không có knob trực tiếp — `ibex_dv_cosim_dpi.f` luôn được link. Cần sửa `yaml/rtl_simulation.yaml` |
| Test timeout | Tăng `timeout_s` trong testlist, hoặc dùng `+test_timeout_s=` |

---

## 10. Tóm tắt — copy & chạy

```bash
cd /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex

# 1. Chạy một test có sóng
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test ITERATIONS=1 SEED=1 WAVES=1

# 2. Xem kết quả
cat out/run/regr.log

# 3. Mở sóng
verdi -ssf out/run/tests/riscv_arithmetic_basic_test.1/waves.fsdb &
```
