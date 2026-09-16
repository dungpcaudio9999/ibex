# 05 — Tầng ID (Instruction Decode / Execute)

Tệp: `ibex/rtl/ibex_id_stage.sv` (1302 dòng), `ibex_decoder.sv` (1490), `ibex_controller.sv` (1133).

Trong Ibex, ID và EX **là một tầng pipeline**. `ibex_id_stage` chứa: bộ giải mã,
controller FSM, mux toán hạng, logic hazard/forwarding, và FSM ID-EX 2 trạng thái.

---

## 1. Bộ giải mã `ibex_decoder`

### 1.1 Cấu trúc

Module **tổ hợp thuần** (clk/rst chỉ dùng cho flop `use_rs3_q` và assertion).
Có **hai** khối `always_comb` lớn:

| Khối | Dòng | Đầu vào | Đầu ra |
|---|---|---|---|
| "Decoder" | `:265-921` | `instr` (= `instr_rdata_i`) | Điều khiển RF/LSU/CSR/jump/branch/CHERIoT |
| "Decoder for ALU control" | `:927-1444` | `instr_alu` (= `instr_rdata_alu_i`) | `alu_operator_o`, `alu_op_a/b_mux_sel_o`, `imm_*_mux_sel_o`, `mult/div_sel_o` |

Tách đôi để bản sao `instr_rdata_alu_i` chỉ điều khiển đường ALU (critical path),
giảm fan-out của flop `instr_rdata_id`.

### 1.2 Trích immediate

`ibex_decoder.sv:161-171`

```systemverilog
imm_i_type_o    = {{20{instr[31]}}, instr[31:20]};
imm_s_type_o    = {{20{instr[31]}}, instr[31:25], instr[11:7]};
imm_b_type_o    = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
imm_u_type_o    = {instr[31:12], 12'b0};
imm_j_type_o    = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
zimm_rs1_type_o = {27'b0, instr_rs1};
```

Immediate CHERIoT riêng (`ibex_decoder.sv:1465-1478`):

```systemverilog
cheriot_imm12_o = (CJALR|CSET_BOUNDS_IMM|CINC_ADDR_IMM|CLOAD_CAP) ? {instr[31:25],instr[24:20]}
                : CSTORE_CAP                                      ? {instr[31:25],instr[11:7]}
                : 12'h0;
cheriot_imm20_o = (CAUIPCC|CAUICGP) ? instr[31:12] : 20'h0;
cheriot_imm21_o = CJAL ? {instr[31],instr[19:12],instr[20],instr[30:21],1'b0} : 21'h0;
```

### 1.3 Địa chỉ thanh ghi

`ibex_decoder.sv:202-223`

```systemverilog
raddr_a = cheriot_operator_o.CAUICGP ? 5'h3 :                       // AUICGP đọc cgp = c3
          ((use_rs3_q & ~instr_first_cycle_i) ? instr_rs3 : instr_rs1);
raddr_b = instr_rs2;

// CheriLimit16Regs = (BaseIsa == BaseIsaRV32IorCHERIoT) = 1
rf_raddr_a_o = cheriot_on ? {1'b0, raddr_a[3:0]} : raddr_a;
rf_raddr_b_o = cheriot_on ? {1'b0, raddr_b[3:0]} : raddr_b;
rf_waddr_o   = cheriot_on ? {1'b0, instr_rd[3:0]} : instr_rd;
```

* `use_rs3_q` cho lệnh ternary bitmanip (`fsl/fsr/cmix/cmov`): chu kỳ 1 đọc rs1,
  chu kỳ 2 đọc rs3 (= `instr[31:27]`). Flop chỉ tồn tại khi `RV32B != RV32BNone`.
* `CAUICGP` ép `raddr_a = 3` — thanh ghi `cgp` (global pointer capability). Comment giải
  thích: dùng đường RF thường thay vì sideband để **logic hazard hiện có tự xử lý**.
* CHERIoT cắt về 4 bit; bit [4] bị bỏ, và một `illegal_reg_16` được sinh song song.

### 1.4 Kiểm tra dải thanh ghi

`ibex_decoder.sv:230-246`

```systemverilog
rf_we_or_load  = rf_we | (opcode == OPCODE_LOAD);      // load ghi RF từ LSU, không qua rf_we

illegal_reg_16 = (RV32E || cheriot_on) &&
                 ((raddr_a[4]   && rf_ren_a_o) ||
                  (raddr_b[4]   && rf_ren_b_o) ||
                  (instr_rs3[4] && use_rs3_d && rf_ren_a_o) ||
                  (instr_rd[4]  && rf_we_or_load));

illegal_insn_o = illegal_insn | illegal_reg_16;
rf_we_o        = rf_we & ~illegal_reg_16;              // chặn ghi RF
```

Ở chế độ CHERIoT, lệnh RV32I dùng x16–x31 → illegal instruction.

### 1.5 Ánh xạ opcode (tóm tắt)

