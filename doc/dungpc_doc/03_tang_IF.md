# 03 — Tầng IF (Instruction Fetch)

Tệp: `ibex/rtl/ibex_if_stage.sv` (940 dòng).

Tầng IF là tầng pipeline **thứ nhất**. Nhiệm vụ: chọn PC kế tiếp, lấy lệnh (qua I$),
giải nén lệnh compressed, chèn dummy instruction, kiểm tra PCC (CHERIoT) + PMP,
rồi đẩy vào thanh ghi IF/ID.

---

## 1. Sơ đồ khối tầng IF

```
 boot_addr_i ─┐
 branch_target_ex_i ─┐
 csr_mepc_i ─┐│      │
 csr_depc_i ─┤│      │     ┌───────────────┐
 exc_pc ─────┤└──────┴────►│ fetch_addr_mux│──► fetch_addr_n
 (mtvec/DM)  │             │  (pc_mux_i)   │
             │             └───────────────┘
             │                     │ branch_req = pc_set_i | predict_branch_taken(=0)
             │                     ▼
             │            prefetch_addr = {fetch_addr_n[31:1], 1'b0}
             │                     │
 instr_* ◄───┼─────────────┌───────▼────────┐
 ic_tag/data ◄─────────────│   ibex_icache  │  [ICache=1]
             │             └───────┬────────┘
             │        fetch_valid_raw, fetch_rdata, fetch_addr, fetch_err, fetch_err_plus2
             │                     │
             │        (BranchPredictor=0 → nối thẳng)
             │        if_instr_valid / if_instr_rdata / if_instr_addr / if_instr_bus_err
             │                     │
             │        ┌────────────┴────────────┐
             │        │                         │
             │        ▼                         ▼
             │  ┌──────────────┐        ┌─────────────────┐
             │  │ CHERIoT PCC  │        │ ibex_compressed │
             │  │ bound/perm   │        │    _decoder     │
             │  │   check      │        │  (+FSM Zcmp)    │
             │  └──────┬───────┘        └────────┬────────┘
             │  cheriot_acc_vio                  │ instr_decompressed
             │  cheriot_bound_vio                │ instr_is_compressed
             │  cheriot_force_uc ──► I$/FIFO     │ instr_gets_expanded
             │                                   │ illegal_c_insn
             │                          ┌────────▼────────┐
 pmp_err_if_i ────────────────────────► │  mux dummy      │◄── ibex_dummy_instr
 pmp_err_if_plus2_i                     │  instruction    │
                                        └────────┬────────┘
                                                 │
                                      ┌──────────▼──────────┐
                                      │  IF/ID pipe regs    │ (if_id_pipe_reg_we)
                                      └──────────┬──────────┘
                                                 ▼ tới ID stage
```

---

## 2. Khối chọn PC

### 2.1 `exc_pc_mux` — địa chỉ trap

`ibex_if_stage.sv:212-232`

```systemverilog
irq_vec = exc_cause.lower_cause;
if (exc_cause.irq_int) irq_vec = ExcCauseIrqNm.lower_cause;   // = 5'd31, NMI nội bộ

unique case (exc_pc_mux_i)
  EXC_PC_EXC:     exc_pc = CHERIoT ? {csr_mtvec_i[31:2], 2'b00}
                                   : {csr_mtvec_i[31:8], 8'h00};
  EXC_PC_IRQ:     exc_pc = CHERIoT ? {csr_mtvec_i[31:2], 2'b00}
                                   : {csr_mtvec_i[31:8], 1'b0, irq_vec, 2'b00};
  EXC_PC_DBD:     exc_pc = DmHaltAddr;       // 32'h1A110800
  EXC_PC_DBG_EXC: exc_pc = DmExceptionAddr;  // 32'h1A110808
endcase
```

**Khác biệt cốt lõi giữa hai chế độ:**

| | RV32I | CHERIoT |
|---|---|---|
| Exception | `mtvec & ~0xFF` (base 256-byte) | `mtvec & ~0x3` (direct) |
| Interrupt | `base + irq_vec*4` (**vectored**) | `mtvec & ~0x3` (**direct**, không vector) |

Ở CHERIoT mọi trap đều vào cùng một handler; phân biệt qua `mcause`.

### 2.2 `fetch_addr_mux` — PC kế tiếp

`ibex_if_stage.sv:240-254`

