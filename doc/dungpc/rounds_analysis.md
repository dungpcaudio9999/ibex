# Phân tích Ibex theo vòng

Tài liệu tích luỹ: mỗi vòng phân tích được ghi nối tiếp vào file này.

## Bối cảnh chung (áp dụng cho mọi vòng)

- **Nguồn**: `/home/dungpc9/ndmoney4porche/projects/ibex`
- **Nhánh**: `feature/pc-work`, HEAD `8031c7dd` (2026-09-08)
- **Remote**: `https://github.com/dungpcaudio9999/ibex.git` (fork cá nhân của lowRISC/ibex)
- **Lịch sử**: 2962 commit, từ 2015-04-01 (gốc PULP "Zero-riscy") đến 2026-09
- **Điểm khác upstream**: fork này đã hiện thực **CHERIoT ISA** (commit `f1cea015`, `506eb31f`,
  `7015eb67`, `c238a226`, `8b8ee086`), thêm `ibex_cheriot_ex.sv`, `ibex_cheriot_pkg.sv`,
  `ibex_trvk.sv`. Bản quyền dòng đầu file có "Copyright Microsoft Corporation".

### Mục lục các vòng
- [Vòng 0 — Tổng quan](#vòng-0--tổng-quan)
- [Vòng 1 — Cấu hình](#vòng-1--cấu-hình)
- [Vòng 2 — Bản đồ tĩnh](#vòng-2--bản-đồ-tĩnh)
- [Vòng 3 — Giao dịch với bên ngoài](#vòng-3--giao-dịch-với-bên-ngoài)
- [Vòng 4 — Verification: bằng chứng chứ không phải lời hứa](#vòng-4--verification-bằng-chứng-chứ-không-phải-lời-hứa)

### Tiện ích
- [`scripts/install_tools.sh`](scripts/install_tools.sh) — cài fusesoc/verilator/yosys/RISC-V GCC

---

# Vòng 0 — Tổng quan


## 1. ISA và extension chính xác

**`RV32{I|E}MC` + B + Zc + Zicsr/Zicntr/Zihpm/Zifencei — 32-bit, không có `A`, không có `F/D`, không có 64-bit.**

| Hạng mục | Kết luận | Bằng chứng |
|---|---|---|
| XLEN | 32 bit cố định. `CSR_MISA_MXL = 2'd1` (MXL=1 → RV32) | `rtl/ibex_pkg.sv:709` |
| Base ISA | RV32I (v2.1) **hoặc** RV32E (v1.9 draft), tham số `RV32E` | `rtl/ibex_top.sv:27`; `doc/01_overview/compliance.rst:16-18` |
| **A (Atomic)** | **KHÔNG** — bit 0 của MISA hardcode `0`; không có `OPCODE_AMO` trong decoder | `rtl/ibex_cs_registers.sv:189`; `rtl/ibex_pkg.sv:73-85` |
| **F / D (Float)** | **KHÔNG** — MISA bit 3 (D) và bit 5 (F) hardcode `0`; không có FPU, không `OPCODE_OP_FP` | `rtl/ibex_cs_registers.sv:191,193` |
| **C (Compressed)** | **CÓ**, luôn bật (MISA bit 2 = 1), v2.0 | `rtl/ibex_cs_registers.sv:190`; `rtl/ibex_compressed_decoder.sv` |
| **M (Mul/Div)** | Tuỳ chọn: `RV32MNone / RV32MSlow / RV32MFast / RV32MSingleCycle` | `rtl/ibex_cs_registers.sv:30,180,196` |
| **B (Bitmanip)** | Tuỳ chọn: ratified v1.0.0 (Zba/Zbb/Zbc/Zbs) + draft v0.93 (Zbe/Zbf/Zbp/Zbr/Zbt) | `doc/01_overview/compliance.rst:36-38,75-79` |
| **Zc** | Tuỳ chọn: `RV32Zca / ZcaZcb / ZcaZcmp / ZcaZcbZcmp` (v1.0.0) | `rtl/ibex_pkg.sv:63-66` |
| Zicsr, Zicntr, Zihpm, Zifencei | Luôn bật | `doc/01_overview/compliance.rst:40-54` |
| Smepmp | v1.0, luôn bật khi có PMP | `doc/01_overview/compliance.rst:62-64` |

### Điểm đặc thù của fork: CHERIoT

- Tham số `BaseIsa` có 2 giá trị: `BaseIsaRV32I` và `BaseIsaRV32IorCHERIoT`
  (*dual base ISA: RV32I/CHERIoT runtime switchable*) — `rtl/ibex_pkg.sv:37-39`.
- Chuyển đổi **lúc chạy** qua chân multi-bit `cheriot_enable_i` (kiểu `ibex_mubi_t`) —
  `rtl/ibex_top.sv:76`. Giá trị MuBi không hợp lệ sẽ raise alert (`8b8ee086`).
- Opcode riêng: `OPCODE_CHERI = 7'h5b`, `OPCODE_AUICGP = 7'h7b` — `rtl/ibex_pkg.sv:84-85`.
- Capability nén 32+1 bit theo spec CHERIoT v1.0 ch. 7.13: tag(1) + R(1) + cperms(6) +
  otype(3) + cexp(4) + top(9) + base(9); `REGCAP_W = 35` cho ECC — `rtl/ibex_cheriot_pkg.sv:10-28`.
- Quyền mở rộng 12 bit: U0/SE/US/EX/SR/MC/LD/SL/LM/SD/LG/GL — `rtl/ibex_cheriot_pkg.sv:38-52`.
- Khi CHERIoT bật, **mọi** lệnh (kể cả RV32I) bị giới hạn về x0–x15 → hàm ý RV32E — `c238a226`.
- MISA phản ánh động: bit I/E/X đổi theo `cheriot_enable_i` — `rtl/ibex_cs_registers.sv:377-390`.
- Module `ibex_trvk.sv`: temporal revocation filter (revocation bitmap trong meta-SRAM).

## 2. Privilege mode

**M + U (không có S, không có H).**

- `doc/01_overview/compliance.rst:66-68`: "Ibex currently supports ... **M-Mode and U-Mode**",
  theo Privileged Spec v1.12.
- MISA: bit 18 (S) = `0`, bit 20 (U) = `1`, bit 13 (N — user interrupt) = `0` —
  `rtl/ibex_cs_registers.sv:197-199`.
- Enum `priv_lvl_e` có khai báo `PRIV_LVL_H`/`PRIV_LVL_S` nhưng chỉ để đủ mã hoá 2 bit;
  RTL ép giá trị không hợp lệ về U: `mstatus.mpp` và `dcsr.prv` chỉ chấp nhận M hoặc U,
  ghi giá trị khác → về `PRIV_LVL_U` — `rtl/ibex_cs_registers.sv:784-785, 813-815`.
- ⇒ Không chạy được OS cần S-mode (Linux). Định vị là embedded control / microcontroller-class.

## 3. Tổ chức pipeline

**2 tầng (mặc định), tuỳ chọn 3 tầng; in-order, single-issue, scalar.**

- Mặc định 2 tầng: **IF** và **ID/EX** (decode + execute + đọc/ghi register file trong cùng 1 chu kỳ)
  — `doc/03_reference/pipeline_details.rst:11-17`, `doc/03_reference/instruction_decode_execute.rst:12-13`.
- Tầng thứ 3 tuỳ chọn: **Writeback**, bật bằng tham số `WritebackStage`
  — `doc/03_reference/pipeline_details.rst:27-31`; `rtl/ibex_top.sv:33`; `rtl/ibex_wb_stage.sv:6-13`.
  Khi `WritebackStage == 0`, module WB chỉ là passthrough.
- **Single-issue**: IPC tối đa = 1 — `doc/03_reference/pipeline_details.rst:23-24`.
  Lệnh đa chu kỳ làm **stall toàn bộ tầng ID/EX** (FSM nhỏ trong ID) chứ không cho lệnh sau vượt lên
  — `doc/03_reference/instruction_decode_execute.rst:21-22`.
- **In-order, writeback không ra khỏi thứ tự**: LSU yêu cầu bộ nhớ trả `rvalid` **đúng thứ tự phát**
  — `doc/03_reference/load_store_unit.rst:95`. Sắc thái duy nhất: dữ liệu load được LSU ghi
  **thẳng** vào register file ngay chu kỳ nhận được, bỏ qua đường WB thông thường
  — `rtl/ibex_wb_stage.sv:9-10`; đây là bypass đường ghi, không phải OoO completion.
  (I-cache có thể phục vụ hit trong bóng của một miss đang chờ — `doc/03_reference/icache.rst:165` —
  nhưng đó là nội bộ cache, không đổi thứ tự retire.)
- Prefetch buffer + fetch FIFO (`DEPTH = 3` mặc định) ở IF; giải nén lệnh C tại IF
  — `doc/03_reference/instruction_fetch.rst:13-22`.
- Branch predictor **tĩnh** tuỳ chọn (`BranchPredictor`), đánh dấu **EXPERIMENTAL**, tắt trong
  mọi config được hỗ trợ — `doc/03_reference/instruction_fetch.rst:31-39`; `ibex_configs.yaml`.

## 4. Bus interface

**KHÔNG phải AXI4 / AHB-Lite / TileLink / Wishbone.** Ibex dùng giao thức
`req` / `gnt` / `rvalid` gốc từ PULP — về mặt semantics tương thích **OBI (Open Bus Interface)**,
nhưng repo **không dùng tên "OBI"** ở bất kỳ đâu (grep toàn bộ `doc/` và `rtl/` → 0 hit),
và **không chứa bridge/adapter** sang bus chuẩn nào (`find` cho axi/ahb/tilelink/obi/wishbone → 0 file).

Hai cổng riêng biệt (Harvard ở mức giao diện), đều master:

| Cổng | Tín hiệu | Vị trí |
|---|---|---|
| Instruction | `instr_req_o`, `instr_gnt_i`, `instr_rvalid_i`, `instr_addr_o`, `instr_rdata_i`, `instr_err_i` | `rtl/ibex_top.sv:84-92` |
| Data | `data_req_o`, `data_gnt_i`, `data_rvalid_i`, `data_we_o`, `data_be_o[3:0]`, `data_addr_o`, `data_wdata_o`, `data_rdata_i`, `data_err_i` | `rtl/ibex_top.sv:93-101` |

Đặc tính giao thức (`doc/03_reference/load_store_unit.rst:88-95`):
1. `req` giữ cao đến khi `gnt` cao 1 chu kỳ; `gnt` có thể cùng chu kỳ hoặc trễ tuỳ ý.
2. Sau `gnt`, địa chỉ/wdata/we/be có thể đổi ngay chu kỳ sau (pipelined).
3. `rvalid` cao đúng 1 chu kỳ, kèm `rdata`/`err`; `err` cao → core raise exception.
4. Nhiều request outstanding được phép, nhưng **response phải in-order**.
5. Data bus rộng 32 bit; truy cập unaligned được LSU tách thành 2 giao dịch.

Khi bật `SecureIbex`/`MemECC`, mỗi cổng thêm tín hiệu integrity (`*_rdata_intg_i`,
`*_wdata_intg_o`) và cặp shadow (`data_req_shadow_o`, `instr_req_shadow_o`)
— `doc/02_user/integration.rst:174,182`.

Trong SoC thực (OpenTitan), việc chuyển sang TileLink-UL do wrapper bên ngoài Ibex đảm nhiệm,
không nằm trong repo này.

## 5. Mục tiêu thiết kế

**Tối ưu diện tích + bảo mật, cho embedded control — KHÔNG phải application-class chạy Linux.**

- README:1-13 — "production-quality open source 32-bit RISC-V CPU core ...
  heavily parametrizable and **well suited for embedded control applications**".
- Không có S-mode, không có MMU/page table → không chạy được Linux. Bảo vệ bộ nhớ bằng **PMP**
  (tuỳ chọn, `PMPNumRegions` 4/16) + Smepmp.
- Dải diện tích/hiệu năng theo config (README:31-36):

  | Config | micro | small | maxperf | maxperf-pmp-bmfull |
  |---|---|---|---|---|
  | Features | RV32EC | RV32IMC, mult 3-cycle | RV32IMC, mult 1-cycle, BTALU, WB stage | + RV32B, 16 PMP |
  | CoreMark/MHz | 0.904 | 2.47 | 3.13 | 3.13 |
  | Area Yosys (kGE) | 16.85 | 26.60 | 32.48 | 66.02 |

  So sánh: CVA6 (application-class, RV64GC, MMU Sv39, chạy Linux) lớn hơn ~1 bậc độ lớn.
- Trục thứ hai rõ rệt là **security hardening** (`SecureIbex`), `doc/03_reference/security.rst`:
  - Data-independent timing (chống side-channel timing/power)
  - Dummy instruction insertion (LFSR, re-seed qua CSR `secureseed`)
  - **Dual-core lockstep** — shadow core chạy trễ `LockstepOffset` chu kỳ, so sánh output
    (`rtl/ibex_lockstep.sv`, `rtl/ibex_top.sv:212`)
  - ECC trên register file và I-cache; I-cache scrambling (`ICacheScramble`)
  - Bus integrity checking; 3 chân alert: `alert_major_internal_o`, `alert_major_bus_o`, `alert_minor_o`
  - Shadow CSR, PC hardening
- Fork này bổ sung trục thứ ba: **memory safety bằng capability (CHERIoT)** — spatial safety qua
  capability bounds/permissions, temporal safety qua TRVK revocation filter.

## 6. Độ chín và bằng chứng

**Ibex upstream: production-grade, đã tape-out nhiều lần. Phần CHERIoT trong fork này: chưa có bằng chứng verification/tape-out.**

### Bằng chứng độ chín (upstream)
- README:11 & `doc/01_overview/index.rst:6` — "extensively verified and has seen **multiple tape-outs**".
- **OpenTitan**: config `opentitan` trong `ibex_configs.yaml:40-60` chính là core dùng trong
  OpenTitan (silicon root of trust — đã có silicon Earl Grey). Đây là config duy nhất có
  nightly regression: https://ibex.reports.lowrisc.org/opentitan/latest/report.html
- **Verification stage V2S** cho config `opentitan` — `doc/01_overview/verification_overview.rst:17`,
  `doc/03_reference/verification_stages.rst:6-8`. Nghĩa là: >90% code + functional coverage,
  >90% regression pass rate, testplan + coverage plan đã hiện thực đầy đủ, **nhưng chưa đóng (not closed)**.
  Các config khác **chưa có** verification stage chính thức.
- Nguồn gốc: PULP "Zero-riscy" (paper PATMOS 2017, DOI 10.1109/PATMOS.2017.8106976),
  chuyển giao cho lowRISC — README:17-21.

### Hạ tầng verification trong repo
| Thành phần | Vị trí |
|---|---|
| UVM testbench + RISCV-DV random instruction generator | `dv/uvm/core_ibex/` |
| Co-simulation với Spike ISS (lowRISC fork) qua DPI | `dv/cosim/` (`spike_cosim.cc`, `cosim_dpi.cc`) |
| RVFI (RISC-V Formal Interface) trace port | `rtl/ibex_top.sv:138,474` (`\`ifdef RVFI`) |
| Formal: data-independent timing (mul/div/rem) | `formal/data_ind_timing/` (12 property file) |
| Formal: I-cache | `formal/icache/` |
| CS-register TB, riscv-compliance, Verilator | `dv/cs_registers/`, `dv/riscv_compliance/`, `dv/verilator/` |
| Testplan + coverage plan | `doc/03_reference/testplan.rst`, `coverage_plan.rst` |
| Synthesis flow (Yosys) | `syn/` |
| Simple System reference platform | `examples/simple_system/` |

### Trạng thái verification theo config (README:31-36 + `ibex_configs.yaml`)
- `small`, `maxperf`, `maxperf-pmp-bmfull`: **Green** (gần hoàn tất)
- `micro` (RV32EC): **Red** (verification tối thiểu/không có)
- README:49 cảnh báo rõ: *"Users must make their own assessment of verification readiness for any tapeout."*

### ⚠️ Cảnh báo về CHERIoT trong fork này
- Config `opentitan` trong repo này đã bị đặt `BaseIsa: BaseIsaRV32IorCHERIoT`
  (`ibex_configs.yaml:41`) — **khác upstream**. Con số V2S và nightly regression được trích dẫn ở
  documentation là của config `opentitan` **upstream (RV32I thuần)**, không phải của phiên bản
  dual-ISA CHERIoT này.
- CHERIoT được thêm vào tháng 8–9/2026, tất cả file doc verification **không** đề cập CHERIoT.
- Bit B trong extension draft v0.93 (Zbe/Zbf/Zbp/Zbr/Zbt) **chưa được ratify**, có thể thay đổi
  không tương thích ngược — `doc/01_overview/compliance.rst:75-79`.
- Branch predictor được đánh dấu EXPERIMENTAL và tắt ở mọi config hỗ trợ.

---

## Tóm tắt một dòng

Ibex là core RISC-V **RV32{I|E}MC(+B,+Zc)**, **M+U mode**, pipeline **2 tầng in-order single-issue**
(tuỳ chọn tầng WB thứ 3), bus **req/gnt/rvalid gốc (OBI-like)**, nhắm **embedded control tiết kiệm
diện tích + hardening bảo mật**, đã tape-out nhiều lần và đạt **V2S** ở config `opentitan`;
riêng fork này thêm **CHERIoT dual-ISA switch runtime** — phần mới, chưa có bằng chứng verification.

## Câu hỏi mở chuyển sang Vòng 1
1. Config `opentitan` sửa sang CHERIoT là chủ ý hay lỗi rebase? Có config CHERIoT riêng không?
2. `cheriot_enable_i` được drive từ đâu ở mức SoC? Đổi runtime an toàn ở thời điểm nào?
3. Interaction giữa PMP (16 vùng) và CHERIoT capability bounds — chồng lấn hay bổ trợ?
4. `ibex_trvk` đặt ở đâu trong hệ phân cấp bus, `NumOutstanding = 4` có đủ không?
5. Register file dùng chung RV32I/CHERIoT (`7015eb67`) — chi phí diện tích và ảnh hưởng ECC?
6. Lockstep shadow core có bao phủ đường dữ liệu CHERIoT không?

---

# Vòng 1 — Cấu hình

## 1. File nào định nghĩa parameter — ba tầng, không chồng chéo

Ibex **không sinh RTL tự động**. Đây là thiết kế *parameterised*, không phải *generated*.
Cấu hình đi qua 3 tầng, mỗi tầng có vai trò riêng:

| Tầng | File | Vai trò | Viết tay? |
|---|---|---|---|
| 1. Nguồn chân lý RTL | `rtl/ibex_top.sv:16-62` (40 parameter), `rtl/ibex_core.sv:18-59` | Khai báo + giá trị mặc định thật sự của phần cứng | Có |
| 2. Bộ config đặt tên | `ibex_configs.yaml` (8 config) | Đặt tên cho các tổ hợp parameter được hỗ trợ/thử nghiệm | Có |
| 3. Khai báo cho build system | `ibex_top.core`, `ibex_core.core`, `ibex_top_tracing.core`… (FuseSoC CAPI=2) | Ánh xạ tên parameter → cờ trình biên dịch | Có |

Cầu nối giữa tầng 2 và 3 là **`util/ibex_config.py`** — một *translator*, không phải generator.
Nó đọc YAML, kiểm tra schema (`known_fields`, `util/ibex_config.py:23-41`) và **in ra chuỗi cờ dòng lệnh**:

```
$ python3 util/ibex_config.py small fusesoc_opts
--BaseIsa=ibex_pkg::BaseIsaRV32I --RV32E=0 --RV32M=ibex_pkg::RV32MFast
--RV32B=ibex_pkg::RV32BNone --RV32ZC=ibex_pkg::RV32Zca --RegFile=ibex_pkg::RegFileFF
--BranchTargetALU=0 --WritebackStage=0 --ICache=0 --ICacheECC=0 --ICacheScramble=0
--BranchPredictor=0 --DbgTriggerEn=0 --SecureIbex=0 --PMPEnable=0 --PMPGranularity=0
--PMPNumRegions=4 --MHPMCounterNum=0 --MHPMCounterWidth=40
```

Script này có nhiều backend output (`util/ibex_config.py`): `fusesoc_opts`, `query_fields`,
và các `SimOpts` cho VCS / Riviera / DSim / Xcelium (mỗi tool có cú pháp `-pvalue`/`-defparam` riêng).
Không hề có backend nào ghi ra file `.sv`.

### Chi tiết dễ vấp: enum truyền bằng `define, không phải parameter

Trong `ibex_top.core`, các parameter chia làm hai loại:

- **`paramtype: vlogparam`** (int/bit): `RV32E`, `ICache`, `ICacheECC`, `BranchTargetALU`,
  `WritebackStage`, `BranchPredictor`, `DbgTriggerEn`, `SecureIbex`, `ICacheScramble`,
  `PMPEnable`, `PMPGranularity`, `PMPNumRegions`, `MHPMCounterNum`, `MHPMCounterWidth`
  → truyền thẳng bằng `-G`/`-pvalue`.
- **`paramtype: vlogdefine`** (enum/str): `BaseIsa`, `RV32M`, `RV32B`, `RV32ZC`, `RegFile`
  → truyền bằng **macro tiền xử lý** (`+define+RV32M=ibex_pkg::RV32MFast`).
  Lý do: không tool nào truyền được literal enum của package qua cờ parameter.
  Macro được "hoàn nguyên" thành parameter ở tầng wrapper, ví dụ
  `examples/simple_system/rtl/ibex_simple_system.sv:59`:
  `parameter ibex_pkg::rv32m_e RV32M = ` + backtick + `RV32M;`

Hệ quả thực dụng: **`ibex_top` bản thân nó không đọc macro nào**. Nếu bạn instantiate `ibex_top`
trực tiếp trong SoC của mình, bạn phải tự truyền 5 enum này qua danh sách parameter —
cờ `+define+` chỉ có tác dụng nếu bạn dùng đúng các wrapper của repo.

### Điểm bất nhất phát hiện được: `src_files.yml` đã mục

`src_files.yml` (file list kiểu PULP legacy) **không đồng bộ với `rtl/`**:

- Liệt kê 2 file **không tồn tại**: `rtl/ibex_counters.sv` (tên thật là `ibex_counter.sv`),
  `rtl/ibex_core_tracing.sv` (tên thật là `ibex_top_tracing.sv`).
- **Thiếu 12 file** đang có trong `rtl/`: `ibex_top.sv`, `ibex_top_tracing.sv`, `ibex_icache.sv`,
  `ibex_lockstep.sv`, `ibex_branch_predict.sv`, `ibex_csr.sv`, `ibex_counter.sv`,
  `ibex_dummy_instr.sv`, `ibex_register_file_ff.sv`, và toàn bộ 3 file CHERIoT
  (`ibex_cheriot_pkg.sv`, `ibex_cheriot_ex.sv`, `ibex_trvk.sv`).

⇒ **Đừng dùng `src_files.yml`**. Nguồn file list đáng tin là các `.core` của FuseSoC
(`ibex_core.core`, `ibex_top.core`) và `rtl/ibex_core.f`.
(`ibex_core.f` cũng chưa có `ibex_cheriot_*` / `ibex_trvk.sv` — cần kiểm tra ở vòng sau.)

## 2. Cấu hình mặc định là gì — có ba "mặc định" khác nhau

Đây là chỗ dễ nhầm. Repo có **ba** khái niệm "mặc định" và chúng **không trùng nhau**:

| "Mặc định" | Nơi định nghĩa | Giá trị |
|---|---|---|
| **Mặc định của flow build** | `Makefile:5` → `IBEX_CONFIG ?= small` | config `small` |
| **Mặc định của RTL** (khi instantiate `ibex_top` không truyền gì) | `rtl/ibex_top.sv:16-62` | gần `small` nhưng **khác** |
| **Mặc định của FuseSoC** | các khối `default:` trong `ibex_top.core` | trùng RTL default |

**Khác biệt cụ thể giữa RTL default và config `small`:**

| Parameter | RTL default (`ibex_top.sv`) | config `small` |
|---|---|---|
| `RV32ZC` | `RV32ZcaZcbZcmp` (đủ Zca+Zcb+Zcmp) | **`RV32Zca`** (chỉ Zca) |
| `MHPMCounterWidth` | 40 | 40 (trùng) |
| `PMPNumRegions` | 4 | 4 (trùng) |

⇒ Nếu bạn instantiate `ibex_top` "trần" mà nghĩ mình đang có `small`, bạn thực ra có
thêm Zcb+Zcmp. Với mục tiêu "cấu hình nhỏ nhất", đây là diện tích thừa cần chú ý.

### YAML chỉ phủ 19/40 parameter

Đối chiếu bằng script: `ibex_top` có **40 parameter**, `ibex_configs.yaml` định nghĩa
**19**. **21 parameter còn lại không có trong bất kỳ config nào** — chúng chỉ nhận giá trị
mặc định của RTL, trừ khi SoC tích hợp tự truyền:

```
CheriotRevBitmapAddrWidth, CheriotRevBitmapBaseAddr, CsrMimpId, CsrMvendorId,
DbgHwBreakNum, DmAddrMask, DmBaseAddr, DmExceptionAddr, DmHaltAddr,
ICacheScrNumPrinceRoundsHalf, ICacheTweakInfection, LockstepOffset,
MemDataWidth, MemECC, PMPRstCfg, PMPRstAddr, PMPRstMsecCfg,
RndCnstIbexKey, RndCnstIbexNonce, RndCnstLfsrPerm, RndCnstLfsrSeed
```

Nhóm này quan trọng ở mức tích hợp SoC: địa chỉ debug module (`DmBaseAddr` mặc định
`32'h1A110000`, `DmHaltAddr` `32'h1A110800`), reset value của PMP, hằng số ngẫu nhiên
cho scrambling/LFSR, base address của revocation bitmap CHERIoT. Việc chúng không nằm
trong YAML nghĩa là **regression nightly không quét chúng** — chúng luôn ở giá trị mặc định
trong verification.

### 8 config có sẵn, chia 3 nhóm

| Nhóm | Config | Ghi chú |
|---|---|---|
| **SUPPORTED** | `small`, `opentitan`, `maxperf`, `maxperf-pmp-bmbalanced` | Nơi tập trung verification + design effort |
| **OTHER** | `maxperf-pmp`, `maxperf-pmp-bmfull`, `maxperf-pmp-bmfull-icache` | Hữu ích nhưng không được hỗ trợ |
| **EXPERIMENTAL** | `experimental-branch-predictor` | Chưa verify / có vấn đề đã biết |

⚠️ README bảng ở đầu repo nhắc tới config **`micro` (RV32EC)** với 16.85 kGE — nhưng
`micro` **không tồn tại trong `ibex_configs.yaml`**. Bảng README đã lệch khỏi YAML.

⚠️ Nhắc lại từ Vòng 0: config `opentitan` trong fork này đã bị đổi
`BaseIsa: BaseIsaRV32IorCHERIoT` (`ibex_configs.yaml:41`), khác upstream.

## 3. Chọn cấu hình để bám: **`small`**

**Lý do chọn:**
- Là mặc định của `Makefile` ⇒ mọi lệnh `make build-simple-system`, `make lint-core-tracing`
  chạy đúng config này mà không cần thêm cờ.
- Verification status **Green** (README) — sai sót phát hiện được nhiều khả năng là do ta hiểu sai,
  không phải do RTL hỏng.
- Nhỏ nhất trong nhóm SUPPORTED (~26.6 kGE), nhưng vẫn **còn thú vị**: có đủ M, C,
  pipeline 2 tầng hoàn chỉnh, LSU với unaligned access, exception/interrupt, debug.
- **Loại bỏ được đúng ba chủ đề khó chồng lên nhau**: không I-cache, không PMP,
  không SecureIbex (⇒ không lockstep, không ECC, không dummy instruction, không scrambling).
  Và vì `BaseIsa = BaseIsaRV32I` nên **cũng không có CHERIoT** — chủ đề khó thứ tư.

**Tham số đầy đủ của `small`** (`ibex_configs.yaml:19-37`):

```yaml
BaseIsa: BaseIsaRV32I    RV32E: 0                RV32M: RV32MFast
RV32B:   RV32BNone       RV32ZC: RV32Zca         RegFile: RegFileFF
BranchTargetALU: 0       WritebackStage: 0       BranchPredictor: 0
ICache: 0                ICacheECC: 0            ICacheScramble: 0
DbgTriggerEn: 0          SecureIbex: 0
PMPEnable: 0             PMPGranularity: 0       PMPNumRegions: 4
MHPMCounterNum: 0        MHPMCounterWidth: 40
```

### Localparam dẫn xuất — bảy thứ bị khoá theo `SecureIbex`

Điểm rất dễ bỏ sót: nhiều tính năng **không có parameter riêng**, chúng được suy ra
từ `SecureIbex`. Với `small` (`SecureIbex = 0`), tất cả đều tắt:

| Localparam | Công thức | Nơi | Giá trị với `small` |
|---|---|---|---|
| `Lockstep` | `= SecureIbex` | `ibex_top.sv:212` | 0 |
| `ResetAll` | `= Lockstep` | `ibex_top.sv:213` | 0 |
| `DummyInstructions` | `= SecureIbex` | `ibex_top.sv:214` | 0 |
| `RegFileLockstepECC` | `= Lockstep` | `ibex_top.sv:216` | 0 |
| `MemECC` | `= SecureIbex` (parameter, mặc định) | `ibex_top.sv:41` | 0 |
| `ICacheTweakInfection` | `= SecureIbex` (parameter, mặc định) | `ibex_top.sv:45` | 0 |
| `DataIndTiming` | `= SecureIbex` | `ibex_core.sv:195` | 0 |
| `PCIncrCheck` | `= SecureIbex` | `ibex_core.sv:196` | 0 |

Hai localparam bị **hardcode `0` bất kể config nào**, tức là *dead feature* trong toàn bộ repo:
- `RegFileECC = 1'b0` (`ibex_top.sv:215`) → nhánh `gen_regfile_ecc` (`ibex_core.sv:1214`)
  **không bao giờ được tổng hợp**.
- `ShadowCSR = 1'b0` (`ibex_core.sv:197`).

`ResetAll` cũng đáng chú ý: nó điều khiển ~8 cặp generate `g_*_ra` / `g_*_nr` khắp
`ibex_if_stage.sv` và `ibex_wb_stage.sv` (flop có reset toàn bộ vs. không reset).
Với `small` → luôn chọn nhánh `_nr` (không reset) ⇒ tiết kiệm diện tích, nhưng sau reset
các thanh ghi này là X trong simulation.

**Ràng buộc hợp lệ duy nhất được kiểm tra bằng assertion** (`ibex_core.sv:2437`):
```systemverilog
`ASSERT_INIT(IllegalParamSecure, !(SecureIbex && (RV32M == RV32MNone)))
```
(vì dummy instruction chèn lệnh mul/div). Ngoài ra **không có** assertion nào chặn tổ hợp
sai khác — ví dụ `ICacheECC=1` với `ICache=0` sẽ lặng lẽ không có tác dụng.

## 4. Khối nào thực sự tồn tại trong netlist với config `small`

> Phương pháp: phân tích tĩnh các khối `generate` (`if (...) begin : gen_*`) trong `rtl/`.
> Không có EDA tool nào cài trong môi trường này (`verilator`/`yosys`/`fusesoc` đều vắng),
> nên đây là suy luận từ RTL, **chưa được đối chiếu với netlist thật**.

### Cây phân cấp CÒN LẠI

```
ibex_top
├── u_fetch_enable_buf          (prim_buf, luôn có)
├── u_mcounteren_writable_buf   (prim_buf, luôn có)
├── gen_regfile_ff/register_file_i        → ibex_register_file_ff
└── ibex_core (u_ibex_core)
    ├── if_stage_i → ibex_if_stage
    │   ├── gen_prefetch_buffer/prefetch_buffer_i  → ibex_prefetch_buffer
    │   │                                             └── ibex_fetch_fifo
    │   └── compressed_decoder_i                   → ibex_compressed_decoder
    ├── id_stage_i → ibex_id_stage
    │   ├── decoder_i     → ibex_decoder
    │   └── controller_i  → ibex_controller
    ├── ex_block_i → ibex_ex_block
    │   ├── alu_i                        → ibex_alu
    │   └── gen_multdiv_fast/multdiv_i   → ibex_multdiv_fast
    ├── load_store_unit_i → ibex_load_store_unit
    ├── wb_stage_i        → ibex_wb_stage   ← chỉ là dây nối, xem bên dưới
    └── cs_registers_i    → ibex_cs_registers
        ├── 17 × ibex_csr   (mstatus, mie, mepc, mcause, mtval, mtvec, dcsr, …)
        └── 2 × ibex_counter (mcycle, minstret) — KHÔNG có counter biến thiên
```

### Bảng chi tiết: có / không, và bị loại bởi cơ chế nào

| Khối | Trong netlist? | Cơ chế loại bỏ | Vị trí |
|---|---|---|---|
| `ibex_prefetch_buffer` + `ibex_fetch_fifo` | ✅ **CÓ** | `ICache=0` → nhánh `else` | `ibex_if_stage.sv:348` |
| `ibex_icache` | ❌ | generate `if (ICache)` | `ibex_if_stage.sv:298-300` |
| `ibex_compressed_decoder` | ✅ **CÓ** | vô điều kiện (C luôn bật) | `ibex_if_stage.sv:485` |
| `ibex_dummy_instr` | ❌ | `DummyInstructions=0` | `ibex_if_stage.sv:504-509` |
| `ibex_branch_predict` | ❌ | `BranchPredictor=0` | `ibex_if_stage.sv:694` |
| `ibex_decoder`, `ibex_controller` | ✅ **CÓ** | vô điều kiện | `ibex_id_stage.sv:478,615` |
| Branch-target ALU | ❌ | `BranchTargetALU=0` → `g_nobtalu` | `ibex_id_stage.sv:369/407`, `ibex_ex_block.sv:94` |
| `ibex_alu` | ✅ **CÓ** | vô điều kiện | `ibex_ex_block.sv:116` |
| `ibex_multdiv_fast` | ✅ **CÓ** | `RV32M=RV32MFast` | `ibex_ex_block.sv:165-166` |
| `ibex_multdiv_slow` | ❌ | `RV32M≠RV32MSlow` | `ibex_ex_block.sv:140` |
| `ibex_load_store_unit` | ✅ **CÓ** | vô điều kiện | `ibex_core.sv:1066` |
| `ibex_wb_stage` | ⚠️ **CÓ nhưng rỗng** | xem ghi chú dưới | `ibex_core.sv:1125` |
| `ibex_cs_registers` | ✅ **CÓ** | vô điều kiện | `ibex_core.sv:1430` |
| `ibex_pmp` | ❌ | `PMPEnable=0` → `g_no_pmp` | `ibex_core.sv:1579/1635` |
| `ibex_register_file_ff` | ✅ **CÓ** | `RegFile=RegFileFF` | `ibex_top.sv:532-534` |
| `ibex_register_file_latch` / `_fpga` | ❌ | else-if chain | `ibex_top.sv:561,589` |
| `ibex_lockstep` (+ shadow core) | ❌ | `Lockstep=0` | `ibex_top.sv:873/1115` |
| `ibex_trvk` | ❌ | `BaseIsa≠…CHERIoT` | `ibex_top.sv:1275-1276` |
| `ibex_cheriot_ex` | ❌ | `BaseIsa≠…CHERIoT` | `ibex_core.sv:911-912` |
| `prim_ram_1p` / `prim_ram_1p_scr` (icache RAM) | ❌ | `ICache=0` → `gen_norams` | `ibex_top.sv:681/842` |
| ECC encode/decode bus (`prim_secded`) | ❌ | `MemECC=0` | `ibex_top.sv:360,863`; `ibex_lsu.sv:376,731` |
| ECC register file | ❌ | `RegFileECC` hardcode 0 | `ibex_core.sv:1214` |
| `ibex_csr` (CSR có flop) | ✅ **17 instance** | luôn có | `ibex_cs_registers.sv:1071-1345` |
| `ibex_counter` (mcycle, minstret) | ✅ 2 instance | luôn có | `ibex_cs_registers.sv:1621,1636` |
| `ibex_counter` (mhpmcounter3-31) | ❌ 0 instance | `MHPMCounterNum=0` → `gen_unimp` | `ibex_cs_registers.sv:1666-1672` |
| PMP CSR (`pmpcfg*`/`pmpaddr*`) | ❌ | `g_no_pmp_tieoffs` — nối `'0` | `ibex_cs_registers.sv:1531` |
| Debug trigger CSR (`tselect`/`tdata*`) | ❌ | `DbgTriggerEn=0` → `gen_trigger_regs` | `ibex_cs_registers.sv:1753` |
| CHERIoT SCR + `mshwm`/`mshwmb` | ❌ | `BaseIsa≠…CHERIoT` | `ibex_cs_registers.sv:1303,2002` |

### Ba lưu ý về "tồn tại trong netlist"

**(a) `ibex_wb_stage` vẫn được instantiate dù `WritebackStage=0`.**
Module có mặt trong cây phân cấp nhưng nhánh `g_bypass_wb` (`ibex_wb_stage.sv:248`) chỉ là
các phép gán thẳng — sau synthesis nó biến mất hoàn toàn thành dây nối, không còn flop nào.
Đây là "module rỗng", không phải "module bị loại". Khi đọc log synthesis, đừng ngạc nhiên
khi thấy tên nó xuất hiện với 0 cell.

**(b) Bitmanip (`RV32B=RV32BNone`) KHÔNG bị loại bằng generate.**
`ibex_alu.sv` dùng biểu thức ba ngôi rải rác trong logic tổ hợp, ví dụ:
```systemverilog
assign bfp_op   = (RV32B != RV32BNone) ? (operator_i == ALU_BFP) : 1'b0;   // :266
assign bfp_mask = (RV32B != RV32BNone) ? ~(32'hffff_ffff << bfp_len) : '0; // :269
```
Logic bitmanip chỉ biến mất nhờ **constant folding / dead-code elimination của công cụ
tổng hợp**, không nhờ elaboration. Hệ quả: bạn **không thể xác nhận nó đã bị loại bằng cách
đọc RTL** — phải xem báo cáo area thật. Tương tự với `DataIndTiming` trong `ibex_multdiv_*`.
Đây là khác biệt phương pháp luận quan trọng so với các khối dùng `generate`.

**(c) `ibex_ex_block` có comment lỗi thời.**
`ibex_ex_block.sv:70-74` viết: *"The multdiv_i output is never selected if RV32M=RV32MNone.
At synthesis time, all the combinational and sequential logic from the multdiv_i module are
eliminated"* — mô tả cơ chế constant-folding. Nhưng code hiện tại (`:140-190`) đã dùng
**generate** nên khi `RV32MNone` thì module **không được instantiate ngay từ elaboration**.
Comment mô tả cơ chế cũ. (Với `small` điều này không ảnh hưởng vì `RV32M=RV32MFast`.)

### Ước lượng quy mô

| | `small` | `maxperf-pmp-bmfull` |
|---|---|---|
| Area (Yosys, kGE) | 26.60 | 66.02 |
| CoreMark/MHz | 2.47 | 3.13 |

⇒ `small` chỉ ~40% diện tích của config lớn nhất, mà vẫn đạt 79% hiệu năng.
Đúng là điểm ngọt để bám theo.

## 5. Cách chạy (khi có tool)

```bash
make test-cfg                              # in ra cờ fusesoc của IBEX_CONFIG hiện tại
make build-simple-system                   # build với 'small' (mặc định)
IBEX_CONFIG=maxperf make build-simple-system
make lint-core-tracing                     # lint Verilator
python3 util/ibex_config.py small query_fields RV32M ICache PMPEnable
```

Yêu cầu ngoài repo: `fusesoc`, `verilator`, RISC-V toolchain
(`python-requirements.txt`, `flake.nix`). **Hiện chưa cài trong môi trường này** —
đã kiểm tra: `verilator`, `yosys`, `fusesoc`, `iverilog`, `sv2v` đều không có.
Mọi kết luận ở mục 4 là phân tích tĩnh, cần xác thực lại khi dựng được môi trường.

## Chốt Vòng 1

| Câu hỏi | Trả lời |
|---|---|
| File nào định nghĩa parameter | `rtl/ibex_top.sv:16-62` (40 param, nguồn chân lý) + `ibex_configs.yaml` (8 config, 19 param) + `*.core` (khai báo build) |
| Config mặc định | `small` (theo `Makefile:5`); RTL default hơi khác — `RV32ZC` là `ZcaZcbZcmp` thay vì `Zca` |
| Viết tay hay sinh tự động | **Viết tay hoàn toàn.** `util/ibex_config.py` chỉ *dịch* YAML → cờ dòng lệnh, không sinh RTL |
| Config đã chọn | **`small`** — nhỏ nhất trong nhóm SUPPORTED, Green verification, không icache/PMP/secure/CHERIoT |
| Khối trong netlist | 15 module thật (xem cây mục 4); loại bỏ icache, PMP, lockstep, dummy-instr, branch-predict, ECC, CHERIoT/TRVK, multdiv_slow, mhpmcounter |

## Câu hỏi mở chuyển sang Vòng 2

1. `rtl/ibex_core.f` thiếu `ibex_cheriot_*.sv` và `ibex_trvk.sv` — file list nào thực sự
   được dùng khi build config `opentitan` (đang bật CHERIoT)? `ibex_core.core` có đủ không?
2. Bảng README nhắc config `micro` không có trong YAML — số liệu 16.85 kGE lấy từ đâu, còn đúng không?
3. `RegFileECC` và `ShadowCSR` hardcode `0`: là dead code hay chờ được nối lên parameter?
4. Với `small`, `ResetAll=0` ⇒ nhiều flop không reset. Simple System khởi tạo chúng thế nào
   để simulation không kẹt X?
5. Tổ hợp parameter không hợp lệ hầu như không được assert. Có tổ hợp nào trong 8 config
   hiện tại đang lặng lẽ vô hiệu (ví dụ `ICacheECC` khi `ICache=0`) không?
6. 21 parameter ngoài YAML (đặc biệt `DmBaseAddr`, `PMPRstCfg`, `RndCnst*`) không được
   regression quét — rủi ro ở mức nào cho một lần tape-out?

---

# Vòng 2 — Bản đồ tĩnh

> **Trạng thái tool** (khác Vòng 1): đã cài `fusesoc 2.4.3` trong venv `~/.ibex-venv`
> và **chạy được `fusesoc --setup` thật**. Nhờ đó phần lớn kết luận dưới đây là
> **bằng chứng từ build system**, không còn là suy đoán từ đọc RTL.
> `verilator`/`yosys` vẫn chưa có (cần sudo hoặc OSS CAD Suite) — script cài:
> [`doc/dungpc/scripts/install_tools.sh`](scripts/install_tools.sh).

## 0. Bug phát hiện được ngay khi chạy build

Lệnh mà README/Makefile bảo chạy đầu tiên **thất bại**:

```
$ fusesoc --cores-root=. run --target=sim --setup lowrisc:ibex:ibex_simple_system \
      $(./util/ibex_config.py small fusesoc_opts)
fusesoc run lowrisc_ibex_ibex_simple_system_0: error: unrecognized arguments:
    --BaseIsa=ibex_pkg::BaseIsaRV32I
```

**Nguyên nhân**: commit `2910e539` *"[cheriot,rtl] Integrate TRVK filter into Ibex top"*
thêm parameter `BaseIsa` vào `ibex_configs.yaml` + `util/ibex_config.py` + một số `.core`,
nhưng **bỏ sót** `examples/simple_system/ibex_simple_system.core` và `ibex_core.core`.

| `.core` file | khai báo `BaseIsa`? |
|---|---|
| `ibex_top.core` | ✅ |
| `ibex_top_tracing.core` | ✅ |
| `dv/riscv_compliance/ibex_riscv_compliance.core` | ✅ |
| `dv/verilator/simple_system_cosim/ibex_simple_system_cosim.core` | ✅ |
| **`examples/simple_system/ibex_simple_system.core`** | ❌ **thiếu** |
| **`ibex_core.core`** | ❌ **thiếu** |

⇒ `make build-simple-system` và `make run-simple-system` — hai target chính của repo —
**hỏng trong fork này**. Cách chữa: thêm khối 4 dòng vào `parameters:` của
`examples/simple_system/ibex_simple_system.core`:
```yaml
  BaseIsa:
    datatype: str
    default: ibex_pkg::BaseIsaRV32I
    paramtype: vlogdefine
```
(Workaround tạm để phân tích: lọc bỏ cờ đó — `sed 's/--BaseIsa=[^ ]* //'`.)

## 1. Top module thật sự là gì — có **sáu** top khác nhau

Đúng như dự đoán: file tên `ibex_top.sv` **không phải** top của bất kỳ flow nào ngoài synthesis.
Bằng chứng lấy từ `grep -rn "toplevel:" --include=*.core` cộng với `config.mk` mà fusesoc sinh ra.

| Flow | Top module thật | Khai báo ở | Vai trò |
|---|---|---|---|
| **Simulation (Verilator)** | `ibex_simple_system` | `examples/simple_system/ibex_simple_system.core:139` | SoC harness: core + bus + RAM + DPI |
| **Co-simulation (Spike)** | `ibex_simple_system` | `dv/verilator/simple_system_cosim/…core:143` | như trên + cosim DPI |
| **UVM DV** | `core_ibex_tb_top` | `dv/uvm/core_ibex/tb/core_ibex_tb_top.sv:9` | TB harness UVM, không dùng bus/RAM thật |
| **RISC-V compliance** | `ibex_riscv_compliance` | `dv/riscv_compliance/…core:166` | SoC harness riêng cho compliance suite |
| **Synthesis (Yosys)** | `ibex_top` | `syn/tcl/lr_synth_flow_var_setup.tcl:8` | **Đây mới là chỗ `ibex_top` là top thật** |
| **Formal** | `ibex_top` / `ibex_multdiv_*` / `ibex_icache` | `dv/formal/ibex_formal.core:21`, `formal/*/…core` | top theo từng property |

### Bốn tầng bọc, mỗi tầng thêm đúng một thứ

Xác nhận bằng file list fusesoc sinh ra (`--top-module ibex_simple_system` trong `config.mk`):

```
ibex_simple_system              ← SoC harness  (examples/simple_system/rtl/, 389 dòng)
├── bus                         ← crossbar đơn giản   (shared/rtl/bus.sv)
├── ram_2p                      ← RAM chung instr+data (shared/rtl/ram_2p.sv)
└── ibex_top_tracing            ← WRAPPER TRACING     (rtl/ibex_top_tracing.sv, 428 dòng)
    ├── ibex_top                ← BIÊN CỦA IP         (rtl/ibex_top.sv, 1622 dòng)
    │   ├── ibex_register_file_ff        ← RF nằm NGOÀI core
    │   ├── (icache RAM, lockstep, trvk) ← đều ngoài core
    │   └── ibex_core           ← LÕI THUẦN           (rtl/ibex_core.sv, 2514 dòng)
    │       ├── ibex_if_stage
    │       ├── ibex_id_stage
    │       ├── ibex_ex_block
    │       ├── ibex_load_store_unit
    │       ├── ibex_wb_stage
    │       └── ibex_cs_registers
    └── ibex_tracer             ← chỉ ghi log, KHÔNG tổng hợp
```

**Ba ranh giới cần phân biệt rõ:**

- **`ibex_core`** = lõi thuần, 105 port. **Không chứa register file, không chứa RAM.**
  Đây là đơn vị "CPU logic".
- **`ibex_top`** = biên IP thật sự để tích hợp SoC, 110 port. Bọc thêm: register file
  (3 biến thể ff/latch/fpga), RAM của icache, `ibex_lockstep` (shadow core),
  `ibex_trvk`, clock gating, ECC bus. **Đây là thứ bạn instantiate trong SoC.**
- **`ibex_top_tracing`** = `ibex_top` + `ibex_tracer`, 66 port. Tracer chỉ sinh log
  thực thi cho debug/so sánh ISS — **`ibex_top_tracing` không dùng cho silicon.**

⚠️ Nghịch lý cần nhớ: `ibex_top_tracing` có **ít port hơn** `ibex_top` (66 vs 110) vì nó
chôn (tie-off) các cổng ECC/lockstep/RVFI mà harness sim không cần.
Đừng dùng số port để suy ra "cái nào cao hơn trong hệ phân cấp".

## 2. Ranh giới module và tín hiệu liên stage

### Quy mô các biên (đo bằng script, đếm khai báo `input`/`output`)

| Module | Ports | Dòng | Ghi chú |
|---|---:|---:|---|
| `ibex_id_stage` | **147** | 1303 | **Biên rộng nhất.** ID là trung tâm điều phối |
| `ibex_top` | 110 | 1622 | Biên IP |
| `ibex_core` | 105 | 2514 | Lõi thuần |
| `ibex_cs_registers` | 94 | 2262 | Rộng vì CSR chạm mọi thứ |
| `ibex_controller` | 83 | 1134 | FSM điều khiển |
| `ibex_cheriot_ex` | 83 | 1032 | Khối CHERIoT (không có ở `small`) |
| `ibex_decoder` | 67 | 1491 | |
| `ibex_if_stage` | 67 | 941 | |
| `ibex_top_tracing` | 66 | 428 | |
| `ibex_lockstep` | 65 | 751 | |
| `ibex_load_store_unit` | 40 | 837 | |
| `ibex_wb_stage` | 39 | 312 | |
| `ibex_trvk` | 38 | 421 | |
| `ibex_ex_block` | 26 | 218 | **Biên hẹp nhất trong đường dữ liệu** |
| `ibex_prefetch_buffer` | 19 | 268 | |
| `ibex_register_file_ff` | 16 | 330 | |
| `ibex_alu` | 15 | 1401 | Tỉ lệ dòng/port cao nhất — logic thuần |
| `ibex_fetch_fifo` | 15 | 301 | |
| `ibex_pmp` | 8 | 264 | |
| `ibex_csr` | 6 | 58 | Nguyên thuỷ, instantiate 17 lần |

**Quan sát**: `ibex_id_stage` với 147 port là điểm nghẽn hiểu biết của toàn thiết kế.
Nó không chỉ "decode" — nó cầm dây tới IF, EX, LSU, WB, CSR, register file, controller,
performance counter và (trong fork này) CHERIoT. Muốn hiểu Ibex thì phải đọc nó trước.

`ibex_ex_block` ngược lại chỉ 26 port — nó thật sự chỉ là "hộp chứa ALU + multdiv",
không giữ trạng thái điều khiển nào.

### Bảng tín hiệu liên stage (nhóm theo comment trong `rtl/ibex_id_stage.sv`)

| Nhóm | Số tín hiệu | Ghi chú |
|---|---:|---|
| Performance Counters | 29 | Nhóm lớn nhất — phần lớn là output đếm sự kiện |
| CSR | 17 | |
| Interface to IF stage | 13 | |
| IF and ID stage signals | 12 | jump/branch/PC control |
| Interrupt signals | 12 | |
| MUL, DIV | 9 | |
| Debug Signal | 9 | |
| Register write info from WB (data hazard) | 9 | Chỉ có nghĩa khi `WritebackStage=1` |
| Interface to load store unit | 6 | |
| Register file read | 6 | |
| Register file write (via writeback) | 5 | |
| ALU | 3 | |
| Multicycle Operation Stage Register | 3 | |
| Stalls | 2 | |
| Branch target ALU | 2 | Chỉ có nghĩa khi `BranchTargetALU=1` |

#### IF → ID (kênh cấp lệnh)

| Tín hiệu | Hướng (từ góc ID) | Ý nghĩa |
|---|---|---|
| `instr_valid_i` | in | có lệnh hợp lệ trong thanh ghi IF-ID |
| `instr_rdata_i` | in | lệnh đã giải nén (32-bit) |
| `instr_rdata_alu_i` | in | **bản sao** của `instr_rdata_i`, tách riêng để cắt đường timing tới ALU |
| `instr_rdata_c_i` | in | dạng nén 16-bit gốc (để nạp `mtval` khi illegal instruction) |
| `instr_is_compressed_i` | in | lệnh gốc là nén |
| `instr_bp_taken_i` | in | branch predictor đoán "taken" (chỉ khi `BranchPredictor=1`) |
| `instr_fetch_err_i` / `_plus2_i` | in | lỗi bus khi fetch / lỗi ở nửa sau lệnh lệch hàng |
| `illegal_c_insn_i` | in | bộ giải nén báo lệnh nén không hợp lệ |
| `pc_id_i` | in | PC của lệnh đang ở ID |
| `instr_req_o` | out | ID yêu cầu IF fetch tiếp |
| `id_in_ready_o` | out | **tín hiệu backpressure chính** — ID sẵn sàng nhận lệnh mới |
| `instr_valid_clear_o` | out | xoá lệnh đang giữ (flush) |
| `instr_first_cycle_id_o` | out | chu kỳ đầu của lệnh đa chu kỳ |

> `instr_rdata_alu_i` là ví dụ điển hình của tối ưu timing lộ ra ngoài biên module:
> hai cổng mang **cùng một giá trị**, tồn tại chỉ để synthesis nhân đôi driver.
> Đừng tưởng đó là hai lệnh khác nhau.

#### ID → IF (điều khiển luồng)

`pc_set_o`, `pc_mux_o`, `exc_pc_mux_o`, `exc_cause_o`, `nt_branch_mispredict_o`,
`nt_branch_addr_o`, `icache_inval_o`, `csr_mtvec_init_o`.
Chiều này **ngược** với luồng dữ liệu — mọi thay đổi PC (branch, jump, exception,
interrupt, debug entry) đều bắt nguồn từ ID/controller và đẩy ngược lên IF.

#### ID → EX

- ALU: `alu_operator_ex_o`, `alu_operand_a_ex_o`, `alu_operand_b_ex_o`
- Branch-target ALU: `bt_a_operand_o`, `bt_b_operand_o` *(chết khi `BranchTargetALU=0`)*
- MUL/DIV: `mult_en_ex_o`, `div_en_ex_o`, `mult_sel_ex_o`, `div_sel_ex_o`,
  `multdiv_operator_ex_o`, `multdiv_signed_mode_ex_o`, `multdiv_operand_a_ex_o`,
  `multdiv_operand_b_ex_o`, `multdiv_ready_id_o`
- Ngược lại: `result_ex_i`, `ex_valid_i`, `imd_val_we_ex_i` (thanh ghi giá trị trung gian
  cho lệnh đa chu kỳ — dùng chung giữa ALU và multdiv, xem `ibex_ex_block.sv:146-150`)

#### ID → LSU

`lsu_req_o`, `lsu_we_o`, `lsu_type_o`, `lsu_sign_ext_o`, `lsu_wdata_o`
→ ngược lại: `lsu_req_done_i`, `lsu_addr_incr_req_i`, `lsu_addr_last_i`,
`lsu_load_err_i`, `lsu_store_err_i`.

`lsu_addr_incr_req_i` là tín hiệu của **truy cập lệch hàng**: LSU báo ngược cho ID rằng
nó cần một giao dịch bus thứ hai. Đây là lý do một lệnh load/store có thể sinh 2 request
(và là gốc của `MaxOutstandingDSideAccesses = 2`, `ibex_top.sv:232`).

#### Register file (đi vòng qua `ibex_top`, không qua `ibex_core`)

Đọc: `rf_raddr_a_o`/`rf_raddr_b_o` + `rf_ren_a_o`/`rf_ren_b_o` → `rf_rdata_a_i`/`rf_rdata_b_i`
Ghi: `rf_waddr_id_o`, `rf_wdata_id_o`, `rf_we_id_o`

Vì register file được instantiate ở **`ibex_top`** (`ibex_top.sv:532`) chứ không phải trong
`ibex_core`, toàn bộ các tín hiệu này **xuyên qua biên `ibex_core`**. Đó là lý do
`ibex_core` có tới 105 port. Lý do thiết kế: cho phép thay RF bằng biến thể latch (ASIC)
hoặc BRAM (FPGA) mà không đụng vào lõi.

#### Data hazard (chỉ sống khi `WritebackStage=1`)

`rf_waddr_wb_i`, `rf_wdata_fwd_wb_i`, `rf_write_wb_i`, `rf_rd_a_wb_match_o`,
`rf_rd_b_wb_match_o`, `outstanding_load_wb_i`, `outstanding_store_wb_i`, `ready_wb_i`, `en_wb_o`.

**Với config `small` (`WritebackStage=0`) toàn bộ nhóm 9 tín hiệu này trở thành vô nghĩa**
— `ibex_wb_stage` chỉ passthrough nên không bao giờ có hazard. Chúng vẫn tồn tại trên biên
module (biên không phụ thuộc parameter), chỉ là logic phía sau bị constant-fold.
Đây là ví dụ rõ nhất của việc **biên module ≠ mạch thực tế**.

## 3. Quy ước đặt tên và di sản lịch sử

### Quy ước nhất quán (theo chuẩn lowRISC/OpenTitan)

| Hậu tố/tiền tố | Số lần xuất hiện | Nghĩa |
|---|---:|---|
| `_i` | 4194 | cổng input |
| `_o` | 2753 | cổng output |
| `_q` | 1412 | đầu ra thanh ghi (trạng thái hiện tại) |
| `_d` | 849 | đầu vào thanh ghi (trạng thái kế tiếp) |
| `_ni` | 396 | input tích cực mức thấp (`rst_ni`) |

Cặp `_d`/`_q` là quy ước then chốt: mọi flop viết dạng
`always_ff @(posedge clk_i) q <= d;` với logic kế tiếp nằm trong `always_comb` tính `_d`.
Tỉ lệ 1412 `_q` / 849 `_d` cho thấy nhiều `_q` được đọc ở nhiều nơi hơn số flop.

Hậu tố tầng: `_id`, `_ex`, `_wb`, `_if` gắn vào tên tín hiệu để chỉ tầng
(`alu_operand_a_ex_o` = toán hạng gửi *tới* tầng EX; `pc_id_i` = PC *của* tầng ID).

### Bất nhất thật sự — hai quy ước generate label cùng tồn tại

```
180 ×  begin : g_...
159 ×  begin : gen_...
```

Gần 50/50. `g_` là quy ước lowRISC/OpenTitan hiện hành; `gen_` là di sản cũ.
Chúng **trộn lẫn ngay trong cùng một file** — ví dụ `ibex_if_stage.sv` có
`gen_icache`/`gen_prefetch_buffer` (dòng 298/348) đứng cạnh `g_mem_ecc`/`g_secure_pc`
(dòng 259/659). Hệ quả thực dụng: **khi grep đường dẫn phân cấp hoặc viết ràng buộc
synthesis/formal, phải thử cả hai tiền tố.**

Tương tự với tên instance: `u_` (42 lần) vs hậu tố `_i` (26 lần) —
`u_prim_buf_instr_rdata` cạnh `prefetch_buffer_i`, `alu_i`, `multdiv_i`.

### Di sản lịch sử

| Lớp | Dấu vết |
|---|---|
| **RI5CY → Zero-riscy** (ETH Zurich / Univ. Bologna, PULP) | `doc/03_reference/history.rst:5` ghi rõ code được phát triển bằng cách **đơn giản hoá RI5CY**. 21/33 file trong `rtl/` vẫn mang dòng bản quyền *"Copyright 2018 ETH Zurich and University of Bologna"* |
| **lowRISC** (từ 2018) | 12 file **không** có dòng ETH — tức là hoàn toàn mới: `ibex_wb_stage`, `ibex_icache`, `ibex_pmp`, `ibex_lockstep`, `ibex_dummy_instr`, `ibex_branch_predict`, `ibex_csr`, `ibex_counter`, `ibex_top_tracing`, + 3 file CHERIoT |
| **Microsoft / CHERIoT** (2026) | `ibex_cheriot_pkg.sv`, `ibex_cheriot_ex.sv`, `ibex_trvk.sv` — và dòng *"Copyright Microsoft Corporation"* đã lan sang cả `ibex_top.sv`, `ibex_wb_stage.sv`, `ibex_top_tracing.sv` |

**Quy tắc đọc code rút ra**: file có header ETH → phong cách PULP cũ (`gen_`, hậu tố `_i`
cho instance, comment thưa). File không có → phong cách lowRISC (`g_`, tiền tố `u_`,
`prim_*` primitives, assertion `ASSERT_*` dày đặc).

## 4. Code dự án vs code bên thứ ba

### Ranh giới rất rõ: mọi thứ bên thứ ba nằm trong `vendor/`

| Thư mục | LOC (SV) | Files | Nguồn |
|---|---:|---:|---|
| `rtl/` | **25 816** | 33 | **Code dự án** |
| `examples/simple_system/rtl/` | 389 | 1 | Code dự án (harness) |
| `shared/rtl/` | ~200 | 4 | Code dự án (bus, RAM cho sim) |
| `vendor/` | **64 692** | 455 | **Bên thứ ba** |

⇒ **Vendor gấp ~2.5× code dự án.** Nhưng phần lớn vendor là DV/test/model, không phải RTL
đi vào silicon.

### Cơ chế vendoring: `util/vendor.py` + cặp `.vendor.hjson` / `.lock.hjson`

Ibex **không dùng git submodule**. Nó copy source vào cây và ghim revision bằng lock file.
Bảy dependency, mỗi cái có `<name>.lock.hjson` chứa `url` + `rev` chính xác:

| Dependency | Upstream | Revision (ghim) | Dùng làm gì |
|---|---|---|---|
| **`lowrisc_ip`** | `github.com/lowRISC/opentitan` | `3424e7fb` | **RTL thật đi vào netlist**: 170 module `prim_*` |
| **`pulp_common_cells`** | `pulp-platform/common_cells` | `63e1b679` | RTL: `stream_fork`, `stream_join_dynamic` |
| `google_riscv-dv` | `chipsalliance/riscv-dv` | `71666eba` | Sinh chương trình ngẫu nhiên cho UVM DV |
| `riscv-isa-sim` | `lowrisc/riscv-isa-sim` (**fork**) | `a4b823a1` | Spike ISS làm mô hình vàng cho co-sim |
| `riscv-tests` | `riscv-software-src/riscv-tests` | `f163ddfc` | Test suite |
| `riscv-arch-tests` | `riscv-non-isa/riscv-arch-test` | `a3b7f0c2` | Compliance |
| `riscv-test-env` | `riscv/riscv-test-env` | `982f93f5` | Môi trường link cho test |
| `eembc_coremark` | `eembc/coremark` | `0c91314d` | Benchmark |

Có `vendor/patches/` chứa patch áp lên upstream — dấu hiệu vendored code **đã bị sửa cục bộ**,
nên đừng so sánh trực tiếp với upstream mà không xem patch.

⚠️ `riscv-isa-sim` trỏ tới **fork của lowRISC**, không phải Spike gốc. Mô hình vàng dùng
để verify Ibex là bản đã sửa — cần biết điều này khi đánh giá độ tin cậy của co-simulation.

### Chỉ có **hai** dependency đi vào netlist

Từ file list fusesoc sinh ra cho config `small`:
- **`prim_*` (109 file `.sv`)** từ `vendor/lowrisc_ip` — clock gating, buffer, FIFO,
  RAM, LFSR, SECDED ECC, cipher (PRINCE), mubi, count.
- **`common_cells` (2 file)** từ PULP: `stream_fork.sv`, `stream_join_dynamic.sv`.

Toàn bộ 6 dependency còn lại là **verification/software**, không tổng hợp.

**Hệ quả quan trọng**: `prim_*` là biên trừu tượng cho công nghệ. `lowrisc:prim_generic:all`
(bản hành vi, dùng cho lint/sim) được thay bằng bản của foundry khi làm ASIC —
xem `ibex_top.core:34-37` (`files_map_prim_generic`). Khi tape-out, 109 file này
**bị thay hết**. Đây là điểm tích hợp lớn nhất mà repo không tự kiểm soát.

### `file list ≠ netlist` — xác nhận bằng thực nghiệm

File list mà fusesoc sinh cho config `small` **vẫn chứa** những file mà Vòng 1 kết luận
là không có trong netlist:

```
ibex_icache.sv          ← ICache=0
ibex_pmp.sv             ← PMPEnable=0
ibex_lockstep.sv        ← SecureIbex=0
ibex_dummy_instr.sv     ← SecureIbex=0
ibex_branch_predict.sv  ← BranchPredictor=0
ibex_multdiv_slow.sv    ← RV32M=RV32MFast
ibex_register_file_latch.sv / _fpga.sv  ← RegFile=RegFileFF
ibex_trvk.sv, ibex_cheriot_ex.sv, ibex_cheriot_pkg.sv  ← BaseIsa=RV32I
```

Chúng được **biên dịch** nhưng không được **elaborate** (generate loại bỏ) hoặc bị
constant-fold. Kết luận Vòng 1 **được xác nhận**, và giờ có thêm hiểu biết:
đừng bao giờ dùng file list để suy ra nội dung netlist.

Cách truyền parameter cũng được xác nhận đúng như Vòng 1 — trong `.vc` file:
```
-GRV32E=0  -GICache=0  -GPMPEnable=0 ...        ← 15 param dạng vlogparam
-DRV32M=ibex_pkg::RV32MFast                     ← 4 enum dạng vlogdefine (macro -D)
-DRV32B=ibex_pkg::RV32BNone
-DRV32ZC=ibex_pkg::RV32Zca
-DRegFile=ibex_pkg::RegFileFF
--top-module ibex_simple_system
```

### Giải đáp câu hỏi mở #1 của Vòng 1

> *"`rtl/ibex_core.f` thiếu `ibex_cheriot_*.sv` và `ibex_trvk.sv` — file list nào thực sự được dùng?"*

**Đã trả lời**: các `.core` của FuseSoC là nguồn thật, và chúng **đầy đủ** —
file list sinh ra có `ibex_cheriot_pkg.sv` (từ `ibex_pkg.core`),
`ibex_cheriot_ex.sv` (từ `ibex_core.core`), `ibex_trvk.sv` (từ `ibex_top.core`).
`rtl/ibex_core.f` và `src_files.yml` đều là **di sản chết**, không flow nào dùng.

## Chốt Vòng 2

| Câu hỏi | Trả lời |
|---|---|
| Top thật sự | **6 top khác nhau.** Sim → `ibex_simple_system`; UVM → `core_ibex_tb_top`; **Synthesis → `ibex_top`**. `ibex_top.sv` chỉ là top ở flow synthesis |
| Core thuần vs wrapper | `ibex_core` (105 port, lõi) ⊂ `ibex_top` (110 port, **biên IP** — thêm RF/RAM/lockstep/trvk) ⊂ `ibex_top_tracing` (66 port, chỉ cho sim) ⊂ `ibex_simple_system` (SoC harness) |
| Biên module | Bảng 20 module ở mục 2. `ibex_id_stage` **147 port** là biên rộng nhất và là điểm nghẽn hiểu biết |
| Tín hiệu liên stage | Đã lập bảng IF↔ID, ID→EX, ID→LSU, RF, hazard. Chú ý `instr_rdata_alu_i` (bản sao vì timing) và nhóm hazard 9 tín hiệu chết khi `WritebackStage=0` |
| Quy ước đặt tên | `_i/_o/_d/_q/_ni` nhất quán. **Bất nhất**: `g_` (180) vs `gen_` (159), `u_` (42) vs `_i` (26) — phải grep cả hai |
| Di sản | 21/33 file `rtl/` còn header ETH Zurich (RI5CY→Zero-riscy); 12 file thuần lowRISC; 3 file CHERIoT/Microsoft (2026) |
| Dự án vs bên thứ ba | Ranh giới sạch: tất cả bên thứ ba ở `vendor/` (7 dep, ghim rev bằng `.lock.hjson`, không dùng submodule). Vendor 64.7k LOC vs dự án 25.8k. **Chỉ 2 dep vào netlist**: `prim_*` (109 file) + `common_cells` (2 file) |

## Câu hỏi mở chuyển sang Vòng 3

1. `BaseIsa` thiếu trong 2 file `.core` — có phải CI của repo không chạy
   `make build-simple-system`? Kiểm tra `.github/workflows/` và `ci/`.
2. `ibex_top_tracing` chôn cổng ECC/lockstep — chính xác nó tie-off những gì,
   và điều đó có làm sim che giấu bug ở đường ECC không?
3. `ibex_id_stage` 147 port: có bao nhiêu port thực sự chết ở config `small`?
   (nhóm hazard 9 + BTALU 2 + phần CHERIoT ~20 → có thể >30 port là dây chết)
4. `prim_generic` sẽ bị thay khi ASIC — danh sách chính xác 109 file nào là
   "phải thay", cái nào dùng nguyên?
5. `vendor/patches/` sửa gì trên upstream? Có patch nào chạm RTL đi vào netlist không?
6. `instr_rdata_i` vs `instr_rdata_alu_i`: nhân đôi này có được assertion nào bảo vệ
   để đảm bảo chúng luôn bằng nhau không?

---

# Vòng 3 — Giao dịch với bên ngoài

Phân tích source tại HEAD `8031c7dd`, ngày 2026-09-09. Ranh giới tích hợp là
[`ibex_top`](../../rtl/ibex_top.sv), tiếp tục lấy cấu hình `small` của Vòng 1 làm mốc:
RV32, không CHERIoT, không I-cache, không SecureIbex, `MemECC=0` theo mặc định,
`DbgTriggerEn=0`. Các nhánh cấu hình khác được ghi riêng bên dưới.
Đây là kết luận từ RTL và tài liệu local; vòng này không chạy simulation,
debug compliance, CDC/RDC hay STA. Các test tích hợp cuối vòng là việc cần thực hiện,
không phải kết quả đã pass.

**Hợp đồng chính:** SoC cung cấp memory và MMIO qua hai cổng request/grant/response,
cấp clock/reset hợp lệ, giữ nguồn ngắt tới khi được phục vụ, và cung cấp hạ tầng
debug nếu cần attach debugger. CLINT, PLIC, JTAG và Debug Module không nằm trong core.
Tên CLINT/PLIC không phải điều kiện bắt buộc để core chạy: điều bắt buộc là chức năng
và giao thức phù hợp ở biên IP.

## 1. Interface đầy đủ tại biên IP

Chiều bên dưới tính từ `ibex_top`: output là core phát, input là SoC cấp.
Khai báo chuẩn nằm ở `rtl/ibex_top.sv:65–209`; `_tag` của capability,
`_intg` của ECC và cache tag là ba loại metadata khác nhau.

### 1.1. Instruction fetch

- Core phát `instr_req_o`, `instr_addr_o[31:0]`.
- SoC cấp `instr_gnt_i`, `instr_rvalid_i`, `instr_rdata_i[31:0]`,
  `instr_rdata_intg_i[6:0]`, `instr_err_i`.
- Read-only; địa chỉ trên bus luôn căn 4 byte, mỗi response mang một word 32 bit.
  Lệnh nén 16 bit và lệnh 32 bit nằm vắt qua hai word được IF ghép bên trong.
- Với `small`, prefetch có tối đa **2 request outstanding**
  (`rtl/ibex_prefetch_buffer.sv:44`). Khi bật I-cache, bộ cache thay prefetch;
  không dùng con số 2 này để suy ra giới hạn của cache fill.
- Fetch có thể đi trước PC đang thực thi. Redirect/branch đánh dấu response cũ
  để discard; không có tín hiệu hủy giao dịch cho memory. Memory vẫn phải trả
  các request đã nhận. Tránh map vùng có side effect khi đọc vào đường fetch.

Nguồn: [`instruction_fetch.rst`](../03_reference/instruction_fetch.rst),
`rtl/ibex_prefetch_buffer.sv:118–128,204–238`.

### 1.2. Data / load-store

- Core phát `data_req_o`, `data_we_o`, `data_be_o[3:0]`, `data_addr_o[31:0]`,
  `data_wdata_o[31:0]`, `data_wdata_intg_o[6:0]`, `data_tag_o`.
- SoC cấp `data_gnt_i`, `data_rvalid_i`, `data_rdata_i[31:0]`,
  `data_rdata_intg_i[6:0]`, `data_tag_i`, `data_err_i`.
- `we=1` là store; `be` chọn các byte của access. Address word-aligned;
  LSU xử lý byte/halfword/word và các access vượt biên word bằng hai giao dịch.
- Top đặt `MaxOutstandingDSideAccesses=2` (`rtl/ibex_top.sv:229–233`).
  Điều này không có nghĩa core có hai memory instruction độc lập chạy song song:
  một instruction có thể cần hai access do misalignment hoặc capability.
- Store tách đôi không atomic: nếu một phần đã ghi rồi phần kia lỗi,
  không có rollback từ core. Với MMIO phải kiểm soát alignment và byte enables.

Nguồn: [`load_store_unit.rst`](../03_reference/load_store_unit.rst),
[`ibex_load_store_unit.sv`](../../rtl/ibex_load_store_unit.sv), phần FSM từ dòng 402.

### 1.3. Hợp đồng bus bắt buộc

Đây là giao diện native req/gnt/rvalid; source TRVK gọi nó là OBI.
Không có cổng AXI/AHB/APB ở `ibex_top`, cũng không suy ra tuân thủ một phiên bản
OBI đầy đủ chỉ từ tên/comment. Bridge phải thực hiện chính xác protocol local:

1. Request được nhận tại cạnh clock có `req && gnt`. Trong khi `req && !gnt`,
   core giữ request và payload ổn định. Grant có thể cùng cycle với request.
2. **Grant chỉ là nhận request.** Sau đó SoC trả đúng một response bằng `rvalid`,
   từ ít nhất cycle kế tiếp; `rdata/err/intg/tag` phải thuộc đúng giao dịch đó.
3. **Store cũng cần `rvalid`**, kể cả khi không có dữ liệu đọc hữu ích.
   Chỉ phát grant cho store sẽ khiến LSU chờ completion.
4. Response đúng thứ tự trên từng cổng. Không có transaction ID trên biên này,
   không có `rready` để core trì hoãn response. Bridge tới fabric có reordering
   phải giữ thứ tự khi trả về core, hoặc hạn chế số giao dịch được nhận.
5. `rvalid` biểu diễn một response trong mỗi cycle; có thể cao hai cycle liên tiếp
   để trả hai request. Không giữ cao nhiều cycle cho cùng một response.
6. `err` có nghĩa cùng `rvalid`. Địa chỉ không được map nên nhận error response;
   không trả response sẽ làm core chờ. Giao thức không đặt bound latency hay timeout.

Ví dụ ở các cạnh lấy mẫu, một store S:

```text
e0: req=1, gnt=0, payload=S                 chờ nhận
e1: req=1, gnt=1, payload=S                 SoC nhận S
e2: req=0, rvalid=0                         chờ completion
e3:        rvalid=1, err=0                  S hoàn tất trên bus
```

Với `MemECC=1`, dùng inverted SECDED 39/32 theo primitive của repo, không thay bằng
parity tùy ý. **Response store cũng phải có cặp data/ECC hợp lệ**; dữ liệu có thể là
một hằng số nhưng ECC phải encode đúng hằng đó. LSU phát hiện lỗi qua `err_o` của
decoder, không sử dụng output đã sửa lỗi (`rtl/ibex_load_store_unit.sv:376–393`).
`MemECC` là parameter riêng, mặc định bằng `SecureIbex`; câu trong tài liệu nói
ECC chỉ hoạt động khi SecureIbex bật không mô tả đầy đủ RTL hiện tại.

### 1.4. Interrupt

Core có **19 dây ngắt**: ba nguồn chuẩn, 15 fast IRQ và một NMI
(`rtl/ibex_top.sv:116–122`). Không có `irq_ack_o` hay output ID ngắt.

- `irq_software_i`: machine software interrupt, cause ID 3, bit `mip/mie[3]`.
- `irq_timer_i`: machine timer interrupt, ID 7, bit 7.
- `irq_external_i`: machine external interrupt, ID 11, bit 11.
- `irq_fast_i[14:0]`: 15 nguồn độc lập, ID 16–30; `fast[0]` là ID 16.
- `irq_nm_i`: external NMI, ID 31; không qua `mie` và không hiển thị trong `mip`.

**Tất cả là level-sensitive.** `mip` lấy trực tiếp mức các IRQ chuẩn/fast;
không có pending latch lưu một pulse ngắn trong core (`rtl/ibex_cs_registers.sv:408–412`).
SoC/peripheral phải giữ pending, ISR xử lý rồi clear tại nguồn qua MMIO.
`mret` không tự clear peripheral, và ghi `mip` không thay thế acknowledge ở nguồn.

Trong RV32 `small`, thứ tự chọn ngắt là NMI → fast[0] → … → fast[14] →
external → software → timer, không phải cứ ID lớn hơn thì ưu tiên hơn.
Maskable interrupt cần `mie` tương ứng và điều kiện cho phép ngắt theo privilege;
ở M-mode cần `mstatus.MIE=1`. NMI bỏ qua các mask này. Trong Debug Mode mọi IRQ,
kể cả NMI, bị bỏ qua; khi đang xử lý NMI không nhận nested NMI.

RV32 dùng vectored interrupt: handler tại `mtvec.BASE + 4 × ID`, base căn 256 byte;
exception đồng bộ về base. NMI dùng offset `0x7c`.
**Ngoại lệ của fork:** khi thực sự bật CHERIoT runtime, `EXC_PC_IRQ` về base trực tiếp,
không dùng phép cộng ID (`rtl/ibex_if_stage.sv:221–228`).

Nguồn: [`exception_interrupts.rst`](../03_reference/exception_interrupts.rst),
`rtl/ibex_controller.sv:502–510,729–758`.

### 1.5. Boot, điều khiển và trạng thái

- `hart_id_i[31:0]`: ID hart do platform gán; cấp ổn định.
- `boot_addr_i[31:0]`: base căn 256 byte. PC đầu tiên **không bằng base**:
  `PC={boot_addr_i[31:8],8'h80}` (`rtl/ibex_if_stage.sv:243,932`).
  Ví dụ Simple System cấp `0x00100000`, instruction đầu ở `0x00100080`.
  Linker/startup và bảng vector phải khớp quy ước này.
- `fetch_enable_i`: cho phép fetch/thực thi; dừng cấp lệnh mới và đợi các lệnh đang
  thực thi hoàn tất theo logic core. Đây không phải cổng request Debug Mode,
  không đảm bảo thay thế protocol quiesce/reset/power-off của SoC.
- `mcounteren_writable_i`: cho phép ghi CSR `mcounteren`, không phải enable timer
  (`rtl/ibex_cs_registers.sv:844`).
- `cheriot_enable_i`: chọn runtime mode của cấu hình dual-ISA; không thể dùng dây
  này để bổ sung CHERIoT khi đã elaborate `BaseIsaRV32I`.
- Ba control trên dùng `ibex_mubi_t` 4 bit: **On=`0101`, Off=`1010`**
  (`rtl/ibex_pkg.sv:754–760`). Khi tie-off nên dùng đúng constant của package.
- `core_sleep_o`: trạng thái do điều kiện clock enable suy ra; xem mục clock.
- `crash_dump_o`: struct gồm năm trường 32 bit `current_pc`, `next_pc`,
  `last_data_addr`, `exception_pc`, `exception_addr` (`rtl/ibex_pkg.sv:16–22`).
  Platform cần chụp chúng trước/trong quy trình reset nếu muốn giữ evidence.
- `double_fault_seen_o`: pulse một cycle khi phát hiện double fault;
  `alert_minor_o`, `alert_major_internal_o`, `alert_major_bus_o` báo lỗi để
  platform lưu trạng thái/xử lý. Chúng không tự tạo khối reset/escalation bên ngoài.

### 1.6. Cổng đặc biệt: CHERIoT, cache, security và trace

**CHERIoT / TRVK.** Ngoài `cheriot_enable_i` và `data_tag_o/i`, còn có
`trvk_heap_base_addr_i[31:0]`; core phát `trvk_revbm_req_o`,
`trvk_revbm_addr_o[31:0]`; SoC trả `trvk_revbm_gnt_i`, `trvk_revbm_rvalid_i`,
`trvk_revbm_rdata_i[31:0]`, `trvk_revbm_rdata_intg_i[6:0]`, `trvk_revbm_err_i`.

TRVK tồn tại khi `BaseIsa==BaseIsaRV32IorCHERIoT`; ở RV32-only data đi xuyên,
output bitmap request/address và output data tag bằng 0
(`rtl/ibex_top.sv:1275–1353`). Với CHERIoT, SoC cần memory giữ capability tag,
quy tắc cập nhật/clear tag đúng với store, và bitmap service thật. Bus 32 bit truyền
capability 64 bit qua pointer word rồi metadata word; tag không phải transaction ID.
DMA/bridge/memory controller cũng phải giữ đúng semantics của tag.

Bitmap chỉ có **1 lookup outstanding**, không có response-ready ngoài top.
Request phải giữ tới grant, response sau grant ít nhất một cycle và không tự phát
khi không có request (`rtl/ibex_trvk.sv:388–418`). Lookup ứng với capability base
trong heap: bit index là `(cap_base - heap_base)/8`; một word bitmap chứa 32 bit.
Heap base căn 8 byte; bitmap base căn 4 byte. Bit revoked hoặc bitmap error làm
capability bị coi là revoked; device/integrity error còn đưa lên major bus alert.
Cổng chỉ đọc: SoC/runtime phải có cơ chế cập nhật bitmap và đảm bảo visibility.
Simple System tie tag về 0 và không trả bitmap, nên không phải mẫu tích hợp CHERIoT đầy đủ.

**Custom extension tổng quát.** Top này không có interface offload kiểu
CV-X-IF/RoCC hay handshake issue/result cho coprocessor. CHERIoT là extension
được implement trong datapath/decoder/CSR và thêm các cổng memory nói trên.
Muốn accelerator độc lập có thể tích hợp MMIO qua data bus; muốn custom instruction
offload cần thiết kế thêm giao diện và logic core.

**I-cache SRAM.** `ram_cfg_icache_tag_i/o`, `ram_cfg_icache_data_i/o` là các mảng
request/response struct cấu hình RAM theo way. RAM tag/data đã được instantiate
trong `ibex_top` khi `ICache=1` (`rtl/ibex_top.sv:681`); SoC/backend vẫn phải cung cấp
implementation primitive/SRAM macro phù hợp. Đây không phải cổng memory-mapped
configuration của CPU. Khi không dùng, cấp `RAM_1P_CFG_REQ_DEFAULT` theo package.

**Scrambling.** `scramble_req_o` yêu cầu key; `scramble_key_valid_i`,
`scramble_key_i[127:0]`, `scramble_nonce_i[63:0]` cung cấp key/nonce đồng bộ.
Top giữ request tới valid và chốt key/nonce tại `clk_i`
(`rtl/ibex_top.sv:623–655`). Reset khởi tạo bằng constant mặc định;
muốn đổi key sau yêu cầu của cache cần một service ngoài core trả lời.
Tắt `ICacheScramble` thì các input này không được sử dụng.

**Lockstep.** `lockstep_cmp_en_o` là MuBi output; các output quan sát shadow gồm
`data_req_shadow_o`, `data_we_shadow_o`, `data_be_shadow_o[3:0]`,
`data_addr_shadow_o[31:0]`, `data_wdata_shadow_o[31:0]`,
`data_wdata_intg_shadow_o[6:0]`, `instr_req_shadow_o`, `instr_addr_shadow_o[31:0]`.
Đây là bản đối chiếu trễ của core chính; không đấu như một bus master độc lập
để thực hiện lại store. Khi không lockstep chúng được tie-off trong top
(`rtl/ibex_top.sv:1251–1264`).

**Trace / RVFI.** Compile define `RVFI` thêm các output ở `rtl/ibex_top.sv:138–183`;
`RISCV_FORMAL` cũng bật define này. Bao gồm valid/order/instruction, trap/halt/intr,
mode/IXL, địa chỉ và giá trị rs1/rs2/rs3/rd, PC trước/sau, địa chỉ/mask/data memory,
capability metadata của register/memory và các field `rvfi_ext_*` cho IRQ/debug,
counter, cache key, expanded instruction. Đây là luồng quan sát không có ready;
`rvfi_halt` không phải cổng handshake giữa DM và hart.

[`ibex_top_tracing`](../../rtl/ibex_top_tracing.sv) nối RVFI tới `ibex_tracer` để ghi
`trace_core_<HARTID>.log` trong simulation. Không có trace encoder, trace SRAM,
trace transport qua chân chip hay JTAG trong top này. Muốn trace trên silicon
phải bổ sung phần thu/lưu/xuất phù hợp; debug run-control và instruction trace
là hai chức năng khác nhau.

## 2. Các khối SoC phải cung cấp

### 2.1. Để boot và chạy chương trình

1. Clock, reset controller và tie-off control hợp lệ.
2. Vùng instruction memory chứa reset code đúng `boot_addr+0x80` và vector table;
   data RAM cho stack/data theo chương trình. Không bắt buộc dùng hai SRAM vật lý:
   có thể dùng RAM dual-port hoặc fabric phân xử instruction/data.
3. Interconnect/bridge tuân thủ giao thức ở mục 1.3, address decoder và error response.
   Với AXI/AHB/APB cần bridge; core không tự cung cấp bộ chuyển đổi này.
4. Runtime/startup khởi tạo stack, data/BSS, trap handler và bật fetch đúng lúc.
   ROM chỉ là một lựa chọn boot; RAM nạp sẵn cũng được dùng trong Simple System.

### 2.2. Timer: cần chức năng, không bắt buộc tên CLINT

Core nhận `irq_timer_i`; nó không chứa timer MMIO `mtime/mtimecmp` tạo IRQ.
`mcycle` đếm clock core không thay thế timer SoC chạy trong lúc WFI.
Các CSR user `time/timeh` cũng không được implement
(`doc/03_reference/cs_registers.rst:593–600`).

Nếu cần tick/scheduler/deadline, SoC thêm timer chạy ở clock còn hoạt động khi core
ngủ, comparator, register map và nối IRQ tới `irq_timer_i`.
Nếu cần software interrupt/IPI thì thêm thanh ghi pending kiểu MSIP và nối
`irq_software_i`. Có thể dùng CLINT phù hợp, hoặc các khối timer/MSIP riêng.
Core không ép địa chỉ CLINT hay một implementation cụ thể.

Repo đã có [`shared/rtl/timer.sv`](../../shared/rtl/timer.sv): `mtime` 64 bit,
`mtimecmp` 64 bit, offset lần lượt 0/4 và 8/12; IRQ giữ tới khi ghi compare.
Đây là timer mẫu, không phải bằng chứng có cả CLINT/MSIP. Reset đặt compare bằng 0,
nên startup cần lập lịch compare trước khi enable interrupt.

### 2.3. Ngắt ngoại vi: PLIC là một phương án

Nếu nhiều peripheral cùng đi vào `irq_external_i`, cần khối gom/pending/enable
và xác định nguồn. PLIC có thể làm việc này; ISR claim/complete qua MMIO của PLIC,
core chỉ thấy external IRQ mức và cause 11. ID peripheral bên trong PLIC khác
cause ID 11 của core.

Với ít nguồn, có thể nối các nguồn pending độc lập tới `irq_fast_i`, hoặc dùng
controller đơn giản có register pending. Nguồn dạng pulse cần được latch;
nguồn khác clock cần CDC trước biên core. Fast IRQ là ngắt riêng của Ibex,
không có nghĩa top implement CLIC hay giao diện IRQ-ID của CLIC.

### 2.4. Debug và các cấu hình tùy chọn

Muốn GDB/JTAG run-control cần Debug Transport Module (DTM), Debug Module (DM),
debug ROM/program buffer/data window theo DM được chọn, đường nối memory vào
fabric, `debug_req_i` và reset/CDC tương ứng. Core không có chân JTAG TCK/TMS/TDI/TDO,
DMI hay một cổng abstract-command trực tiếp đọc register file.
DM/DTM không cần để chạy firmware nếu không dùng debug entry; tie `debug_req_i=0`.

CHERIoT cần tagged memory + bitmap service; `MemECC=1` cần producer/consumer ECC
ở đường memory; cache scrambling cần key service; cấu hình an toàn cần nơi tiếp
nhận alert/crash data và chính sách xử lý. Đây đều là việc tích hợp platform,
không được suy ra đã có chỉ vì top xuất tín hiệu.

### 2.5. Simple System hiện có gì — và thiếu gì

`examples/simple_system/rtl/ibex_simple_system.sv:235–375` nối core vào RAM dual-port
1 MiB, bus data với ba device RAM/timer/simulator control; timer nối `irq_timer_i`.
Các IRQ còn lại và `debug_req_i` bằng 0. Không có PLIC, MSIP/CLINT đầy đủ hay DM/DTM.
`simulator_ctrl` ghi log/kết thúc simulation, không phải UART IP dùng trên chip.

**Giới hạn fabric mẫu:** `shared/rtl/bus.sv:8–15,89–99` nói rõ dành cho demo/simulation;
mọi device phải response ngay cycle sau request. Nó giữ selection của cycle trước,
không có ready/grant từ device. Không tái sử dụng nguyên trạng để nối slave
variable-latency như flash controller/bridge khác clock.

**Đính chính Vòng 2:** `ibex_top_tracing` hiện truyền xuyên ECC và shadow outputs
(`rtl/ibex_top_tracing.sv:271–300,371–381`), không chôn/tie-off các cổng này.
Chính Simple System bỏ output write ECC/shadow và tạo lại read ECC từ read data khi
`SecureIbex=1` (`examples/simple_system/rtl/ibex_simple_system.sv:190–205,266,303–313`).
Do đó simulation bình thường với harness này không chứng minh bảo vệ toàn tuyến
memory ECC: lỗi data xuất hiện trước encoder có thể được encode thành cặp data/ECC
hợp lệ. Không có lưu/check write ECC tại RAM mẫu.

## 3. Clock, reset và CDC

### 3.1. Một clock đầu vào, có clock gating bên trong

`ibex_top` chỉ nhận `clk_i`; không có clock bus/debug thứ hai.
Root clock chạy các flop quản lý busy và key/nonce.
`prim_clock_gating` tạo `clk` cho core/RF/TRVK và các logic theo kết nối top;
đây là clock cùng nguồn có gating, không phải miền tần số/pha bất đồng bộ.
Shadow core khi bật lockstep chạy đồng bộ và được delay bằng logic.

Ở cấu hình `small` (`rtl/ibex_top.sv:318–338`):

```systemverilog
clock_en     = core_busy_q[0] | debug_req_i | irq_pending | irq_nm_i;
core_sleep_o = ~clock_en;
```

SecureIbex thay phép kiểm busy bằng `core_busy_q != IbexMuBiOff`.
`irq_pending = |(mip & mie)` là combinational để mở clock khi đang ngủ
(`rtl/ibex_cs_registers.sv:1041–1044`). **Wake-up không đồng nghĩa nhận trap:**
ở M-mode có thể thoát WFI với local IRQ enabled dù `mstatus.MIE=0`;
bit global này vẫn ngăn nhận maskable trap.

Clock gate generic latch `en_i | test_en_i` khi clock thấp rồi AND với clock.
Vì test enable có thể mở gate độc lập, `core_sleep_o=1` không chứng minh clock vật lý
đang dừng trong test mode. Nó cũng không phải toàn bộ giao thức cho phép cắt nguồn.
Muốn wake qua timer/IRQ, nguồn tạo và logic giữ/synchronize IRQ phải còn clock
khi core ngủ; không đặt synchronizer duy nhất sau gate đang đóng.

### 3.2. Không có bộ CDC tự động ở biên IP

IRQ/debug đi thẳng tới controller và logic clock-enable. Primitive clock gate còn
ghi rõ giả định `en_i` đã được đồng bộ
(`vendor/lowrisc_ip/ip/prim_generic/rtl/prim_clock_gating.sv:7–8`).
Latch của gate không thay synchronizer chống metastability.

Trong SoC một clock, root ↔ gated clock là đường timing liên quan cần constraints
đúng. Nếu memory, timer, peripheral, debug DTM/JTAG hoặc key service dùng clock khác:

- Synchronize level IRQ/debug trong miền còn hoạt động; pulse phải có latch/handshake
  để không mất sự kiện.
- Bus nhiều bit cần bridge CDC giữ request/response và thứ tự; không synchronize
  từng bit address/data độc lập.
- Key/nonce nhiều bit cần handshake đảm bảo payload nhất quán.
- Quy hoạch reset của bridge và hai phía; không chỉ kiểm CDC dữ liệu.

Không thấy async FIFO hay bộ synchronizer biên cho các cổng này trong top/TRVK.
Không kết luận “CDC safe” chỉ từ việc module có một input clock; vòng này chưa có
report CDC/RDC để chứng minh tích hợp cụ thể.

### 3.3. Reset active-low, assert bất đồng bộ

Nhiều state flop dùng `always_ff @(posedge clk... or negedge rst_ni)`:
reset assert bất đồng bộ tại RTL. Top không có reset synchronizer bảo đảm release
đồng bộ cho toàn bộ core. SoC phải thiết kế release phù hợp clock/gating,
recovery/removal, các primitive được chọn và reset tree thực tế.
Không được gọi reset này là synchronous chỉ vì state cập nhật ở cạnh clock.

`scan_rst_ni` là reset test của shadow; `test_en_i` mở gate và chọn reset test.
Không DFT thì cấp `test_en_i=0`, `scan_rst_ni=1` như Simple System.
Lockstep có sequencing riêng để nhả shadow reset trễ và bật compare
(`rtl/ibex_lockstep.sv:149–236`); cơ chế này không thay reset synchronizer
của `rst_ni` ngoài top. Với `small`, `ResetAll=0`: một số payload flop không reset,
nên không mặc định toàn bộ register/RAM có giá trị zero sau reset.

**Reset khi còn outstanding:** reset core xóa tracker/FIFO state, nhưng memory có
thể vẫn giữ request cũ. Nếu nó trả response sau khi core đã boot lại thì response
đó không còn metadata đúng. SoC cần reset/cancel đồng bộ các giao dịch hoặc drain
và chặn response cũ bằng bridge trước khi cho core hoạt động lại.
Điểm này đặc biệt liên quan `ndmreset` từ một DM ngoài core và reset một phần SoC.

## 4. Debug: phiên bản và trigger chính xác

### 4.1. Phần nào của Debug Spec được core cung cấp?

[`doc/03_reference/debug.rst`](../03_reference/debug.rst), dòng 6, công bố
**execution-based debug theo RISC-V Debug Specification 0.13**.
Bổ sung khi đối chiếu ở Vòng 4: `doc/01_overview/compliance.rst:9` công bố phiên bản
cụ thể **0.13.2**. Hai trang có mức chi tiết khác nhau; chưa có kiểm conformance
toàn hệ thống trong phiên này và không có cơ sở nâng thành Debug Spec 1.0.
Core có `dcsr`, `dpc`, `dscratch0`, `dscratch1`; logic single-step,
EBREAK theo `dcsr.ebreakm/ebreaku`, debug request và DRET.

Luồng halt điển hình: debugger → DTM → DM → `debug_req_i` → controller vào
Debug Mode → fetch tại `DmHaltAddr` qua instruction bus bình thường.
Core dùng code/địa chỉ memory của debug subsystem để trao đổi trạng thái và
thực hiện thao tác debug. Nối riêng `debug_req_i` không tạo được một hệ JTAG debug.
Nếu fabric không phục vụ debug entry address, core sẽ gặp lỗi/chờ bus thay vì
thực hiện debug handler. Cần giữ yêu cầu theo protocol của DM cho tới khi DM biết
hart đã halt; top không có dây halt-ack riêng.

Giá trị mặc định **theo RTL** (`rtl/ibex_top.sv:48–51`):

- `DmBaseAddr = 0x1A110000`.
- `DmAddrMask = 0x00000FFF`.
- `DmHaltAddr = 0x1A110800`.
- `DmExceptionAddr = 0x1A110808`.

PMP dùng `((addr & ~DmAddrMask) == DmBaseAddr)` để nhận vùng debug khi Debug Mode
(`rtl/ibex_pmp.sv:240`). Mask mặc định ứng với vùng 4 KiB; không phải khối DM được
instantiate hay memory được tạo tự động tại địa chỉ đó. Bảng parameter trong
`integration.rst` ghi sai default mask `0x1A110000`; phải theo RTL và map của DM thật.

### 4.2. Có trigger, nhưng tùy cấu hình và phạm vi hẹp

`DbgTriggerEn=1` elaborate trigger bank; `DbgHwBreakNum` đặt số slot, default 1.
Với `small`, `DbgTriggerEn=0`: không có hardware trigger, nhưng chức năng debug
request/single-step không vì thế mà bị loại bỏ.

Mỗi trigger dùng `tselect`, `tdata1`, `tdata2`; RTL trả type=2, action=1:

- So sánh **PC bằng chính xác một địa chỉ** ở IF, match trước thực thi.
- Execute breakpoint ở M/U, vào Debug Mode.
- Không load/store watchpoint, không match dữ liệu, không range/NAPOT,
  không chaining và không hit bit.
- `tselect` chọn một slot; write ngoài số slot bị giới hạn về slot cuối.
  `tdata1.execute` bật/tắt comparator; `tdata2` chứa địa chỉ cần match.

Bằng chứng trực tiếp: `rtl/ibex_cs_registers.sv:1753–1879`, đặc biệt
`trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i])`.
Câu “one trigger only” trong bảng integration đã cũ so với parameter `DbgHwBreakNum`.

**Phân biệt quyền CSR:** `dcsr/dpc/dscratch*` bị chặn truy cập ngoài Debug Mode.
Với trigger bật, RV32 M-mode có thể đọc `tselect/tdata*`; ghi các thanh ghi trigger
thực sự được gate bởi `debug_mode_i`. Tài liệu debug nói toàn bộ trigger CSR chỉ
truy cập được ở Debug Mode là quá rộng so với RTL hiện tại:
decode tại `rtl/ibex_cs_registers.sv:635–662` không đặt `dbg_csr`, trong khi
write-enable ở dòng 1774–1779 yêu cầu Debug Mode. U-mode vẫn chịu kiểm privilege CSR.

## 5. Các quyết định và kiểm thử cho SoC

Chưa có target FPGA/ASIC, clock tree hay bus fabric cụ thể được chỉ định trong
vòng này. Với mốc `small`, phương án bring-up là memory/fabric một clock,
reset controller, timer MMIO, ngắt có pending ở nguồn và DM/DTM nếu cần debugger.
Chỉ cần PLIC khi topology/phần mềm của platform yêu cầu; CHERIoT cần mở thêm
phạm vi tagged memory và revocation ở mục 1.6.

Trước khi coi cấu hình SoC là dùng được, cần thực hiện các kiểm thử sau:

1. **Boot:** kiểm PC đầu `base+0x80`, fetch-enable và vector table; thử delay grant
   và delay response instruction độc lập.
2. **Bus:** load/store với backpressure, response liên tiếp, hai access outstanding,
   split access và error ở từng phần; store phải có completion. Branch khi fetch
   outstanding phải drain response cũ đúng cách.
3. **IRQ/WFI:** timer đánh thức core; phân biệt wake với trap khi MIE=0;
   nguồn giữ pending tới ISR clear; thử nhiều fast IRQ cùng lúc và NMI.
4. **Debug:** halt trong lúc chạy/WFI, fetch debug ROM, resume/DRET, single-step,
   EBREAK; thử trigger chỉ khi đã bật cấu hình. Kiểm DM reset cùng outstanding bus.
5. **Clock/reset:** reset khi chờ grant/response; chặn response trước reset lọt
   sang lượt boot mới; CDC/RDC/STA theo clock tree và implementation primitive thật.
6. **Tùy chọn:** fault injection ECC ở đúng vị trí ngoài encoder; capability tag
   qua load/store/DMA và revoked bitmap; key renewal khi bật scrambling;
   latch alert/crash data và kiểm policy xử lý.

Những mục mở từ Vòng 2 về CI, số port chết, thay primitive và patch vendor không
được coi là đã giải quyết bởi vòng giao diện này. Mục về ECC/lockstep wrapper đã
được đính chính ở mục 2.5; các phần còn lại thuộc phân tích build/verification tiếp theo.

---

# Vòng 4 — Verification: bằng chứng chứ không phải lời hứa

Phạm vi: checkout `8031c7dd`, ngày phân tích 2026-09-09; tiếp tục dùng `small`
làm cấu hình mục tiêu. Phân biệt bốn loại bằng chứng: code checker hiện hữu,
thử nghiệm local có log, kết quả upstream có revision riêng, và điều chưa chạy.
Các kết luận ở Vòng 0–3 về cấu trúc RTL không đồng nghĩa đã kiểm chứng hành vi động.

**Repo có golden reference:** Spike cho simulation và Sail cho flow formal mới.
Nhưng chưa có regression RTL/ISS pass của chính checkout này trong phiên làm việc.
CHERIoT runtime chưa được các harness đã kiểm tra exercise end-to-end.
ISS cũng không phải oracle tuyệt đối: cấu hình ISA, model patches, input đồng bộ,
checker enable và miền trạng thái được so sánh đều ảnh hưởng sức mạnh kết luận.
Directed test và formal property vẫn cung cấp bằng chứng độc lập hữu ích ngay cả
khi không có ISS, miễn kỳ vọng và giả định được xác định rõ.

## 1. Golden reference và đường phát hiện mismatch

### 1.1. UVM dùng lowRISC Spike qua DPI

Luồng chính trong [`dv/uvm/core_ibex`](../../dv/uvm/core_ibex/README.md):

```text
RISCV-DV sinh chương trình → RISC-V GCC tạo ELF/bin → memory model nạp chương trình
                                                      ↓
RTL Ibex → RVFI monitor → ibex_cosim_scoreboard → DPI → SpikeCosim → Spike
memory agent data-access ────────────┘                    ↑
IRQ / NMI / debug / lỗi memory được đưa vào đúng thứ tự ──┘
```

RISCV-DV là **stimulus generator**, không phải golden execution model.
`dv/cosim/cosim.core` chọn `spike_cosim.cc`; đây là implementation ISS hiện có.
Tài liệu yêu cầu fork [`lowRISC/riscv-isa-sim`, nhánh `ibex_cosim`](https://github.com/lowRISC/riscv-isa-sim/tree/ibex_cosim),
build với `--enable-commitlog --enable-misaligned`. Không mặc định Spike upstream
bất kỳ sẽ model đúng custom CSR/NMI/debug của Ibex.

Checker tại `dv/uvm/core_ibex/common/ibex_cosim_agent/ibex_cosim_scoreboard.sv:165`
gọi:

```cpp
riscv_cosim_step(handle, rd_addr, rd_wdata, pc, trap, rf_wr_suppress)
```

`dv/cosim/spike_cosim.cc` step ISS và kiểm PC, địa chỉ/giá trị register write,
trap đồng bộ và các data memory access được monitor gửi sang trước đó.
Mismatch tạo thông báo có PC hoặc register/kỳ vọng rồi scoreboard báo `UVM_FATAL`
(`scoreboard.sv:165–173`; `spike_cosim.cc:335,400,453,467`).
Đây là tandem ở mức sự kiện kiến trúc, không ép Spike chạy cùng số cycle pipeline.
`step` không nhận raw `rvfi_insn` hay capability metadata; không gọi nó là phép
so trực tiếp mọi field RVFI với một field độc lập bên ISS.

Có hai loại sự kiện cần giữ đúng thứ tự: retire/trap của instruction và IRQ event.
`rvfi_ext_irq_valid` còn biểu diễn IRQ event không đi kèm `rvfi_valid`.
`rvfi_order` dùng theo dõi thứ tự, bao gồm liên kết lỗi fetch với instruction;
không coi số dòng log hay số cycle là cùng một đại lượng với số instruction.

### 1.2. Golden có giới hạn và có các trường được đồng bộ từ DUT

- **Data memory:** so transaction có tác dụng kiến trúc, gồm read/write, address,
  data/byte enables và lỗi. Instruction fetch có speculation nên không được
  so một-một với mọi external instruction transaction. IF fault được thông báo riêng.
- **IRQ/debug/NMI:** môi trường đưa vào ISS tại ranh giới kiến trúc phù hợp.
  Cần phân biệt lỗi DUT với lỗi sampling/ordering của scoreboard khi debug mismatch.
- **Counter:** `mcycle`, các `mhpmcounter*` được set từ RVFI vào ISS trước step
  (`scoreboard.sv:153–163`). Vì vậy CSR read khớp không tự chứng minh counter
  đếm đúng số cycle/sự kiện. Cần property hoặc checker riêng.
- **Fetch error với cache:** tài liệu co-sim cho phép probe trong IF để phản ánh
  lỗi thực sự đến pipeline. Cách này có thể bỏ sót lỗi bị cache/prefetch làm mất
  trước điểm probe; I-cache có UVM environment riêng để bổ sung.
- **ISA/extension:** `scripts/ibex_cmd.py:94–120` tạo ISA string theo RV32E/M/B,
  chưa encode CHERIoT và lựa chọn Zc mới ở đây. Khi mở rộng config phải đối chiếu
  cả hàm `get_isa_string()` trong SV, generator, compiler và version ISS.

Nguồn: [`cosim.rst`](../03_reference/cosim.rst),
[`cosim.h`](../../dv/cosim/cosim.h),
[`ibex_cosim_scoreboard.sv`](../../dv/uvm/core_ibex/common/ibex_cosim_agent/ibex_cosim_scoreboard.sv).

### 1.3. PASS không luôn có nghĩa ISS đã kiểm toàn bộ test

`cfg.relax_cosim_check=1` biến mismatch từ `UVM_FATAL` thành `UVM_INFO`.
Test `riscv_csr_test` có `+disable_cosim=1`
(`riscv_dv_extension/testlist.yaml:572–582`); base test chuyển nó thành cờ relax.
`core_ibex_mcounteren_lock_test` cũng chủ động relax ở
`tests/core_ibex_test_lib.sv:2031–2036`. Các test này có mục đích/check khác,
nhưng PASS của chúng không là bằng chứng ISS equivalence cho toàn trace.

Post-processing hiện chuyển RTL trace thành CSV và kiểm log UVM; không còn một
pass so CSV RTL/ISS độc lập cứu lại mismatch đã bị relax
(`scripts/check_logs.py:27–78`). Tên `ISS=ovpsim` trong comment Makefile là di sản:
flow compile vẫn yêu cầu Spike libraries; tài liệu nói OVPsim không hỗ trợ flow
co-sim hiện tại. Không thấy implementation ISS thứ hai được nối vào checker.

### 1.4. Simple System: phải chọn đúng target mới có golden

- `lowrisc:ibex:ibex_simple_system`: chạy firmware/tracer; log instruction không
  tự so với ISS.
- `lowrisc:ibex:ibex_simple_system_cosim`: thêm C++ Spike instance, SV checker/bind,
  DPI và dependency check. `Finish()` in số instruction đã so
  (`dv/verilator/simple_system_cosim/simple_system_cosim.cc:52–56`).
- `ci/run-cosim-test.sh` kiểm return code của simulator, chuỗi failure và thông báo
  firmware PASS tùy test. `--skip-pass-check` chỉ bỏ yêu cầu chuỗi PASS, không bỏ ISS.

Vì vậy **Verilator có thể chạy Spike co-sim** qua target riêng này; câu “only VCS”
ở đầu `cosim.rst` không mô tả đầy đủ source hiện tại.

### 1.5. Khoảng trống CHERIoT

`dv/uvm/core_ibex/tb/core_ibex_tb_top.sv:159–188` tie `data_tag_i=0`, không phục vụ
revocation bitmap và buộc `cheriot_enable_i=IbexMuBiOff`.
Simple System có cùng giới hạn đã nêu ở Vòng 3.
API `Cosim::step` và scoreboard đang kiểm PC/integer write/trap, không nhận `cap_t`.
Formal harness chọn `BaseIsaRV32I` với Sail RISC-V thường.

Kết luận cho các flow đã đọc: **chưa có golden end-to-end đang hoạt động cho
capability bounds/permissions/tag/revocation hoặc chuyển mode CHERIoT**.
Elaborate dual-ISA và chạy firmware RV32 chỉ kiểm phần RV32 của cấu hình đó.

## 2. Regression: lệnh, simulator và thời gian

### 2.1. UVM: lệnh theo Makefile hiện tại

Chuẩn bị Python dependencies theo `python-requirements.txt`, RISC-V toolchain,
lowRISC Spike libraries + `pkg-config`, simulator SystemVerilog/UVM và license.
Thiết lập `RISCV_TOOLCHAIN`, `RISCV_GCC`, `RISCV_OBJCOPY`, `SPIKE_PATH`,
`PKG_CONFIG_PATH` theo nơi cài thực tế. UVM compile cần các package
`riscv-riscv`, `riscv-disasm`, `riscv-fdt`, `riscv-fesvr`.

Từ root repo, smoke một test/seed:

```bash
make -C dv/uvm/core_ibex \
  IBEX_CONFIG=small SIMULATOR=xlm ISS=spike \
  TEST=riscv_arithmetic_basic_test ITERATIONS=1 SEED=1 \
  WAVES=0 COV=0 OUT=out-round4-smoke
```

Full regression cho `small`, giữ số iteration quy định của testlist:

```bash
/usr/bin/time -p make -C dv/uvm/core_ibex --keep-going -j4 \
  IBEX_CONFIG=small SIMULATOR=xlm ISS=spike \
  TEST=all SEED=20260909 WAVES=0 COV=1 OUT=out-round4-small
```

`-j4` là lựa chọn chạy tối đa bốn job, cần điều chỉnh theo RAM/license. Không thêm
`ITERATIONS=1` nếu muốn giữ độ sâu regression mặc định. Một subset giao diện hữu ích:
`TEST=riscv_unaligned_load_store_test,riscv_mem_error_test,riscv_interrupt_wfi_test,riscv_debug_wfi_test`.
Test bị ràng buộc `rtl_params` sẽ được lọc theo config; test trigger/PMP/security
không tự được exercise trong `small` chỉ vì đã chọn `TEST=all`.

Các stage tách bằng `GOAL=rtl_tb_compile`, `GOAL=rtl_sim_run`, `GOAL=collect_results`;
full flow đi qua generate → compile firmware → compile TB → RTL run → check logs
→ merge/report (`wrapper.mk`, `scripts/ibex_sim.mk`).
Makefile mặc định `SIMULATOR=xlm`, `IBEX_CONFIG=opentitan`, `TEST=all` và seed random.
Do đó chỉ gõ `make` không giữ cấu hình `small` hay seed của một failure.

**Simulator thực tế trong source:**

- Xcelium: `SIMULATOR=xlm`, có compile/run/DPI linking; là default và quickstart
  của `dv/uvm/core_ibex/README.md`.
- VCS: `SIMULATOR=vcs`, có co-sim linking trong YAML và hướng dẫn trong docs.
- DSim: YAML có co-sim và bước relink library; chưa xác nhận chạy ở môi trường này.
- Questa/Riviera có recipe, nhưng không nên coi tên entry là chứng minh full flow
  co-sim hoạt động. Nhánh Questa không đưa `<cosim_opts>`/Spike linking vào compile.
  Có thêm entry `qrun` trong YAML nhưng `SIM_CFGS` của Python không nhận tên này.
- Verilator: dùng target Simple System co-sim riêng, không dùng thay thế trực tiếp
  cho UVM regression nêu trên.

`COSIM=1` trong tài liệu cũ không còn là nút bật cần thiết cho UVM: metadata default
`cosim=True`, `compile_tb.py:151–159` luôn bật `cosim_opts` vì post-compare đã deprecated.
Tuy vậy cờ relax theo từng test vẫn có thể hạ mức kiểm tra.

### 2.2. Simple System co-sim và CI công khai

Ví dụ cấu hình RV32 gần `small`, sau khi có đủ toolchain:

```bash
fusesoc --cores-root=. run --target=sim --setup --build \
  lowrisc:ibex:ibex_simple_system_cosim \
  --BaseIsa=ibex_pkg::BaseIsaRV32I --RV32E=0 \
  --RV32M=ibex_pkg::RV32MFast --RV32B=ibex_pkg::RV32BNone \
  --RV32ZC=ibex_pkg::RV32Zca --RegFile=ibex_pkg::RegFileFF
make -C examples/sw/benchmarks/coremark SUPPRESS_PCOUNT_DUMP=1
./ci/run-cosim-test.sh --skip-pass-check CoreMark \
  examples/sw/benchmarks/coremark/coremark.elf
```

Đây là smoke chương trình cố định, không thay thế random IRQ/debug/memory-error UVM.
Các parameter không liệt kê dùng default của `.core`; muốn tái lập một config đầy đủ
phải kiểm toàn bộ option được truyền như composite CI action đang làm.

`.github/workflows/ci.yml` chạy CSR TB bằng Verilator, compliance và co-sim qua
[`.github/actions/ibex-rtl-ci-steps/action.yml`](../../.github/actions/ibex-rtl-ci-steps/action.yml)
trên sáu cấu hình. Action này thực sự build target `ibex_simple_system_cosim`,
chạy CoreMark, thêm PMP/security tests khi config hỗ trợ. Đây là câu trả lời rõ hơn
cho câu hỏi CI của Vòng 2: CI có dùng Simple System co-sim, không chỉ lint.
Full UVM/private regression được nối qua `private-ci.yml` tới repo CI riêng;
không có quyền/artefact trong phiên này để xác nhận job của fork đang chạy thành công.

Version pin có trong `ci/vars.env`: Verilator `v4.210`, co-sim archive `aadf648`,
toolchain `20220210-1`, cùng một pin Spike nội bộ khác.
Đó là cấu hình CI trong source, không phải tool version đã cài trên máy hay bằng
chứng các extension mới đều tương thích. Muốn replay phải giữ đúng version thực
tế của simulator/compiler/Spike, không chỉ tên branch di động.

### 2.3. Mất bao lâu: số đo nào có, số nào chưa có

Inventory tĩnh: testlist RISCV-DV có **57 test entry, tổng 1.540 iteration**;
directed list có **944 test entry/iteration**, trước lọc config.
Không cộng các số này rồi gọi đó là số test thực chạy của `small`.
Bằng chứng: [`source_inventory.json`](evidence/round4/source_inventory.json).

Default timeout mỗi RTL process/test là **1.800 giây**
(`scripts/metadata.py:74`); test có thể override `timeout_s`, nhiều directed config
dùng 300 giây. Wrapper subprocess còn có guard `run_rtl_timeout_s+60`
(`scripts/run_rtl.py:109`). **Timeout không phải runtime trung bình.**
Thời gian thực phụ thuộc build mới/cached, số seed, độ dài chương trình, waves,
coverage, jobs, RAM và license queue. Chưa có số đo full regression local nên
không khẳng định “chạy N phút/giờ”. Lệnh `/usr/bin/time` ở trên dùng để đo baseline thật.

Formal cũng không phải smoke nhẹ: README từng dùng máy 128 GiB/32 core;
CI formal có comment mốc 200 GB/~40 phút, nhưng job hiện giới hạn `MAX_MEM_GB=60`.
Đây là ghi chú tài nguyên lịch sử, không phải cam kết thời gian của checkout/máy này.

### 2.4. Lệnh đã thử trong phiên này

[`preflight.json`](evidence/round4/preflight.json) lưu full SHA, thời điểm UTC,
tool paths, argv, return code và thời gian từng command:

- `vsim -version` thành công: **Questa Sim-64 10.7c, 2018.08**. Chỉ chứng minh
  binary chạy được; không xác nhận license, UVM compatibility hay DPI link.
- Spike setup check exit 1: **`pkg-config: not found`**.
  Không diễn giải thành kết quả kiểm libraries của Spike vì chưa gọi được pkg-config.
- Smoke UVM `small`, arithmetic, seed 1, `SIMULATOR=xlm`, OUT trong `/tmp`:
  exit 2 sau **0,211 giây**, vì `ModuleNotFoundError: pathlib3x` ở metadata setup.
  **Chưa compile RTL, chưa step Spike, chưa có test PASS/FAIL của DUT.**
- Trên PATH chưa tìm thấy `xrun`, `vcs`, `verilator`, `fusesoc`, `spike`,
  compiler RISC-V, `nix`, `yosys`, `jg`, `rIC3`. Không kết luận máy không có chúng
  ở bất kỳ nơi nào; đây là trạng thái shell hiện tại.

Log gốc: [`uvm_smoke_attempt.log`](evidence/round4/uvm_smoke_attempt.log),
[`spike_setup_check.log`](evidence/round4/spike_setup_check.log),
[`questa_version.log`](evidence/round4/questa_version.log).
Không cài lại toolchain hay thay simulator trong vòng phân tích này.

## 3. Known issues, deviation và kết quả upstream

### 3.1. Bằng chứng regression công khai có revision riêng

[Báo cáo upstream truy cập ngày 2026-09-09](https://ibex.reports.lowrisc.org/opentitan/latest/report.html)
hiển thị run **2026-09-04 04:18 UTC**, commit **`34b0705`**, config `opentitan`:
**1.456/1.530 pass, 95,2%; functional coverage 89,5%**.
Có mismatch thực: một log báo ISS chờ synchronous trap tại `0x80002800`,
DUT báo PC `0x80011bc4`. Chưa xác định nguyên nhân là RTL, model hay stimulus.
Đây không phải kết quả của `8031c7dd`/`small`; URL `latest` có thể thay đổi.

### 3.2. Issue tracker: đối chiếu applicability với local RTL

Các issue dưới đây hiển thị Open khi truy cập. Đây là snapshot các vấn đề liên quan,
không phải danh sách đầy đủ hay xác nhận đã tái hiện local. Issue tracker của fork
`dungpcaudio9999/ibex` không tải được qua web trong phiên này; không suy ra nó không có issue.

**RVFI reporting — [#2476](https://github.com/lowRISC/ibex/issues/2476), mở 2026-08-20.**
Người báo cáo thấy memory read mask khác 0 ở instruction không truy cập memory.
Local `rtl/ibex_core.sv:2084–2085` vẫn chọn mask chỉ theo `data_we_o`, chưa qualify
bằng memory instruction. Đây là source phù hợp với báo cáo, liên quan cả `small`
khi bật RVFI; chưa tái hiện waveform local. Spike scoreboard dùng data-access
monitor riêng, nên ISS match không bảo đảm mọi field RVFI hợp lệ.

**Debug/PMP — [#2474](https://github.com/lowRISC/ibex/issues/2474), mở 2026-08-14.**
Issue báo Debug Mode vẫn áp MPRV dù `dcsr.mprven=0`.
Local `rtl/ibex_cs_registers.sv:826,997` hardwire `mprven=0` nhưng chọn LSU privilege
chỉ theo `mstatus.mprv/mpp`. Mẫu logic còn hiện diện; cần directed debug/PMP replay.
`small` tắt PMP nên không đại diện cho kịch bản PMP fault trong issue.

**DRET/PMP — [#2473](https://github.com/lowRISC/ibex/issues/2473), mở 2026-08-13.**
Issue báo DRET về U-mode để MPRV còn set, làm sai privilege của data access.
Local nhánh DRET chỉ khôi phục `priv_lvl_d`; nhánh MRET mới có clear MPRV
(`rtl/ibex_cs_registers.sv:948–962`). Source phù hợp; chưa tái hiện test local.
Đây là lý do không dùng tuyên bố “Debug Spec compliant” thay cho test chuyển privilege.

**Smepmp — [#2491](https://github.com/lowRISC/ibex/issues/2491), mở 2026-09-03.**
Issue báo MML chặn ghi `pmpcfg` cho OFF/invalid TOR quá rộng.
Local `is_mml_m_exec_cfg` bỏ qua `mode`, còn `pmp_cfg_wr_suppress` dùng hàm này
(`rtl/ibex_cs_registers.sv:164,1466`). Cần kiểm khi `PMPEnable=1` và dùng MML;
không coi issue là lỗi đã chạy lại, không áp dụng trực tiếp cho `small` không PMP.

**CHERIoT/ECC — [#2480](https://github.com/lowRISC/ibex/issues/2480), mở 2026-08-21.**
Issue báo shared register storage dùng ECC khác nhau giữa integer và capability
khi đổi mode, có thể gây alert giả. Local có `rf_shared` và cấu hình ECC shadow,
nhưng chưa kiểm closure/fix toàn đường hoặc tái hiện. Liên quan dual-ISA + ECC;
không áp dụng cho `small`. Harness runtime Off hiện tại không exercise việc đổi mode.

### 3.3. Deviation/waiver trong repo cần đọc cùng kết quả PASS

- [Compliance overview](../01_overview/compliance.rst) công bố Privileged 1.12,
  Debug **0.13.2**, trong khi trang exception/debug còn ghi 1.11/0.13.
  Vòng 3 đã được bổ sung bản công bố cụ thể hơn. Đây là lệch tài liệu/version,
  không phải tự nó chứng minh một implementation failure.
- Custom fast IRQ, NMI, CSR và các extension B draft đòi hỏi Spike phù hợp;
  không phải mọi chênh với Spike upstream đều là bug của DUT.
- Composite CI action còn chấp nhận mẫu log **`FAIL: 4/48`** của `rv32i` như expected
  failure, dẫn tới [issue #100](https://github.com/lowRISC/ibex/issues/100), hiện Closed.
  Đây là waiver theo tổng số lỗi, không định danh chính xác bốn testcase; có thể
  che một tập failure khác cùng số lượng. Chưa chạy compliance suite local để
  xác định waiver có đang được kích hoạt hay đã hết cần thiết.
- Coverage waiver ở `dv/uvm/core_ibex/waivers/coverage_waivers_xlm.tcl`, VCS coverage
  scope ở `cover.cfg`; phải đọc denominator/exclusion cùng coverage percentage.
  Không coi waived/unreachable code là đã được exercise.
- `DV_ASSERT_CTRL` trong UVM TB cho phép tắt nhóm NoAlerts/spurious response, gồm
  assertion TRVK tùy cấu hình (`tb/core_ibex_tb_top.sv:214–232`). Fault injection
  cần disable có chủ đích, nhưng phải lưu trạng thái disable trong evidence.

### 3.4. Một lỗi tiềm ẩn trong chính bộ chọn regression

`scripts/ibex_cmd.py:150–188` append test ngay bên trong vòng duyệt từng
`rtl_params`. Nếu điều kiện đầu match nhưng điều kiện sau fail, test đã được thêm;
nếu hai điều kiện đều match, test có thể được thêm hai lần.

Đã chạy **chính function lấy từ AST source**, bỏ decorator typeguard vì môi trường
thiếu dependency, với hai input tổng hợp: case cần bị loại vẫn được trả về,
case hợp lệ bị trả hai lần. Kết quả:
[`filter_probe.json`](evidence/round4/filter_probe.json),
script tái lập [`filter_probe.py`](evidence/round4/filter_probe.py).
Đây là reproduction Python, không phải test RTL. Hai YAML đọc trong phiên này
không có entry trực tiếp với nhiều hơn một `rtl_params`; vì vậy chưa chứng minh
lỗi này làm sai số testcase của regression hiện tại. Không sửa checker trong vòng audit.

## 4. Assertion và formal: có gì, đang chứng minh phần nào?

### 4.1. Assertion trong RTL

Đếm tĩnh các dòng gọi macro `ASSERT*` trong `rtl/*.sv`: **168 lời gọi ở 20 file**.
Con số này chưa elaborate generate/parameter, chưa preprocess và không phải số
property active hay proven. Inventory theo file nằm trong `source_inventory.json`.

Ví dụ có nội dung kiểm cụ thể:

- `IbexDataAddrUnaligned`: khi request data, address phải word-aligned
  (`rtl/ibex_load_store_unit.sv:830`).
- `PipeEmptyOnIrq`: điều kiện pipeline khi nhận IRQ
  (`rtl/ibex_controller.sv:1078`).
- `IbexPipelineFlushOnChangingDebugMode`: flush khi đổi debug mode
  (`rtl/ibex_controller.sv:1114`).
- `RevbmReqStable_A`: giữ request/address khi chờ grant;
  `RevbmRspOnlyWhenOutstanding_A`: không trả bitmap unsolicited;
  `DsRspFifoNoOverflow_A`: FIFO response không overflow
  (`rtl/ibex_trvk.sv:411–415`).
- Nhiều `ASSERT_KNOWN`, kiểm state hợp lệ, boot alignment và parameter legality.

**Điểm quyết định là compile backend:** `prim_assert.sv:102–114` chọn dummy macros
khi `VERILATOR` hoặc `SYNTHESIS`. `prim_assert_dummy_macros.svh` định nghĩa
ASSERT/ASSUME/COVER thành rỗng. Do đó trong flow dùng đúng header/define này,
`--assert` không phục hồi macro đã bị loại trước compile.
Điều này không xóa checker C++/DPI hay mọi raw SV assertion. Một run Verilator
co-sim vẫn có thể kiểm Spike dù các macro SVA này không hoạt động.
Muốn nói assertion đã pass phải xác nhận preprocessing, enable, activation và
negative test của build cụ thể; chưa có bằng chứng ấy ở phiên này.

### 4.2. Có flow formal mới so với Sail

[`dv/formal/README.md`](../../dv/formal/README.md) mô tả trace equivalence giữa RTL
và model Sail RISC-V, không chỉ một thư mục assertion để tham khảo.
`spec/main.sail`, `check/top.sv`, `thm/*.proof`, psgen và Sail SV backend dựng
spec/checker và chia proof thành các lemma.

- `Top`: kết quả instruction đúng khi retire trong miền được kiểm.
- `Wrap`: nối trạng thái giữa các lần `spec_en` để suy ra equivalence qua trace.
- `Load`, `Store`, `NoMem`: hành vi memory của instruction.
- `Live`: bảo đảm có bước kiểm tiếp theo; **đang comment out** cùng một số
  liveness lemma (`thm/riscv.proof:136,178`). Không tính mục này là đã proven.

Lệnh Jasper từ root, khi đã cài tool/dependency/license:

```bash
nix develop .#formal
cd dv/formal
make
# Hoặc make jg để mở interactive session
```

Flow OSS theo CI, từ root trong shell mới:

```bash
nix develop .#oss-dev
cd dv/formal
make build/aig-manip
make build/all.aig SHELL=bash
python3 conductor.py prove --check-complete --max-mem 60
```

Backend OSS là Yosys/plugins + rIC3/AIG orchestration, không phải chỉ gõ `sby`
trên một `.sby`. `.github/workflows/ci-formal.yml` chứa các lệnh này.
Sự tồn tại workflow không xác nhận proof tại local HEAD; chưa có engine log,
lemma completion, counterexample hay cover/vacuity report mới trong phiên này.

### 4.3. Giả định và lỗ hổng của proof

Formal harness không cùng cấu hình `small`: top mặc định `WritebackStage=1`,
instantiate PMP và BranchTargetALU bật; chọn BaseIsaRV32I, runtime CHERIoT Off
(`check/top.sv:36–43,171–184`). README còn mô tả `ResetAll=1` và bỏ clock gating,
nhưng chưa xác nhận được phần biến đổi này trong build hiện tại: `ibex_top`
vẫn dẫn xuất ResetAll từ SecureIbex. Phải đối chiếu elaborated model/log của run,
không coi mô tả lịch sử trong README là cấu hình RTL đã đo được.

Các giới hạn thấy trực tiếp trong source:

1. `check/protocol/mem.sv`: assume không bus error, response chỉ khi outstanding,
   grant chỉ khi request. `TIME_LIMIT=5` cho nhánh bound thông thường; **nhánh YOSYS
   mạnh hơn**: request phải được grant ngay và outstanding phải có response.
   Không suy ra proof cho mọi memory latency hợp lệ của bus Vòng 3.
2. `check/protocol/irqs.sv`: không NMI, không fast IRQ; IRQ giữ tới data grant;
   WFI phải wake trong `WFI_BOUND=20`. Đây là assumptions môi trường.
3. `check/top.sv:188–196`: cấm Debug Mode/debug request, giữ boot constant,
   fetch enabled. Có thêm assumption `mcounteren_q==0` ở dòng 491.
4. README nêu chưa chứng minh reset base case và chưa chứng minh instruction ở
   PC được fetch đúng từ địa chỉ đó; một số CSR ngoài miền check được bỏ qua.
5. README còn ghi M-types chưa conclusive và mô tả liveness/bounds lịch sử khác
   source. Chỉ log proof đúng revision mới quyết định trạng thái thực tế.

Vì proof cấm debug và loại CHERIoT nên không dùng nó để phủ định các issue
debug/PMP/CHERIoT ở mục 3. Cũng không dùng functional equivalence để tuyên bố
side-channel/security closure.

### 4.4. Tài sản formal cũ khác với flow đang có recipe

`formal/icache/README.md` và `formal/data_ind_timing/README.md` còn ghi chưa có cách
chạy các assertion trong thư mục đó. Chúng là source asset, không phải proof result.
Trang `doc/03_reference/rvfi.rst` ghi “not yet formally verified” cũng không đủ để
kết luận repo hiện không có formal: cần phân biệt trang cũ với flow Sail mới,
và tiếp tục phân biệt flow tồn tại với proof đã đóng cho cấu hình đang dùng.

## 5. Biến “tôi nghĩ core đúng” thành lỗi tại instruction/PC cụ thể

Một gói evidence có thể replay cần chứa:

1. **DUT/model:** full git SHA + dirty diff, toàn bộ parameter/define, phiên bản
   simulator, compiler, Spike commit/build flags, formal model/dependency lock nếu dùng.
2. **Stimulus:** tên test, seed generator/RTL, ELF/bin và hash; đừng chỉ giữ seed
   vì đổi generator/compiler có thể tạo chương trình khác.
3. **Checker:** co-sim hoạt động, `relax_cosim_check=0` cho test kiến trúc thông thường,
   số instruction đã so >0; danh sách assertion enabled/disabled và coverage waiver.
4. **Failure:** PC DUT/ISS, register hoặc memory transaction sai, trap/IRQ state,
   `rvfi_order`/step index phù hợp và waveform quanh lỗi. Không gọi bất kỳ số cycle
   hay dòng log nào là instruction thứ N nếu chưa đối chiếu stream.
5. **Replay:** giữ nguyên config/test/seed/binary, bật `WAVES=1` khi rerun; giảm
   chương trình sau khi đã tái hiện, rồi giữ testcase làm regression.
6. **Độ nhạy:** đưa một sai lệch có kiểm soát vào observed result/response trong
   harness thử nghiệm, chứng minh checker báo fail đúng vị trí; positive PASS
   một mình không chứng minh checker thực sự đang quan sát DUT.

UVM đặt artefact tại `OUT/run/tests/<test>.<seed>/`: `rtl_sim.log`,
`trace_core_00000000.log`, `spike_cosim_trace_core_00000000.log`, `trr.yaml`.
`OUT/run` có report HTML/JSON và các summary/JUnit theo metadata.
Các tên/path này có trong `scripts/run_rtl.py:57–59`, `wrapper.mk`, `collect_results.py`.
Message `Cosim mismatch` hiện không luôn in `rvfi_order`; muốn kết luận đúng “lệnh
thứ N” phải nối log/waveform với RVFI order hoặc bổ sung diagnostic tại scoreboard.

**Trạng thái sau Vòng 4:** đã truy checker và formal assumptions, kiểm issue/report
upstream, lưu preflight + smoke setup failure và tái hiện một lỗi Python filter
trên input tổng hợp. Chưa có regression DUT/Spike pass local, chưa có proof local,
chưa có CHERIoT end-to-end evidence. Bước thực thi tiếp theo là dựng môi trường
co-sim phù hợp, chạy một seed có checker active rồi mới mở rộng regression.