| Opcode | RV32I | CHERIoT bật (`cheriot_enable_i == On` & `~illegal_c_insn_i`) |
|---|---|---|
| `JAL` (`0x6f`) | jump bằng ALU/BTALU | `CJAL`: adder A=imm21, B=PC, setaddr=`SETADDR_PCC_PCNXT` |
| `JALR` (`0x67`) | jump | `CJALR`: adder A=imm12, B=rs1, setaddr=`PCC_PCNXT`; funct3≠0 → illegal |
| `AUIPC` (`0x17`) | `rd = pc + imm20<<12` | `CAUIPCC`: adder A=imm20<<12, B=PC, setaddr=`PCC_ARITH` |
| `LOAD` (`0x03`) funct3=`011` | illegal | `CLOAD_CAP` (CLC), `cheriot_data_req_o=1`, `data_req_o=0` |
| `STORE` (`0x23`) funct3=`011` | illegal | `CSTORE_CAP` (CSC) |
| `LOAD`/`STORE` khác | bình thường (`data_req_o=1`) | bình thường, nhưng bound/perm check bởi CHERIoT EX |
| `OPCODE_CHERI` (`0x5b`) | illegal | 26 lệnh CHERIoT — §1.6 |
| `OPCODE_AUICGP` (`0x7b`) | illegal | `CAUICGP`: adder A=imm20<<12, B=rs1(=c3) |
| `SYSTEM` (`0x73`) | ECALL/EBREAK/MRET/DRET/WFI/CSR | giống, thêm `csr_cheriot_always_ok_o` |
| `MISC_MEM` (`0x0f`) | FENCE=nop, FENCE.I=jump+`icache_inval_o` | giống |

### 1.6 Bảng lệnh CHERIoT (`OPCODE_CHERI`)

`ibex_decoder.sv:791-885`

**funct3=`000`, funct7=`0x7f` (fmt3 — một nguồn):** phân biệt bằng `instr[24:20]`

| `instr[24:20]` | Lệnh | `cheriot_operator` | `cap_field_sel`/`setbounds_sel` |
|---|---|---|---|
| `0x00` | `CGetPerm` | `CGET_FIELD` | `CFIELD_PERM` |
| `0x01` | `CGetType` | `CGET_FIELD` | `CFIELD_TYPE` |
| `0x02` | `CGetBase` | `CGET_FIELD` | `CFIELD_BASE` |
| `0x03` | `CGetLen` | `CGET_FIELD` | `CFIELD_LEN` |
| `0x04` | `CGetTag` | `CGET_FIELD` | `CFIELD_TAG` |
| `0x08` | `CRepresentableLength` | `CRRL` | `SETBOUNDS_CRRL` |
| `0x09` | `CRepresentableAlignmentMask` | `CRAM` | `SETBOUNDS_CRAM` |
| `0x0a` | `CMove` | `CMOVE_CAP` | — |
| `0x0b` | `CClearTag` | `CCLEAR_TAG` | — |
| `0x0f` | `CGetAddr` | `CGET_FIELD` | `CFIELD_ADDR` |
| `0x17` | `CGetHigh` | `CGET_FIELD` | `CFIELD_HIGH` |
| `0x18` | `CGetTop` | `CGET_FIELD` | `CFIELD_TOP` |

**funct3=`000`, funct7=`0x01`:** `CSpecialRW` → `CCSR_RW`, `setaddr_sel = SETADDR_SCR`,
`cheriot_cs2_dec_o = instr[24:20]` (chọn SCR chứ không phải rs2).

**funct3=`000`, funct7 khác (fmt2 — hai nguồn):**

| funct7 | Lệnh | operator | sel phụ |
|---|---|---|---|
| `0x08` | `CSetBounds` | `CSET_BOUNDS` | `SETBOUNDS_RS2` |
| `0x09` | `CSetBoundsExact` | `CSET_BOUNDS_EX` | `SETBOUNDS_RS2_EX` |
| `0x0a` | `CSetBoundsRoundDown` | `CSET_BOUNDS_RNDN` | `SETBOUNDS_RNDN` |
| `0x0b` | `CSeal` | `CSEAL` | — |
| `0x0c` | `CUnseal` | `CUNSEAL` | — |
| `0x0d` | `CAndPerm` | `CAND_PERM` | — |
| `0x10` | `CSetAddr` | `CSET_ADDR` | adder A=rs2, setaddr=`RFA_ARITH` |
| `0x11` | `CIncAddr` | `CINC_ADDR` | adder A=rs2, B=rs1, setaddr=`RFA_ARITH` |
| `0x14` | `CSub` | `CSUB_CAP` | — |
| `0x16` | `CSetHigh` | `CSET_HIGH` | — |
| `0x20` | `CTestSubset` | `CIS_SUBSET` | — |
| `0x21` | `CIsEqual` | `CIS_EQUAL` | — |

**funct3=`001`:** `CIncAddrImm` — adder A=imm12, B=rs1, setaddr=`RFA_ARITH`.
**funct3=`010`:** `CSetBoundsImm` — `SETBOUNDS_IMM`.

### 1.7 Chặn lan truyền lệnh illegal

`ibex_decoder.sv:906-923`

```systemverilog
if (illegal_c_insn_i) illegal_insn = 1'b1;

if (illegal_insn) begin
  rf_we = 0; data_req_o = 0; data_we_o = 0;
  jump_in_dec_o = 0; jump_set_o = 0; branch_in_dec_o = 0; csr_access_o = 0;
end
```

Lưu ý `cheriot_data_req_o` **không** nằm trong danh sách này — nhưng nó được gán
`~illegal_c_insn_i` tại chỗ (`ibex_decoder.sv:405, :454`).

### 1.8 Kiểm tra toán hạng CSR

`ibex_decoder.sv:250-260`