| `pc_mux_i` | Nguồn | Khi nào |
|---|---|---|
| `PC_BOOT` | `{boot_addr_i[31:8], 8'h80}` | FSM controller trong `RESET`/`BOOT_SET` |
| `PC_JUMP` | `branch_target_ex_i` | branch taken / jump / CJALR / FENCE.I |
| `PC_EXC` | `exc_pc` | trap / debug entry |
| `PC_ERET` | `csr_mepc_i` | MRET |
| `PC_DRET` | `csr_depc_i` | DRET |
| `PC_BP` | `predict_branch_pc` | **không dùng** (BranchPredictor=0) |

Assertion `IbexBootAddrUnaligned` yêu cầu `boot_addr_i[7:0] == 0`; PC reset =
`boot_addr + 0x80`.

`csr_mtvec_init_o = (pc_mux_i == PC_BOOT) & pc_set_i` → báo CSR khởi tạo `mtvec` từ boot addr.

### 2.3 Yêu cầu chuyển hướng gửi xuống I$

`ibex_if_stage.sv:286-294`

```systemverilog
branch_req      = pc_set_i | predict_branch_taken;      // predict_* = 0
prefetch_branch = branch_req | nt_branch_mispredict_i;  // nt_* = 0
prefetch_addr   = branch_req ? {fetch_addr_n[31:1], 1'b0} : nt_branch_addr_i;
fetch_valid     = fetch_valid_raw & ~nt_branch_mispredict_i;
```

Với `BranchPredictor=0`, rút gọn thành `prefetch_branch = pc_set_i`,
`prefetch_addr = {fetch_addr_n[31:1], 1'b0}` (ép align nửa-từ).

---

## 3. Kiểm tra bus / ECC I-side

`ibex_if_stage.sv:258-284`

```systemverilog
// MemECC = 1
prim_buf #(.Width(39)) u_prim_buf_instr_rdata (.in_i(instr_rdata_i), .out_o(instr_rdata_buf));
prim_secded_inv_39_32_dec u_instr_intg_dec (.data_i(instr_rdata_buf), .err_o(ecc_err));
assign instr_intg_err  = |ecc_err;             // không phân biệt sửa được / không

assign instr_err        = instr_intg_err | instr_bus_err_i;   // → vào I$ như "err"
assign instr_intg_err_o = instr_intg_err & instr_rvalid_i;    // → alert_major_bus_o
```

Điểm quan trọng: lỗi ECC **không được sửa**, chỉ báo alert và được coi như bus error
(dẫn tới `ExcCauseInstrAccessFault`). `prim_buf` chặn tổng hợp tối ưu bộ giải mã.

---

## 4. Kiểm tra PCC (CHERIoT) tại IF

`ibex_if_stage.sv:437-471`. Đây là phần **đặc thù CHERIoT-Ibex**, không có ở Ibex upstream.

### 4.1 Tính headroom

```systemverilog
allow_all  = (pcc_cap_i.base32 == 0) & (pcc_cap_i.top33 == 33'h1_0000_0000);
instr_hdrm = {1'b0, pcc_cap_i.top33} - {2'b00, if_instr_addr};   // 34-bit
hdrm_ge4   = (|instr_hdrm[32:2]) & ~instr_hdrm[33];   // top - pc >= 4
hdrm_ge2   = (|instr_hdrm[32:1]) & ~instr_hdrm[33];   // top - pc >= 2
hdrm_ok    = allow_all || (instr_is_compressed ? hdrm_ge2 : hdrm_ge4);
base_ok    = ~(if_instr_addr < pcc_cap_i.base32);
```

`allow_all` xử lý trường hợp đặc biệt PCC phủ toàn bộ không gian 32-bit và PC quấn vòng
(PC = `0xFFFF_FFFE` với lệnh 32-bit): nếu không có ngoại lệ này thì fetch sẽ bị lỗi vì
headroom < 4.

### 4.2 Ba tín hiệu vi phạm

```systemverilog
cheriot_bound_vio = CHERIoT & enabled & ~debug_mode_i & (~base_ok || ~hdrm_ok);

cheriot_force_uc  = CHERIoT & enabled & ~allow_all & (~base_ok | ~hdrm_ge4);

cheriot_acc_vio   = CHERIoT & enabled & ~debug_mode_i &
                    (~pcc_cap_i.perms.EX || ~pcc_cap_i.valid || (pcc_cap_i.otype != 0));
```

