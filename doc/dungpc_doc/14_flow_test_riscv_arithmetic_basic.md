# 14 — Flow test `riscv_arithmetic_basic_test`

> Mọi số liệu trong tài liệu này lấy từ **lần chạy thật** trên máy này
> (`out/run/tests/riscv_arithmetic_basic_test.1/`, VCS X-2025.06, seed 1).

---

## 1. Tóm tắt một dòng

Sinh ngẫu nhiên **10.000 lệnh số học/logic/nhân-chia/CSR** (không load/store, không
branch/jump), chạy trên RTL, và so khớp **từng lệnh retire** với Spike qua RVFI.
Test pass khi cả 10.448 lệnh khớp **và** chương trình ghi signature `TEST_PASS`.

---

## 2. Hai nửa của flow

```
╔════════════════ NỬA 1: SINH CHƯƠNG TRÌNH (offline) ════════════════╗
  ibex_configs.yaml ──render_config_template.py──► riscv_core_setting.sv
                                                          │
  riscv-dv generator (biên dịch & CHẠY bằng chính VCS) ◄───┘
        + gen_opts từ testlist.yaml
                     │
                     ▼  test.S  (13.792 dòng)
  riscv32-unknown-elf-gcc ──► test.o ──objcopy──► test.bin
╚════════════════════════════════════════════════════════════════════╝
                     │
╔════════════════ NỬA 2: MÔ PHỎNG & KIỂM TRA ═══════════════════════╗
                     ▼ backdoor load (CẢ 2 nơi)
      ┌──────────────────────┐        ┌────────────────────┐
      │  mem_model của UVM   │        │  Spike (DPI trong  │
      │  (instr + data)      │        │  cùng tiến trình)  │
      └──────────┬───────────┘        └─────────┬──────────┘
                 │ phục vụ req                   │ step từng lệnh
                 ▼                               │
          ibex_top (DUT) ──RVFI──► ibex_cosim_scoreboard ◄┘
                 │                        │ so PC/rd/wdata
                 │ sw 0x8ffffff8          │
                 ▼                        ▼
        handshake signature        uvm_fatal nếu lệch
╚════════════════════════════════════════════════════════════════════╝
```

---

## 3. Bước 1 — Cấu hình generator

`scripts/render_config_template.py` đọc config `opentitan` từ `ibex_configs.yaml` và
render `riscv_dv_extension/riscv_core_setting.tpl.sv` → `riscv_core_setting.sv`:

```systemverilog
parameter int XLEN    = 32;
parameter int NUM_GPR = 32;
privileged_mode_t supported_privileged_mode[] = {MACHINE_MODE, USER_MODE};
riscv_instr_group_t supported_isa[$] = {RV32I, RV32M, RV32C,
                                        RV32ZBA, RV32ZBB, RV32ZBC, RV32ZBS, RV32B};
mtvec_mode_t supported_interrupt_mode[$] = {VECTORED};
int max_interrupt_vector_num = 32;
bit support_pmp        = 1;
bit support_epmp       = 1;
bit support_debug_mode = 1;
bit support_umode_trap = 0;
bit support_unaligned_load_store = 1'b1;
```

`RV32ZBA/ZBB/ZBC/ZBS + RV32B` đến từ `RV32B = RV32BOTEarlGrey`;
`RV32C` từ `RV32ZC = RV32ZcaZcbZcmp`; `support_pmp/epmp` từ `PMPEnable=1`.

---

## 4. Bước 2 — Sinh chương trình

`riscv_dv_extension/testlist.yaml:5-17`:

```yaml
- test: riscv_arithmetic_basic_test
  gen_test: riscv_instr_base_test
  gen_opts: >
    +instr_cnt=10000
    +num_of_sub_program=0
    +no_fence=1
    +no_data_page=1
    +no_branch_jump=1
    +boot_mode=m
  iterations: 10
  rtl_test: core_ibex_base_test
```

| gen_opt | Tác dụng |
|---|---|
| `+instr_cnt=10000` | 10.000 lệnh ngẫu nhiên trong `main` |
| `+num_of_sub_program=0` | Không sinh sub-program → không có call/return |
| `+no_fence=1` | Không `FENCE`/`FENCE.I` |
| `+no_data_page=1` | **Không tạo data page → không có load/store** |
| `+no_branch_jump=1` | **Không branch/jump trong luồng ngẫu nhiên** |
| `+boot_mode=m` | Khởi động ở Machine mode |

Generator **được biên dịch và chạy bằng chính VCS** (`instr_gen_build` → `instr_gen_run`),
không phải Python.

---

## 5. Cấu trúc `test.S` thực tế (13.792 dòng)