```systemverilog
csr_op_o = csr_op;
if ((csr_op == CSR_OP_SET || csr_op == CSR_OP_CLEAR) && instr_rs1 == '0)
  csr_op_o = CSR_OP_READ;      // CSRRS/CSRRC với rs1=x0 → không được ghi CSR
```

Theo đặc tả RISC-V, `CSRRS/C rd, csr, x0` là đọc thuần tuý (không gây side-effect ghi).

### 1.9 CSR "always OK" cho CHERIoT

`ibex_decoder.sv:778-782`

```systemverilog
csr_cheriot_always_ok_o = CHERIoT & enabled &
                          ((instr[31:28] == 4'hc) &&
                           ((instr[27] == 1'b0) || (instr[26:25] == 2'b00)));
```

Cho phép truy cập `0xC00`–`0xC9F` (counter không đặc quyền, bảng 7.1 spec CHERIoT)
**không cần** quyền ASR trên PCC. Mọi CSR khác yêu cầu `pcc.perms.SR = 1`.

---

## 2. Controller FSM

`ibex/rtl/ibex_controller.sv`

### 2.1 Sơ đồ trạng thái

```
                    ┌───────┐
           reset ──►│ RESET │ instr_req_o=0, pc_mux=PC_BOOT, pc_set=1
                    └───┬───┘
                        ▼
                  ┌──────────┐
                  │ BOOT_SET │ instr_req_o=1, pc_mux=PC_BOOT, pc_set=1
                  └────┬─────┘
                       ▼
                ┌─────────────┐
      ┌────────►│ FIRST_FETCH │
      │         └──┬───┬───┬──┘
      │  id_in_ready│   │   │ enter_debug_mode → DBG_TAKEN_IF
      │            │   │ handle_irq → IRQ_TAKEN
      │            ▼
      │      ┌──────────┐  special_req & (ready_wb|wb_exception)
      │      │  DECODE  │──────────────────────────────► ┌───────┐
      │      │          │◄──────────────────────────────│ FLUSH │
      │      └──┬────┬──┘                                └───┬───┘
      │         │    │ enter_debug_mode → DBG_TAKEN_IF      │
      │         │    │ handle_irq       → IRQ_TAKEN         │ ebreak+debug
      │         │    └──────────────────────────────────►   ▼
      │         │                                     ┌──────────────┐
      │         │                                     │ DBG_TAKEN_ID │
      │         │                                     └──────┬───────┘
      │         │                                            ▼ DECODE
      │         │ wfi (qua FLUSH)
      │         ▼
      │  ┌────────────┐      ┌───────┐
      │  │ WAIT_SLEEP │─────►│ SLEEP │ ctrl_busy_o=0 → clock gate tắt
      │  └────────────┘      └───┬───┘
      └──────────────────────────┘ irq/debug → FIRST_FETCH
```

### 2.2 Chi tiết từng trạng thái

| Trạng thái | `instr_req_o` | `halt_if` | `flush_id` | `ctrl_busy_o` | `controller_run_o` | Hành động |
|---|---|---|---|---|---|---|
| `RESET` | 0 | 0 | 0 | 1 | 0 | `pc_set=1`, `pc_mux=PC_BOOT` → `BOOT_SET` |
| `BOOT_SET` | 1 | 0 | 0 | 1 | 0 | `pc_set=1` lần nữa → `FIRST_FETCH` |
| `WAIT_SLEEP` | 0 | 1 | 1 | **0** | 0 | → `SLEEP` |
| `SLEEP` | 0 | 1 | 1 | 0 (hoặc 1) | 0 | Thức khi irq/debug → `FIRST_FETCH` |
| `FIRST_FETCH` | 1 | — | 0 | 1 | 0 | `id_in_ready` → `DECODE` |
| `DECODE` | 1 | có điều kiện | 0 | 1 | **1** | Chạy lệnh bình thường |
| `IRQ_TAKEN` | 1 | 0 | 0 | 1 | 0 | `csr_save_if`, `csr_save_cause`, `pc_mux=PC_EXC` → `DECODE` |
| `DBG_TAKEN_IF` | 1 | 0 | **1** | 1 | 0 | `csr_save_if`, `debug_csr_save`, `pc→DmHaltAddr` → `DECODE` |
| `DBG_TAKEN_ID` | 1 | 0 | **1** | 1 | 0 | EBREAK vào debug: `csr_save_id` → `DECODE` |
| `FLUSH` | 1 | **1** | **1** | 1 | 0 | Xử lý exception / MRET / DRET / WFI → `DECODE` |

### 2.3 `special_req` — điều gì đưa FSM vào `FLUSH`

`ibex_controller.sv:285-295`

```systemverilog
special_req_flush_only = wfi_insn | csr_pipe_flush;
special_req_pc_change  = mret_insn | dret_insn | exc_req_d | exc_req_wb;
special_req            = special_req_pc_change | special_req_flush_only;
```

Trong `DECODE`:
```systemverilog
if (special_req) begin
  retain_id = 1'b1;                                  // giữ lệnh trong ID (không clear valid)
  if (ready_wb_i | wb_exception_o) ctrl_fsm_ns = FLUSH;
end
```

**Chờ `ready_wb_i`** là điểm quan trọng của pipeline 3 tầng: exception từ WB phải được
ưu tiên hơn exception từ ID/EX (thứ tự kiến trúc). Chỉ khi WB rỗng (hoặc chính WB đang
báo exception) mới chuyển sang FLUSH.