* `cheriot_bound_vio` → nạp vào `instr_fetch_cheriot_bound_vio_o`, sinh
  `ExcCauseCheriFault` với `mtval = {S=1, cap_idx=0, cause=0x1}` và **xoá tag MEPCC**
  (`csr_mepcc_clrtag_o`).
* `cheriot_acc_vio` → `ExcCauseCheriFault` với `cause = 0x2` (tag violation).
* `cheriot_force_uc` — **cơ chế chống side-channel**: nếu chỉ được phép fetch 2 byte,
  ép fetch FIFO coi dữ liệu hiện tại là lệnh compressed lệch hàng và đẩy ngay sang ID
  mà **không chờ** nửa sau. Nhờ vậy thời gian fetch không phụ thuộc dữ liệu.
  Được nối tới `ibex_prefetch_buffer.cheriot_force_uc_i`; khi `ICache=1` tín hiệu này
  bị `unused_cheriot_force_uc` (`ibex_if_stage.sv:205`) — tức I$ không dùng cơ chế này.

**Trong debug mode tất cả kiểm tra CHERIoT bị vô hiệu** (`~debug_mode_i`), để debugger
có thể truy cập mọi địa chỉ.

### 4.3 Gộp lỗi fetch

`ibex_if_stage.sv:424-434`

```systemverilog
if_instr_pmp_err  = pmp_err_if_i | (if_instr_addr[1] & ~instr_is_compressed & pmp_err_if_plus2_i);
if_instr_err      = if_instr_bus_err | if_instr_pmp_err | cheriot_acc_vio | cheriot_bound_vio;
if_instr_err_plus2 = ((if_instr_addr[1] & ~instr_is_compressed & pmp_err_if_plus2_i)
                      | fetch_err_plus2) & ~pmp_err_if_i;
```

Kênh PMP thứ hai (`PMP_I2`, địa chỉ `pc_if + 2`) chỉ có tác dụng cho lệnh **32-bit
lệch hàng nửa-từ** — khi đó lệnh trải qua hai word có thể thuộc hai vùng PMP khác nhau.

---

## 5. Compressed decoder

`ibex/rtl/ibex_compressed_decoder.sv` (939 dòng), instantiate tại `ibex_if_stage.sv:485-499`.

```systemverilog
ibex_compressed_decoder #(.RV32ZC(RV32ZcaZcbZcmp), .ResetAll(1), .BaseIsa(...))
  compressed_decoder_i (
    .valid_i        (fetch_valid & ~fetch_err),
    .id_in_ready_i  (id_in_ready_i & ~pc_set_i),
    .instr_i        (if_instr_rdata),
    .cheriot_enable_i,
    .instr_o        (instr_decompressed),
    .is_compressed_o(instr_is_compressed),
    .gets_expanded_o(instr_gets_expanded),
    .flush_expanded_i(flush_expanded),     // = pc_set_i & (pc_mux_i == PC_EXC)
    .illegal_instr_o(illegal_c_insn));
```

### 5.1 Phần Zca/Zcb (tổ hợp thuần)

Chuyển lệnh 16-bit → 32-bit tương đương. Ví dụ tiêu biểu:

| C-instr | Bung thành |
|---|---|
| `c.addi4spn` | `addi rd', x2, nzuimm` — **hoặc** `CIncAddrImm` (opcode `OPCODE_CHERI`) khi CHERIoT bật (`ibex_compressed_decoder.sv:229-240`) |
| `c.addi16sp` | `addi x2, x2, imm` / `CIncAddrImm` ở CHERIoT (`:385-402`) |
| `c.lw` | `lw rd', off(rs1')` |
| `c.ld`/`c.clc` (funct3=011, C0) | `lw`/`CLC` (`OPCODE_LOAD` funct3=`011`) |
| `c.sw` | `sw` |
| `c.lbu/c.lhu/c.lh/c.sb/c.sh` (Zcb) | load/store byte/half |
| `c.zext.b/c.sext.b/c.zext.h/c.sext.h/c.not/c.mul` (Zcb) | `andi`/`sext.b`/... |

Điểm đáng chú ý: ở chế độ CHERIoT, các phép **cộng vào stack pointer** được chuyển thành
lệnh CHERIoT `CIncAddrImm` thay vì `addi` — vì `x2` là một *capability*, cộng vào địa chỉ
phải giữ nguyên metadata và phải kiểm tra khả năng biểu diễn (representability).