```
_start / h0_start        csrw misa, 0x40001106
kernel_sp                la x12, kernel_stack_end
trap_vec_init            mtvec = mtvec_handler | 1        ← mode = VECTORED
pmp_setup                mseccfg=4; pmpaddr0..15; pmpcfg0..3
mepc_setup               mepc = init
custom_csr_setup         csrwi 0x7c0, 1                   ← CPUCTRLSTS.icache_enable = 1
init_machine_mode        mstatus=0x1800 (MPP=M); mie=0; ghi signature; mret
init                     li x0..x31 = hằng ngẫu nhiên; la x26, user_stack_end; j main
test_done                ghi signature TEST_PASS → ecall
test_fail                ghi signature TEST_FAIL → ecall
mmode_intr_vector_1..31  31 vector ngắt (save/restore GPR)
mtvec_handler            phân loại trap
mmode_exception_handler
ecall_handler
instr_fault_handler
load_fault_handler
store_fault_handler
main                     10.000 lệnh ngẫu nhiên          ← THÂN BÀI TEST
write_tohost             sw gp, tohost, t5
```

> **Đáng chú ý:** `csrwi 0x7c0, 1` bật **I-Cache** ngay từ đầu.
> Bit 0 của `cpu_ctrl_sts_part_t` chính là `icache_enable`
> (xem [10_csr_pmp_counter](10_csr_pmp_counter.md) §2.9).
> Vậy test này **có** thực thi đường I-Cache, dù không đụng D-side.

---

## 6. `main` chứa gì (đo trực tiếp)

Phân bố lệnh (top 25 trong 10.000):

| Lệnh | SL | Lệnh | SL | Lệnh | SL |
|---|---|---|---|---|---|
| `c.sub` | 235 | `c.srli` | 215 | `c.slli` | 204 |
| `mulhsu` | 231 | `xor` | 212 | `csrrc` | 203 |
| `slli` | 230 | `csrrs` | 212 | `slt` | 201 |
| `c.xor` | 224 | `rem` | 211 | `srai` | 200 |
| `c.srai` | 220 | `c.or` | 210 | `div` | 200 |
| `mulh` | 218 | `c.lui` | 210 | `csrrwi` | 200 |
| … | | `or` / `xori` / `srli` / `sltiu` / `andi` / `mul` / `csrrw` | ~204–209 | | |

**Kiểm chứng ràng buộc:**

| Kiểm tra | Kết quả |
|---|---|
| Số lệnh load/store trong `main` | **0** |
| Số lệnh branch/jump trong `main` | **1** — duy nhất `jalr x0, x2, 0` ở dòng cuối để nhảy tới `test_done` |
| Số lệnh CSR | **1205** |
| CSR nào bị đụng | **chỉ `0x340` (`mscratch`)** |

`mscratch` được chọn vì nó nằm trong danh sách **miễn pipeline-flush**
(`no_flush_csr_addr = {CSR_MSCRATCH, CSR_MEPC}` — [05_tang_ID](05_tang_ID.md) §2.3),
nên ghi nó không gây flush và an toàn về mặt kiến trúc.

### Vậy test này thực sự kiểm cái gì?

| Khối vi kiến trúc | Được kiểm | Ghi chú |
|---|---|---|
| `ibex_alu` — adder/comparator/shifter/bitwise | ✅ mạnh | `add/sub/xor/or/and/sll/srl/sra/slt/sltu` + immediate |
| `ibex_alu` — bitmanip Zb* | ⚠️ một phần | generator có bật `RV32ZBA/ZBB/ZBC/ZBS` nhưng seed này chủ yếu ra lệnh cơ bản |
| `ibex_multdiv_fast` — nhân | ✅ mạnh | `mul/mulh/mulhsu/mulhu` ~850 lệnh |
| `ibex_multdiv_fast` — chia | ✅ mạnh | `div/divu/rem/remu` ~800 lệnh, mỗi lệnh 37 chu kỳ |
| `ibex_compressed_decoder` (Zca) | ✅ mạnh | ~2.000 lệnh `c.*` |
| Zcb / Zcmp | ❌ | không sinh trong seed này |
| `ibex_cs_registers` | ⚠️ hẹp | chỉ `mscratch`, 1205 lệnh; đủ test đường `csr_op_e` |
| Forwarding WB→ID | ✅ mạnh | luồng ALU dày đặc, phụ thuộc dữ liệu liên tục |
| `stall_multdiv` | ✅ | MULH/DIV/REM |
| I-Cache | ✅ | được bật; miss/fill/hit trên 10k lệnh tuần tự |
| LSU + D-bus | ❌ | không có load/store |
| Branch/jump + BT-ALU | ❌ | bị chặn bởi `+no_branch_jump=1` |
| PMP | ⚠️ tĩnh | `pmp_setup` cấu hình 16 vùng nhưng không có truy cập vi phạm |
| Interrupt / Debug | ❌ | `enable_irq_*`, `enable_debug_seq` = 0 ở base test |
| CHERIoT | ❌ | `cheriot_enable_i` không bật ở base test |