`csr_pipe_flush` (`ibex_id_stage.sv:593-598`):
```systemverilog
no_flush_csr_addr = csr_addr_o inside {CSR_MSCRATCH, CSR_MEPC};
csr_pipe_flush    = csr_op_en_o & (csr_op_o inside {WRITE,SET,CLEAR}) & !no_flush_csr_addr;
```
→ **hầu hết** lệnh ghi CSR đều flush pipeline (để lần fetch sau thấy PMP/CSR mới).
`mscratch` và `mepc` được miễn vì hay dùng trong exception handler.

### 2.4 Ưu tiên exception

`ibex_controller.sv:299-345` (nhánh `g_wb_exceptions`, WritebackStage=1):

```
1. store_err_q          (từ WB)
2. load_err_q           (từ WB)
3. cheriot_wb_err_q     (từ WB)
4. instr_fetch_err      (từ ID)
5. illegal_insn_q       (từ ID)
6. ecall_insn           (từ ID)
7. ebrk_insn            (từ ID)
8. cheriot_ex_err_q     (từ ID)
9. cheriot_asr_err_q    (từ ID)
```

Lỗi từ **WB luôn ưu tiên hơn** lỗi từ ID/EX vì lệnh trong WB đứng trước theo thứ tự chương trình.

Assertion `IbexExceptionPrioOnehot` kiểm tra đúng **một** tín hiệu `*_prio` được set khi
`(ctrl_fsm_cs == FLUSH) & csr_save_cause_o`.

(So sánh: khi `WritebackStage=0`, thứ tự đảo ngược — `instr_fetch_err` lên đầu,
`store/load_err` xuống sau `cheriot_ex_err`.)

### 2.5 Sinh `mcause` / `mtval` trong `FLUSH`

`ibex_controller.sv:816-945`. Bảng đầy đủ:

| Nguồn ưu tiên | `exc_cause_o` | `csr_mtval_o` | Ghi chú |
|---|---|---|---|
| `instr_fetch_err` + `cheriot_acc_vio` | `ExcCauseCheriFault` (28) | `{21'h0, 1'b1, 5'h0, 5'h2}` | S=1, cap_idx=0, cause=tag vio |
| `instr_fetch_err` + `cheriot_bound_vio` | `ExcCauseCheriFault` | `{21'h0, 1'b1, 5'h0, 5'h1}` | **+ `csr_mepcc_clrtag_o = 1`** |
| `instr_fetch_err` (bus/PMP) | `ExcCauseInstrAccessFault` (1) | `pc_id` hoặc `pc_id+2` | |
| `illegal_insn` | `ExcCauseIllegalInsn` (2) | CHERIoT: `0`; RV32: lệnh gốc | |
| `ecall` | `ExcCauseEcallMMode`(11) / `UMode`(8) | 0 | theo `priv_mode_i` |
| `ebreak` (không vào debug) | `ExcCauseBreakpoint` (3) | CHERIoT: `pc_id`; RV32: 0 | |
| `store_err` + CHERIoT + `wb_err_info[11]` | `ExcCauseStoreAddrMisaligned` (6) | `lsu_addr_last_i` | alignment CLC/CSC |
| `store_err` + CHERIoT | `ExcCauseCheriFault` | `{21'h0, wb_err_info[10:0]}` | |
| `store_err` (RV32) | `ExcCauseStoreAccessFault` (7) | `lsu_addr_last_i` | |
| `load_err` (tương tự store) | 4 / 5 / 28 | `lsu_addr_last_i` hoặc err_info | |
| `cheriot_ex_err` | `ExcCauseCheriFault` | `{21'h0, ex_err_info[10:0]}` | hiện luôn 0 |
| `cheriot_wb_err` + `wb_err_info[12]` | `ExcCauseIllegalInsn` | `{21'h0, info[10:0]}` | SCR addr sai |
| `cheriot_wb_err` | `ExcCauseCheriFault` | `{21'h0, info[10:0]}` | |
| `cheriot_asr_err` | `ExcCauseCheriFault` | `{21'b0, 1'b1, 5'h0, 5'h18}` | thiếu quyền SR |

Khi không có exception, nhánh `else`:
* `mret_insn` → `pc_mux=PC_ERET`, `csr_restore_mret_id_o=1`, thoát NMI mode nếu đang ở.
* `dret_insn` → `pc_mux=PC_DRET`, `debug_mode_d=0`, `csr_restore_dret_id_o=1`.
* `wfi_insn` → `WAIT_SLEEP`.

Cuối `FLUSH`: nếu `enter_debug_mode_prio_q` và không phải ebreak-vào-debug thì chuyển
`DBG_TAKEN_IF` thay vì `DECODE` — tức "đã set xong CSR như exception, nhưng nhảy vào
debug handler".

### 2.6 Lỗi ASR của CHERIoT

`ibex_controller.sv:236-250`

```systemverilog
mret_cheriot_asr_err = cheriot_on & ~csr_pcc_perm_sr_i & mret_insn;
csr_cheriot_asr_err  = cheriot_on & ~csr_pcc_perm_sr_i & instr_valid_i
                     & csr_access_i & ~illegal_insn_i & ~csr_cheriot_always_ok_i;
cheriot_asr_err_d    = (~illegal_insn_i & csr_cheriot_asr_err) | mret_cheriot_asr_err;
```