### 5.2 FSM Zcmp

`ibex_compressed_decoder.sv:178-193` khai báo FSM 3-bit gộp 3 máy trạng thái độc lập
dùng chung trạng thái `CmIdle`:

```
CmIdle ──┬──► CmPushStoreReg ──► CmPushDecrSp ──► CmIdle       (cm.push)
         ├──► CmPopLoadReg  ──► CmPopIncrSp ──┬──► CmIdle      (cm.pop)
         │                                    ├──► CmPopZeroA0 ──► CmPopRetRa ──► CmIdle (cm.popretz)
         │                                    └──► CmPopRetRa  ──► CmIdle      (cm.popret)
         └──► CmMvSecondReg ──► CmIdle                          (cm.mvsa01 / cm.mva01s)
```

Thanh ghi trạng thái: `cm_state_q` (3-bit), `cm_rlist_q` (5-bit), `cm_sp_offset_q` (5-bit).

Ví dụ `cm.push {ra, s0-s2}, -32`:

| Chu kỳ | Micro-op sinh ra | `gets_expanded` |
|---|---|---|
| 0 | `sw s2, -4(sp)` | `INSTR_EXPANDED` |
| 1 | `sw s1, -8(sp)` | `INSTR_EXPANDED` |
| 2 | `sw s0, -12(sp)` | `INSTR_EXPANDED` |
| 3 | `sw ra, -16(sp)` | `INSTR_EXPANDED` |
| 4 | `addi sp, sp, -32` | `INSTR_EXPANDED_LAST` |

Các hàm sinh lệnh (`ibex_compressed_decoder.sv:44-176`):
`cm_push_store_reg()`, `cm_pop_load_reg()`, `cm_sp_addi()`, `cm_mv_reg()`,
`cm_zero_a0()`, `cm_ret_ra()`, `cm_mvsa01()`, `cm_mva01s()`, `cm_rlist_top_reg()`,
`cm_stack_adj()`.

`cm_rlist_init()` xử lý đặc biệt: `rlist == 15` nghĩa là phải lưu cả x26+x27, nên
được khởi tạo nội bộ thành 16.

### 5.3 Ngữ nghĩa 4 trạng thái `instr_exp_e`

`ibex_pkg.sv:318-325`:

| Giá trị | Ý nghĩa | Tác động |
|---|---|---|
| `INSTR_NOT_EXPANDED` | Lệnh thường | — |
| `INSTR_EXPANDED` | Đang giữa chuỗi micro-op | IF **không** pop lệnh mới (`fetch_ready = 0`); không tính `minstret` |
| `INSTR_EXPANDED_COMMIT` | Micro-op phải commit nguyên tử với micro-op kế | Thêm: **chặn interrupt** và **chặn vào debug mode** |
| `INSTR_EXPANDED_LAST` | Micro-op cuối | IF pop lệnh nén kế tiếp |

Ảnh hưởng:

* `ibex_if_stage.sv:808-810` / `:840-842`:
  `fetch_ready = id_in_ready_i & ~stall_dummy_instr & !(instr_gets_expanded inside
  {INSTR_EXPANDED, INSTR_EXPANDED_COMMIT})`
* `ibex_controller.sv:474-482`: `enter_debug_mode_prio_d` và `enter_debug_mode` bị
  chặn khi `instr_gets_expanded inside {INSTR_EXPANDED, INSTR_EXPANDED_COMMIT}`
* `ibex_controller.sv:498-501`: `handle_irq` bị chặn khi `== INSTR_EXPANDED_COMMIT`
* `ibex_id_stage.sv:1218-1220`: `instr_perf_count_id_o` = 0 cho micro-op không phải cuối
* `ibex_if_stage.sv:665-669`: `PCIncrCheck` bỏ qua khi đang bung

`flush_expanded_i = pc_set_i & (pc_mux_i == PC_EXC)` (`ibex_if_stage.sv:483`) — chỉ
exception mới xoá FSM Zcmp; branch/jump không thể xảy ra giữa chuỗi.

---

## 6. Chèn dummy instruction

`ibex_if_stage.sv:504-567` — khối `gen_dummy_instr` **[BẬT]**.

### 6.1 `ibex_dummy_instr`