→ Đây là test **"smoke test cho datapath số học"**, cố ý loại bỏ nhiễu từ bộ nhớ và
luồng điều khiển để cô lập lỗi ALU/MULDIV/decoder.

---

## 7. Bước 3 — Biên dịch

`scripts/compile_test.py`:

```
$RISCV_GCC  -march=... -mabi=ilp32 ... test.S -o test.o
$RISCV_OBJCOPY -O binary test.o test.bin
```

Log: `compile_gen.riscv-dv.log`, `compile.riscvdv.log`.

---

## 8. Bước 4 — Chạy mô phỏng (UVM)

`tests/core_ibex_base_test.sv:225-241`:

```systemverilog
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  dut_vif.dut_cb.fetch_enable <= ibex_pkg::IbexMuBiOff;   // 1. giữ CPU đứng yên
  clk_vif.wait_clks(100);                                 // 2. chờ 100 chu kỳ
  load_binary_to_mems();                                  // 3. backdoor nạp test.bin
  dut_vif.dut_cb.fetch_enable <= ibex_pkg::IbexMuBiOn;    // 4. thả CPU chạy
  fork
    send_stimulus();                                      // 5. vseq (stimulus nền)
    handle_reset();
  join_none
  wait_for_test_done();                                   // 6. chờ kết thúc
  phase.drop_objection(this);
endtask
```

`load_binary_to_mems()` nạp **cùng một binary vào cả hai nơi**: mem_model của UVM
(để DUT fetch) và bộ nhớ của Spike (để ISS chạy song song).

### Stimulus nền vẫn có, dù là "base test"

| Nguồn | Trạng thái ở base test |
|---|---|
| `ibex_mem_intf_response_seq` — **rvalid_delay ngẫu nhiên** | ✅ bật (phân phối `dist`) |
| `enable_spurious_dside_responses` | ✅ bật, `spurious_response_pct = 20` — bơm **phản hồi bus giả** để kiểm cơ chế chống spurious response |
| `fetch_enable_seq` (`InfiniteRuns`) | ✅ bật |
| `enable_irq_single_seq` / `_multiple_seq` / `_nmi_seq` | ❌ tắt |
| `enable_debug_seq` | ❌ tắt |
| `enable_mem_intg_err` | ❌ tắt |
| `enable_double_fault_detector` | ✅ bật |

→ Ngay cả test "cơ bản" cũng có **độ trễ bus ngẫu nhiên** và **phản hồi giả**, nên
đường `lsu_load_err & outstanding_load_wb` ([11_security](11_security.md) §2.11) vẫn được
kích hoạt.

---

## 9. Ba lớp kiểm tra

### Lớp 1 — Co-simulation từng lệnh (lớp chính)

`common/ibex_cosim_agent/ibex_cosim_scoreboard.sv`, task `run_cosim_rvfi`:

```systemverilog
forever begin
  rvfi_port.get(rvfi_instr);                       // 1 lệnh vừa retire trên RVFI
  riscv_cosim_set_mip(cosim_handle, rvfi_instr.pre_mip, rvfi_instr.post_mip);
  riscv_cosim_set_nmi(...);  riscv_cosim_set_nmi_int(...);
  riscv_cosim_set_debug_req(...);  riscv_cosim_set_mcycle(...);
  riscv_cosim_set_ic_scr_key_valid(...);
  if (!riscv_cosim_step(cosim_handle, rvfi_instr.rd_addr, rvfi_instr.rd_wdata,
                        rvfi_instr.pc, rvfi_instr.trap))
    `uvm_fatal(`gfn, get_cosim_error_str())        // lệch → dừng ngay
end
```

Spike thực thi **đúng 1 lệnh** rồi so `pc`, `rd_addr`, `rd_wdata`, `trap`.
Các trạng thái bất đồng bộ (`mip`, NMI, debug_req, `mcycle`) được **bơm từ RTL sang ISS**
trước mỗi bước để hai bên không lệch.

Các task song song khác: `run_cosim_dmem` (thông báo truy cập D-side),
`run_cosim_imem`, `run_cosim_ifetch`, `run_cosim_ifetch_pmp`, `run_cosim_imem_errors`.

**Kết quả lần chạy thật:**
```
Co-simulation matched      10448 instructions
```

### Lớp 2 — Handshake signature (điều kiện kết thúc)

| Địa chỉ | Dùng cho |
|---|---|
| `0x8ffffffc` | `signature_addr` — ghi CSR/core-status |
| `0x8ffffff8` | `signature_addr - 4` — **kết quả test** |

Trong `test.S`:
```asm
test_done:  li x29, 0x8ffffff8
            li x10, 0x0 ; slli x10,x10,8 ; addi x10,x10,0x1   # data=0 (PASS), type=1
            sw x10, 0(x29)
            ecall
test_fail:  ... data=1 (FAIL), type=1 ...
```

`wait_for_test_done()` bắt giao dịch ghi tới địa chỉ đó:
`TEST_PASS` → kết thúc bình thường; `TEST_FAIL` → `uvm_fatal`.

### Lớp 3 — Bộ đếm thời gian & double-fault

`wait_for_test_done()` chạy `fork ... join_any` gồm 5 nhánh:

1. Handshake signature (trên)
2. **Double-fault detector** — quá ngưỡng → `uvm_fatal`
3. **Timeout theo chu kỳ** (`timeout_in_cycles`) → `uvm_fatal "TEST TIMEOUT!!"`
4. **Timeout wall-clock** (`+test_timeout_s=1800`) → fatal hoặc kết thúc êm
5. `wait_for_custom_test_done()` (hook cho test dẫn xuất)

Khi kết thúc: `vseq.stop()` → hạ `fetch_enable` → chờ 3000 chu kỳ cho lệnh dở dang.

---

## 10. Bước 5 — Kết luận pass/fail

`scripts/check_logs.py:27-81`:

```python
if trr.failure_mode == Failure_Modes.TIMEOUT:      trr.passed = False
try:    process ibex trace
except: trr.passed = False; FILE_ERROR
uvm_pass, _, uvm_failure_mode = check_ibex_uvm_log(trr.rtl_log)
if not uvm_pass:  trr.passed = False     # có UVM_ERROR / UVM_FATAL
...
trr.passed = True
```

→ ghi `trr.yaml`, rồi `collect_results.py` gộp thành `out/run/regr.log`.

> Với VCS, `trr.rtl_log` được chuyển sang `rtl_sim_stdstreams.log`
> (`run_rtl.py`: *"Since we cannot pass the logfile to VCS as an argument"*).

---

## 11. Số liệu lần chạy thật (seed 1)

| Chỉ số | Giá trị |
|---|---|
| Dòng `test.S` | 13.792 |
| Lệnh ngẫu nhiên trong `main` | 10.000 |
| Lệnh khớp cosim | **10.448** (gồm cả init/handler) |
| Bắt đầu chạy chương trình | 202.400 ps |
| Kết thúc (handshake PASS) | 158.758.400 ps → **~158,6 µs** |
| CPU time | 8,8 s |
| `UVM_ERROR` / `UVM_FATAL` | 0 / 0 |
| Kết quả | `100.00% PASS 1 PASSED, 0 FAILED` |

---

## 12. Tín hiệu nên xem khi debug test này

Dùng [verdi/ibex_opentitan.rc](verdi/README.md), tập trung các nhóm:

| Nhóm | Vì sao |
|---|---|
| `01_RVFI_RETIRE` | Đối chiếu trực tiếp với `spike_cosim_trace_core_00000000.log` |
| `04_IF_ID_REG`, `05_ID_CONTROLLER` | Lệnh nào đang ở ID, FSM đang ở trạng thái nào |
| `06_STALL_HAZARD` | `stall_multdiv` sẽ rất bận (div 37 chu kỳ) |
| `07_REGFILE` | Kiểm forwarding WB→ID |
| `08_EX_ALU_MULDIV` | `md_state_q`, `div_counter_q` |
| `03_ICACHE` | I-Cache được bật bởi `csrwi 0x7c0, 1` |
| `10`, `11` (LSU/D-bus) | Gần như im lặng — có thể collapse |

Đối chiếu trace:
```bash
T=out/run/tests/riscv_arithmetic_basic_test.1
head -20 $T/trace_core_00000000.log            # trace RTL
head -20 $T/spike_cosim_trace_core_00000000.log # trace Spike
```

---

## 13. Chạy biến thể

```bash
cd /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex

# nhiều seed để tăng phủ
make IBEX_CONFIG=opentitan SIMULATOR=vcs ISS=spike \
     TEST=riscv_arithmetic_basic_test ITERATIONS=10

# muốn có load/store + branch: dùng test khác
make ... TEST=riscv_machine_mode_rand_test      # đầy đủ, 5 sub-program
make ... TEST=riscv_rand_instr_test             # + ghi nhiều CSR
make ... TEST=riscv_mmu_stress_test             # nặng về load/store
```