`csr_pcc_perm_sr_i` ← `pcc_cap_r.perms.SR` (`ibex_core.sv:760`).
Ở CHERIoT, quyền truy cập CSR **không** đến từ privilege mode mà từ permission bit trên PCC.

### 2.7 Internal NMI (lỗi ECC bộ nhớ)

`ibex_controller.sv:393-452` — khối `g_intg_irq_int` **[BẬT]** vì `MemECC=1`.

```systemverilog
// Khi mem_resp_intg_err_i (lỗi ECC trên D-side) → set IRQ nội bộ + chốt địa chỉ
if (mem_resp_intg_err_irq_pending_q) begin
  if (entering_nmi & !irq_nm_ext_i) mem_resp_intg_err_irq_clear = 1'b1;
end else if (mem_resp_intg_err_i) begin
  mem_resp_intg_err_addr_d  = lsu_addr_last_i;
  mem_resp_intg_err_irq_set = 1'b1;
end

irq_nm_int       = mem_resp_intg_err_irq_pending_q;
irq_nm_int_cause = NMI_INT_CAUSE_ECC;       // = 5'b0
irq_nm_int_mtval = mem_resp_intg_err_addr_q;

irq_nm = irq_nm_ext_i | irq_nm_int;
```

Ở `IRQ_TAKEN`:
```systemverilog
if (irq_nm && !nmi_mode_q) begin
  exc_cause_o = irq_nm_ext_i ? ExcCauseIrqNm                                 // {1,0,5'd31}
                             : '{irq_ext:0, irq_int:1, lower_cause: NMI_INT_CAUSE_ECC};
  if (irq_nm_int & !irq_nm_ext_i) csr_mtval_o = irq_nm_int_mtval;            // địa chỉ lỗi
  nmi_mode_d = 1'b1;
end
```

NMI ngoài **ưu tiên hơn** NMI nội bộ. IRQ nội bộ chỉ được xoá khi thực sự vào NMI handler.

### 2.8 Ưu tiên interrupt

`ibex_controller.sv:733-750` (trong `IRQ_TAKEN`):

```
1. NMI (ngoài hoặc trong)   → lower_cause = 31 (ngoài) hoặc 0 (ECC nội bộ), irq_int=1
2. irq_fast[14:0]           → lower_cause = {1'b1, mfip_id}  (16..30)
3. irq_external             → lower_cause = 11
4. irq_software             → lower_cause = 3
5. irq_timer                → lower_cause = 7
```

`mfip_id` được tính bằng vòng lặp **ngược** (`for i = 14 downto 0`) nên ID thấp nhất thắng
(`ibex_controller.sv:503-512`).

### 2.9 Điều kiện `handle_irq`

`ibex_controller.sv:493-501`

```systemverilog
irq_enabled = csr_mstatus_mie_i | (priv_mode_i == PRIV_LVL_U);
handle_irq  = ~debug_mode_q & ~debug_single_step_i & ~nmi_mode_q &
              (irq_nm | (irq_pending_i & irq_enabled)) &
              !(instr_gets_expanded_i == INSTR_EXPANDED_COMMIT);
```

Interrupt bị chặn khi: đang ở debug mode, đang single-step, đang ở NMI handler
(không lồng NMI), hoặc đang ở giữa chuỗi Zcmp cần commit nguyên tử.

Assertion `PipeEmptyOnIrq`: khi vào `IRQ_TAKEN`, pipeline phải rỗng
(`~instr_valid_i & ready_wb_i`).

### 2.10 Điều kiện vào debug mode

`ibex_controller.sv:462-482`

```systemverilog
do_single_step_d       = instr_valid_i ? ~debug_mode_q & debug_single_step_i : do_single_step_q;
enter_debug_mode_prio_d = (debug_req_i | do_single_step_d) & ~debug_mode_q &
                          !(gets_expanded inside {EXPANDED, EXPANDED_COMMIT});
enter_debug_mode        = enter_debug_mode_prio_d |
                          (trigger_match_i & ~debug_mode_q) & !(gets_expanded inside {...});
```

`trigger_match_i` **không** thuộc nhóm "prio" — vì nếu luồng điều khiển đổi (branch),
lệnh gây trigger không còn được thực thi nữa nên phải bỏ qua.

Ưu tiên `debug_cause` (`ibex_controller.sv:519-525`):
```
trigger_match > ebreak(vào debug) > debug_req > single_step > NONE
```
Nhưng ở `FLUSH`, EBREAK có ưu tiên **cao nhất** (comment `ibex_controller.sv:977-983`):
`cause==EBREAK (3) > debug_req (2) > step (1)`.

### 2.11 Điều khiển stall

`ibex_controller.sv:1012-1027`

```systemverilog
stall               = stall_id_i | stall_wb_i;
id_in_ready_o       = ~stall & ~halt_if & ~retain_id;
instr_valid_clear_o = ~(stall | retain_id) | flush_id;
```

* `retain_id` (chỉ set trong `DECODE` khi `special_req`) là "stall kiểu khác":
  giữ `instr_valid_id` nhưng **không** được đưa vào `stall` để tránh vòng tổ hợp
  (`special_req` phụ thuộc `illegal_csr_insn_i` phụ thuộc `csr_op_en_o` phụ thuộc
  `instr_id_done` phụ thuộc `stall`).