`ibex/rtl/ibex_dummy_instr.sv` (150 dòng).

```
prim_lfsr (LfsrDw=32, StatePermEn=1, StatePerm=RndCnstLfsrPerm)
    seed_en_i  ← dummy_instr_seed_en_i (ghi CSR SECURESEED)
    seed_i     ← dummy_instr_seed_q ^ dummy_instr_seed_i   (tích luỹ XOR)
    lfsr_en_i  ← insert_dummy_instr & id_in_ready_i
         │
         ▼ lfsr_state[14:0]
    lfsr_data = { instr_type[1:0], op_b[4:0], op_a[4:0], cnt[4:0] }
```

Điều kiện chèn:

```systemverilog
dummy_cnt_threshold = lfsr_data.cnt & {dummy_instr_mask_i, 2'b11};  // TIMEOUT_CNT_W=5
dummy_cnt_en        = dummy_instr_en_i & id_in_ready_i & (fetch_valid_i | insert_dummy_instr);
dummy_cnt_d         = insert_dummy_instr ? '0 : dummy_cnt_q + 1;
insert_dummy_instr  = dummy_instr_en_i & (dummy_cnt_q == dummy_cnt_threshold);
```

`dummy_instr_mask_i` (3 bit từ CSR `CPUCTRLSTS`) cắt bớt chu kỳ ngẫu nhiên:
mask `3'b000` → ngưỡng ∈ [0,3] (chèn rất dày), mask `3'b111` → ngưỡng ∈ [0,31].

Lệnh dummy sinh ra (`ibex_dummy_instr.sv:144`):

```systemverilog
dummy_instr = {dummy_set, lfsr_data.op_b, lfsr_data.op_a, dummy_opcode, 5'h00, 7'h33};
//              funct7      rs2              rs1            funct3      rd=x0  OPCODE_OP
```

| `instr_type` | funct7 | funct3 | Lệnh |
|---|---|---|---|
| `DUMMY_ADD` | `0000000` | `000` | `add x0, opa, opb` |
| `DUMMY_MUL` | `0000001` | `000` | `mul x0, opa, opb` |
| `DUMMY_DIV` | `0000001` | `100` | `div x0, opa, opb` |
| `DUMMY_AND` | `0000000` | `111` | `and x0, opa, opb` |

Chọn 4 loại này vì chúng có **profile công suất/thời gian rất khác nhau**
(add 1 chu kỳ, mul 1 chu kỳ, div 37 chu kỳ) → làm nhiễu phân tích side-channel.

### 6.2 Mux vào luồng lệnh

```systemverilog
instr_out               = insert_dummy_instr ? dummy_instr_data : instr_decompressed;
instr_is_compressed_out = insert_dummy_instr ? 1'b0 : instr_is_compressed;
instr_gets_expanded_out = insert_dummy_instr ? INSTR_NOT_EXPANDED : instr_gets_expanded;
illegal_c_instr_out     = insert_dummy_instr ? 1'b0 : illegal_c_insn;
instr_err_out           = insert_dummy_instr ? 1'b0 : if_instr_err;
stall_dummy_instr       = insert_dummy_instr;
```

`stall_dummy_instr` chặn `fetch_ready` → lệnh thật vẫn nằm trong I$ output, được lấy lại
ở chu kỳ sau. PC của lệnh dummy trùng với PC của lệnh thật kế tiếp.

`dummy_instr_id_o` được flop cùng `if_id_pipe_reg_we` → đi kèm lệnh xuống ID/WB, và
cuối cùng tới register file để cho phép ghi x0.

---

## 7. Thanh ghi IF/ID

`ibex_if_stage.sv:568-660`

```systemverilog
instr_valid_id_d = (if_instr_valid & id_in_ready_i & ~pc_set_i) |
                   (instr_valid_id_q & ~instr_valid_clear_i);
instr_new_id_d   =  if_instr_valid & id_in_ready_i & ~pc_set_i;
if_id_pipe_reg_we = instr_new_id_d;
```

Ngữ nghĩa:

* Lệnh vào ID khi: I$ có dữ liệu **và** ID sẵn sàng **và** không có yêu cầu đổi PC.
  `~pc_set_i` chính là cơ chế **squash**: khi có branch/trap, lệnh đang ở đầu I$ bị bỏ.
* `instr_valid_id_q` **giữ** giá trị cho tới khi controller phát `instr_valid_clear_i`
  (khi lệnh hoàn thành hoặc bị flush). Đây là lý do lệnh multi-cycle "đứng yên" trong ID.

Vì `ResetAll = 1` → nhánh `g_instr_rdata_ra` được chọn: mọi flop dữ liệu đều có
`if (!rst_ni) ... <= '0`. Danh sách flop:
`instr_rdata_id_o`, `instr_rdata_alu_id_o`, `instr_fetch_err_o`, `instr_fetch_err_plus2_o`,
`instr_rdata_c_id_o`, `instr_is_compressed_id_o`, `instr_gets_expanded_id_o`,
`instr_expanded_id_o`, `illegal_c_insn_id_o`, `pc_id_o`.

Thêm khối riêng `gen_cheriot_vio_regs` (`ibex_if_stage.sv:634-656`) flop
`instr_fetch_cheriot_acc_vio_o` / `instr_fetch_cheriot_bound_vio_o`.

> `instr_rdata_alu_id_o` là **bản sao bit-hệt** của `instr_rdata_id_o`, chỉ để giảm
> fan-out trên đường tới ALU decoder. Assertion `IbexDuplicateInstrMatch` kiểm tra
> `instr_rdata_i === instr_rdata_alu_i` (dùng `===` vì DV có thể bơm X).

---

## 8. Kiểm tra tăng PC (`PCIncrCheck`)

`ibex_if_stage.sv:659-692` — **[BẬT]**, SEC_CM: `PC.CTRL_FLOW.CONSISTENCY`.

```systemverilog
prev_instr_seq_d = (prev_instr_seq_q | instr_new_id_d) &
                   ~branch_req & ~if_instr_err & ~stall_dummy_instr &
                   !(instr_gets_expanded inside {INSTR_EXPANDED, INSTR_EXPANDED_COMMIT});

prev_instr_addr_incr = pc_id_o + (instr_is_compressed_id_o ? 32'd2 : 32'd4);
prim_buf #(.Width(32)) u_prev_instr_addr_incr_buf (...);   // chặn tối ưu hoá

pc_mismatch_alert_o = prev_instr_seq_q & (pc_if_o != prev_instr_addr_incr_buf);
```

Logic: nếu lệnh trước chạy **tuần tự** (không branch, không lỗi, không dummy, không Zcmp),
thì `pc_if` bắt buộc phải bằng `pc_id + 2` hoặc `pc_id + 4`. Sai lệch → glitch trên
đường PC → `alert_major_internal_o`.

`prim_buf` là bắt buộc: nếu không, tổng hợp sẽ nhận ra `pc_if` được tính từ chính
`pc_id + 2/4` và tối ưu phép so sánh thành hằng `0`.

---

## 9. Khối không được sinh trong cấu hình này

| Khối | Điều kiện | Trạng thái |
|---|---|---|
| `ibex_prefetch_buffer` + `ibex_fetch_fifo` | `ICache == 0` | **[TẮT]** |
| `ibex_branch_predict` + skid buffer | `BranchPredictor == 1` | **[TẮT]** |

Với `BranchPredictor = 0`, nhánh `g_no_branch_predictor` (`ibex_if_stage.sv:799-812`):

```systemverilog
instr_bp_taken_o     = 1'b0;
predict_branch_taken = 1'b0;
if_instr_valid   = fetch_valid;
if_instr_rdata   = fetch_rdata;
if_instr_addr    = fetch_addr;
if_instr_bus_err = fetch_err;
fetch_ready = id_in_ready_i & ~stall_dummy_instr &
              !(instr_gets_expanded inside {INSTR_EXPANDED, INSTR_EXPANDED_COMMIT});
```

**Về `ibex_fetch_fifo`** (dùng khi `ICache=0`): FIFO sâu `NUM_REQS+1 = 3` entry,
mỗi entry 32-bit, có đường bypass trực tiếp `in_rdata_i → out_rdata_o`. Nó xử lý
việc ghép lệnh 32-bit trải qua 2 word (`rdata_unaligned = {rdata_q[1][15:0], rdata[31:16]}`)
và có chân `cheriot_force_uc_i` để ép coi là compressed. Trong cấu hình `opentitan`,
chức năng tương đương do **skid buffer** của I$ đảm nhiệm (xem [04_icache.md](04_icache.md) §6).