* `if (~instr_exec_i) halt_if = 1'b1;` ở cuối `always_comb`
  (`ibex_controller.sv:993-996`) — `fetch_enable_i` tắt → ngừng nhận lệnh mới.

---

## 3. Mux toán hạng

`ibex_id_stage.sv:346-440`

### 3.1 Mux tính địa chỉ lệch hàng

```systemverilog
alu_op_a_mux_sel = lsu_addr_incr_req_i ? OP_A_FWD        : alu_op_a_mux_sel_dec;
alu_op_b_mux_sel = lsu_addr_incr_req_i ? OP_B_IMM        : alu_op_b_mux_sel_dec;
imm_b_mux_sel    = lsu_addr_incr_req_i ? IMM_B_INCR_ADDR : imm_b_mux_sel_dec;
```

Khi LSU cần truy cập word thứ hai của một load/store lệch hàng, ALU bị "chiếm dụng"
để tính `addr_last + 4` (`OP_A_FWD` = `lsu_addr_last_i`, `IMM_B_INCR_ADDR` = `32'h4`).

### 3.2 Operand A

```systemverilog
imm_a = (imm_a_mux_sel == IMM_A_Z) ? zimm_rs1_type : '0;

unique case (alu_op_a_mux_sel)
  OP_A_REG_A:  alu_operand_a = rf_rdata_a_fwd;    // đã forward từ WB
  OP_A_FWD:    alu_operand_a = lsu_addr_last_i;
  OP_A_CURRPC: alu_operand_a = pc_id_i;
  OP_A_IMM:    alu_operand_a = imm_a;             // zimm cho CSRRWI/CSRRSI/CSRRCI
endcase
```

`csr_wdata = alu_operand_a_ex` (`ibex_core.sv:1432`) — dữ liệu ghi CSR đi qua chính đường
operand A.

### 3.3 Operand B và Branch-Target ALU

Vì `BranchTargetALU = 1` → nhánh `g_btalu_muxes` (`ibex_id_stage.sv:369-408`):

```systemverilog
// BT-ALU operand A: chỉ 2 lựa chọn
bt_a_operand_o = (bt_a_mux_sel == OP_A_REG_A) ? rf_rdata_a_fwd : pc_id_i;

// BT-ALU operand B: 4 lựa chọn
unique case (bt_b_mux_sel)
  IMM_B_I:       bt_b_operand_o = imm_i_type;    // JALR
  IMM_B_B:       bt_b_operand_o = imm_b_type;    // branch
  IMM_B_J:       bt_b_operand_o = imm_j_type;    // JAL
  IMM_B_INCR_PC: bt_b_operand_o = compressed ? 2 : 4;   // FENCE.I
endcase

// ALU chính: imm_b RÚT GỌN (không còn IMM_B_B / IMM_B_J)
unique case (imm_b_mux_sel)
  IMM_B_I, IMM_B_S, IMM_B_U, IMM_B_INCR_PC, IMM_B_INCR_ADDR
endcase
```

Nhờ tách BT-ALU, mux `imm_b` của ALU chính **nhỏ đi 2 lối vào** → đường tới hạn ngắn hơn.

```systemverilog
alu_operand_b = (alu_op_b_mux_sel == OP_B_IMM) ? imm_b : rf_rdata_b_fwd;
```

### 3.4 Thanh ghi trung gian multi-cycle

`ibex_id_stage.sv:444-458`

```systemverilog
for (i = 0; i < 2; i++)
  always_ff: if (imd_val_we_ex_i[i]) imd_val_q[i] <= imd_val_d_ex_i[i];   // 34-bit mỗi cái
```

Dùng chung giữa ALU (bitmanip multicycle, chỉ dùng 32 bit thấp) và MULDIV
(mac_res 34-bit / remainder+denominator). Reset về 0 (không điều kiện `ResetAll` — luôn có reset).

---

## 4. Hazard & Forwarding (WritebackStage = 1)

`ibex_id_stage.sv:1000-1125` — nhánh `gen_stall_mem`.

### 4.1 So khớp địa chỉ

```systemverilog
rf_rd_a_wb_match = (rf_waddr_wb_i == rf_raddr_a_o) & |rf_raddr_a_o;   // bỏ qua x0
rf_rd_b_wb_match = (rf_waddr_wb_i == rf_raddr_b_o) & |rf_raddr_b_o;
rf_rd_a_hz       = rf_rd_a_wb_match & rf_ren_a;
rf_rd_b_hz       = rf_rd_b_wb_match & rf_ren_b;
```

### 4.2 Forwarding

```systemverilog
rf_rdata_a_fwd = rf_rd_a_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_a_i;
rf_rdata_b_fwd = rf_rd_b_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_b_i;
```

`rf_wdata_fwd_wb_i` là **`rf_wdata_wb_q`** (kết quả ALU/CHERIoT đã flop trong WB), **không**
phải `rf_wdata_wb_o` — vì dữ liệu load (`rf_wdata_lsu`) về quá muộn cho đường forward.

### 4.3 Stall load-use

```systemverilog
stall_ld_hz = outstanding_load_wb_i & (rf_rd_a_hz | rf_rd_b_hz);
```

Khi WB đang chờ dữ liệu load và lệnh trong ID đọc đúng thanh ghi đích → **stall**.
Đây là hazard duy nhất phải stall; mọi hazard khác được forward.

> Forwarding riêng cho capability được thực hiện **trong `ibex_cheriot_ex`**
> (`ibex_cheriot_ex.sv:209-226`, khối `fwd_data_merger`) vì nó cần cả
> `rf_wdata_fwd_wb` lẫn `rf_wcap_fwd_wb`.

### 4.4 `instr_executing` vs `instr_executing_spec`

```systemverilog
outstanding_memory_access = (outstanding_load_wb_i | outstanding_store_wb_i) & ~lsu_resp_valid_i;
data_req_allowed          = ~outstanding_memory_access;

instr_kill = instr_fetch_err_i | wb_exception | id_exception_nc | ~controller_run;

instr_executing_spec = instr_valid_i & ~instr_fetch_err_i & controller_run & ~stall_ld_hz;

instr_executing      = instr_valid_i & ~instr_kill & ~stall_ld_hz & ~outstanding_memory_access;
```

**Tại sao cần bản "spec"?**
`branch_set_raw_d` / `jump_set_raw` được sinh từ `instr_executing_spec`. Nếu dùng
`instr_executing` đầy đủ thì `data_err_i` (lỗi bus D-side) sẽ đi vào `wb_exception` →
`instr_executing` → `pc_set_o` → `instr_req_o`/`instr_addr_o`, tạo **đường feedthrough
từ data_err_i sang instr_req_o** — điều mà nhiều interconnect không chấp nhận (dễ gây
vòng tổ hợp).

Giải pháp: nhánh được phát **suy đoán**; nếu sau đó WB báo exception, pipeline bị flush
và PC được đặt lại → fetch suy đoán bị bỏ.

`id_exception_nc` = exception từ ID **không tính** CHERIoT EX error
(`ibex_controller.sv:278-280`) — để tránh vòng tổ hợp
`instr_executing → cheriot_lsu_err → cheriot_ex_err → instr_executing`.

### 4.5 `cheriot_exec_id_o`

```systemverilog
cheriot_exec_id_o = (cheriot_enable_i == IbexMuBiOn) & instr_valid_i &
                    ~instr_fetch_err_i & instr_is_legal_cheriot & controller_run &
                    ~wb_exception & ~stall_ld_hz & ~outstanding_memory_access;
```

Giống `instr_executing` nhưng dùng `~wb_exception` trực tiếp thay vì `instr_kill`
(vì `instr_kill` chứa `id_exception_nc` → vòng tổ hợp).

### 4.6 Chặn phát lại request

```systemverilog
stall_mem = instr_valid_i & (outstanding_memory_access |
                             ((lsu_req_dec | cheriot_lsu_req_dec) & ~lsu_req_done_i));
```

Assertion `IbexStallMemNoRequest`: `instr_valid & lsu_req_dec & ~instr_done |-> ~lsu_req_done_i`
— nếu lệnh load bị stall vì lý do khác thì LSU không được báo hoàn thành request.

---

## 5. FSM ID-EX (2 trạng thái)

`ibex_id_stage.sv:861-990`

```systemverilog
typedef enum logic { FIRST_CYCLE, MULTI_CYCLE } id_fsm_e;
always_ff: if (instr_executing) id_fsm_q <= id_fsm_d;
```

### 5.1 Bảng chuyển trạng thái từ `FIRST_CYCLE`

`unique case (1'b1)` với **thứ tự ưu tiên** (assertion `IbexMulticycleEnableUnique`
đảm bảo `$onehot0({lsu_req_dec, multdiv_en_dec, branch_in_dec, jump_in_dec})`):

| Điều kiện | Hành động (cấu hình opentitan) |
|---|---|
| `lsu_req_dec` (load/store RV32) | `~lsu_req_done_i` → `MULTI_CYCLE` |
| `cheriot_lsu_req_dec` (CLC/CSC) | như trên (nếu CHERIoT bật) |
| `multdiv_en_dec` | `~ex_valid_i` → `MULTI_CYCLE`, `rf_we_raw=0`, `stall_multdiv=1`. **MUL 1 chu kỳ ⇒ `ex_valid` ngay ⇒ ở lại `FIRST_CYCLE`** |
| `branch_in_dec` | `id_fsm_d = (data_ind_timing_i \|\| (!BTALU && branch_decision)) ? MULTI_CYCLE : FIRST_CYCLE`; với BTALU=1 và DIT=0 → **`FIRST_CYCLE`**; `branch_set_raw_d = branch_decision \| data_ind_timing`; `stall_branch = data_ind_timing_i` |
| `jump_in_dec` | `id_fsm_d = BTALU ? FIRST_CYCLE : MULTI_CYCLE` → **`FIRST_CYCLE`**; `stall_jump = ~BTALU = 0` |
| `alu_multicycle_dec` | `stall_alu=1`, `MULTI_CYCLE`, `rf_we_raw=0` (bitmanip ternary/rotate/crc) |

Ở trạng thái `MULTI_CYCLE`:

```systemverilog
if (multdiv_en_dec) rf_we_raw = rf_we_dec & ex_valid_i;      // chỉ ghi khi có kết quả
if (multicycle_done & ready_wb_i) id_fsm_d = FIRST_CYCLE;
else { stall_multdiv = multdiv_en_dec; stall_branch = branch_in_dec; stall_jump = jump_in_dec; }
```

```systemverilog
multicycle_done = (lsu_req_dec | cheriot_lsu_req_dec) ? ~stall_mem : ex_valid_all;
ex_valid_all    = instr_is_cheriot_id_o ? cheriot_ex_valid_i : ex_valid_i;
```

### 5.2 Tổng hợp stall

```systemverilog
stall_id  = stall_ld_hz | stall_mem | stall_multdiv | stall_jump | stall_branch | stall_alu;
stall_wb  = en_wb_o & ~ready_wb_i;
instr_done = ~stall_id & ~flush_id & instr_executing;
en_wb_o    = instr_done;
instr_id_done_o = en_wb_o & ready_wb_i;
instr_first_cycle = instr_valid_i & (id_fsm_q == FIRST_CYCLE);
```

Assertion `IllegalInsnStallMustBeMemStall`: lệnh illegal chỉ được stall vì `stall_mem`
(để exception bộ nhớ có ưu tiên cao hơn illegal instruction).

### 5.3 Điều khiển branch/jump 2 pha

`ibex_id_stage.sv:767-852`

Vì `BranchTargetALU = 1` **và** `DataIndTiming = 1` → nhánh **`g_branch_set_flop`**
(không phải `g_branch_set_direct`):

```systemverilog
always_ff: branch_set_raw_q <= branch_set_raw_d;      // KHÔNG qualify bằng instr_executing (*)
branch_set_raw = (BranchTargetALU && !data_ind_timing_i) ? branch_set_raw_d : branch_set_raw_q;
```

→ **Runtime** quyết định: khi `cpuctrl.data_ind_timing = 0` thì dùng đường tổ hợp
(1 chu kỳ); khi = 1 thì dùng đường flop (branch **luôn** 2 chu kỳ, bất kể taken/not-taken).

(*) Comment trong mã ghi nhận đây là bug đã biết: "should qualify this with instr_executing
(same as id_fsm_q). let's wait for now and fix later QQQ" (`ibex_id_stage.sv:780-782`).

Lọc xung kép:
```systemverilog
branch_jump_set_done_d = (branch_set_raw | jump_set_raw | branch_jump_set_done_q)
                       & ~instr_valid_clear_o;
jump_set   = jump_set_raw   & ~branch_jump_set_done_q;
branch_set = branch_set_raw & ~branch_jump_set_done_q;
```
Cần thiết vì `*_raw` có thể giữ cao nhiều chu kỳ (khi `instr_executing_spec=1` nhưng
`instr_executing=0` do đang chờ phản hồi bộ nhớ). Chỉ chu kỳ đầu được gửi tới controller,
tránh flush IF nhiều lần.

Assertion `NeverDoubleBranch` / `NeverDoubleJump`.

`branch_taken` (dùng bởi decoder cho `data_ind_timing`):
```systemverilog
always_ff: branch_taken_q <= branch_decision_i;
branch_taken = ~data_ind_timing_i | branch_taken_q;
```

---

## 6. Ghi register file từ ID

```systemverilog
rf_we_id_o = rf_we_raw & instr_executing & ~illegal_csr_insn_i;

unique case (rf_wdata_sel)
  RF_WD_EX:  rf_wdata_id_o = result_ex_i;
  RF_WD_CSR: rf_wdata_id_o = csr_rdata_i;
endcase
```

`csr_op_en_o` (`ibex_id_stage.sv:747-750`) có tối ưu riêng cho CHERIoT:

```systemverilog
csr_op_en_o = csr_access_o & instr_executing &
              (CHERIoT_enabled ? instr_first_cycle : instr_id_done_o);
```

Comment giải thích: `instr_id_done` có quá nhiều logic phía trước, gây khó timing ở chế
độ CHERIoT; dùng `instr_first_cycle` thay thế.

---

## 7. Đếm `minstret`

`ibex_id_stage.sv:1213-1222`

```systemverilog
minstret_write = csr_access_o & (csr_op inside {WRITE,SET,CLEAR}) &
                 (csr_addr_o inside {CSR_MINSTRET, CSR_MINSTRETH});

instr_perf_count_id_o = ~ebrk_insn & ~ecall_insn_dec & ~illegal_insn_dec &
                        ~illegal_csr_insn_i & ~instr_fetch_err_i & ~minstret_write &
                        !(instr_gets_expanded_i inside {INSTR_EXPANDED, INSTR_EXPANDED_COMMIT});
```

Không đếm: trap, ecall/ebreak, lệnh illegal, chính lệnh ghi `minstret`, và micro-op
Zcmp không phải cuối (chuỗi `cm.push` đếm **1** lệnh, không phải 5).

---

## 8. Assertion cách ly CHERIoT

`ibex_id_stage.sv:1295-1300`:

```systemverilog
`ASSERT_IF(IbexCheriotLoadDisabled,  !cheriot_load_o,        cheriot_enable_i != IbexMuBiOn)
`ASSERT_IF(IbexCheriotStoreDisabled, !cheriot_store_o,       cheriot_enable_i != IbexMuBiOn)
`ASSERT_IF(IbexInstrNotCheriot,      !instr_is_cheriot_id_o, cheriot_enable_i != IbexMuBiOn)
`ASSERT_IF(IbexCheriotExecDisabled,  !cheriot_exec_id_o,     cheriot_enable_i != IbexMuBiOn)
```

Đảm bảo khi CHERIoT tắt, datapath CHERIoT hoàn toàn im lặng — điều kiện tiên quyết để
tương đương logic (LEC) với Ibex RV32I gốc.
