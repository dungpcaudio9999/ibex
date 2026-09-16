# 06 — Tầng EX: ALU, Branch-Target ALU, MUL/DIV

Tệp: `ibex/rtl/ibex_ex_block.sv` (217 dòng), `ibex_alu.sv` (1400), `ibex_multdiv_fast.sv` (556).

---

## 1. `ibex_ex_block` — khối bọc

`ibex_ex_block.sv`

```
   alu_operator_i  ──┐
   alu_operand_a_i ──┤                         ┌──────────┐
   alu_operand_b_i ──┼────────────────────────►│ ibex_alu │──► alu_result
   instr_first_cycle_i                         │          │──► adder_result_o ──► LSU
                     │  multdiv_alu_operand_a/b│          │──► adder_result_ext_o (34b)
                     │  ◄──────────────────────│          │──► comparison_result_o
                     │  multdiv_sel_i          │          │──► is_equal_result_o
                     │                         └────▲─────┘
                     │                              │ alu_imd_val_q (32b × 2)
                     │
   multdiv_operand_a_i ──┐                    ┌─────────────────┐
   multdiv_operand_b_i ──┼───────────────────►│ ibex_multdiv    │──► multdiv_result
   multdiv_operator_i    │                    │      _fast      │──► valid_o
   mult_en/div_en        │                    │  (SingleCycle)  │──► alu_operand_a/b_o
   mult_sel/div_sel      │  alu_adder_i ─────►│                 │──► imd_val_d_o (34b×2)
   data_ind_timing_i     │  alu_adder_ext_i ─►│                 │
                         │  equal_to_zero_i ─►└─────────────────┘
   bt_a_operand_i ──┐
   bt_b_operand_i ──┴──► [ adder 33-bit ] ──► branch_target_o
```

### 1.1 Chia sẻ thanh ghi trung gian

```systemverilog
multdiv_sel = mult_sel_i | div_sel_i;                          // RV32M != None

imd_val_d_o[0] = multdiv_sel ? multdiv_imd_val_d[0] : {2'b0, alu_imd_val_d[0]};
imd_val_d_o[1] = multdiv_sel ? multdiv_imd_val_d[1] : {2'b0, alu_imd_val_d[1]};
imd_val_we_o   = multdiv_sel ? multdiv_imd_val_we  : alu_imd_val_we;
alu_imd_val_q  = '{imd_val_q_i[0][31:0], imd_val_q_i[1][31:0]};
```

Hai thanh ghi 34-bit dùng chung. ALU chỉ dùng 32 bit thấp; MULDIV dùng cả 34 bit
(MAC result cần 34 bit, remainder cần 33 bit + bit mượn).

Lưu ý `mult_sel_i`/`div_sel_i` là tín hiệu **tĩnh từ decoder** (không phụ thuộc
`instr_executing`), còn `mult_en_i`/`div_en_i` là tín hiệu **động** (đã qualify). Tách đôi
để các mux dữ liệu (dùng `_sel`) không nằm trên đường điều khiển FSM (dùng `_en`).

### 1.2 Kết quả và `ex_valid`

```systemverilog
result_ex_o       = multdiv_sel ? multdiv_result : alu_result;
branch_decision_o = alu_cmp_result;
ex_valid_o        = multdiv_sel ? multdiv_valid : ~(|alu_imd_val_we);
```

`ex_valid_o` cho lệnh ALU thường = 1 (vì `alu_imd_val_we = 0`); với bitmanip multi-cycle,
chu kỳ đầu ghi `imd_val` → `ex_valid=0`, chu kỳ hai `imd_val_we=0` → `ex_valid=1`.

### 1.3 Branch-Target ALU **[BẬT]**

```systemverilog
bt_alu_result   = bt_a_operand_i + bt_b_operand_i;    // 33-bit, carry bỏ
branch_target_o = bt_alu_result[31:0];
```

Bộ cộng 32-bit **riêng biệt**, chạy song song với ALU chính. Nhờ đó:
* **JAL/JALR**: ALU chính tính `pc + 2/4` (link address), BT-ALU tính đích → **0 stall**.
* **Branch**: ALU chính tính điều kiện (`comparison_result_o`), BT-ALU tính đích cùng lúc
  → taken branch chỉ **1 stall** (thay vì 2).

Với `BranchTargetALU = 0` thì `branch_target_o = alu_adder_result_ex_o` — phải dùng ALU
chính, nên cần chu kỳ thứ hai.

---

## 2. `ibex_alu` — chi tiết từng khối con

### 2.1 Bộ cộng (Adder)

`ibex_alu.sv:45-109`

```systemverilog
// Điều khiển
unique case (operator_i)
  ALU_SUB, ALU_EQ, ALU_NE, ALU_GE, ALU_GEU, ALU_LT, ALU_LTU,
  ALU_SLT, ALU_SLTU, ALU_MIN, ALU_MINU, ALU_MAX, ALU_MAXU: adder_op_b_negate = 1'b1;
  ALU_SH1ADD: adder_op_a_shift1 = 1'b1;
  ALU_SH2ADD: adder_op_a_shift2 = 1'b1;
  ALU_SH3ADD: adder_op_a_shift3 = 1'b1;
endcase

// Toán hạng A (33-bit, bit 0 = 1 làm carry-in)
unique case (1'b1)
  multdiv_sel_i:     adder_in_a = multdiv_operand_a_i;     // 33-bit từ MULDIV
  adder_op_a_shift1: adder_in_a = {operand_a_i[30:0], 2'b01};
  adder_op_a_shift2: adder_in_a = {operand_a_i[29:0], 3'b001};
  adder_op_a_shift3: adder_in_a = {operand_a_i[28:0], 4'b0001};
  default:           adder_in_a = {operand_a_i, 1'b1};
endcase

// Toán hạng B
operand_b_neg = {operand_b_i, 1'b0} ^ {33{1'b1}};           // ~(b<<1)
unique case (1'b1)
  multdiv_sel_i:     adder_in_b = multdiv_operand_b_i;
  adder_op_b_negate: adder_in_b = operand_b_neg;
  default:           adder_in_b = {operand_b_i, 1'b0};
endcase

adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
adder_result       = adder_result_ext_o[32:1];
```

**Kỹ thuật:** toán hạng được dịch trái 1 bit, bit 0 của A là hằng `1`. Khi trừ
(`b_negate`), `adder_in_b = ~(b<<1)` và `adder_in_a[0] = 1` → tổng = `a - b` ở bit [32:1]
theo bù hai. Nhờ vậy **một** bộ cộng 33-bit làm được cả cộng, trừ, so sánh, và
`sh1/2/3add`, đồng thời chia sẻ với MULDIV.

`adder_result_ex_o` đi thẳng ra LSU làm địa chỉ truy cập (đường tới hạn quan trọng).

### 2.2 Bộ so sánh

`ibex_alu.sv:112-174`

```systemverilog
is_equal = (adder_result == 32'b0);

// signed/unsigned
cmp_signed cho: ALU_GE, ALU_LT, ALU_SLT, ALU_MIN, ALU_MAX

is_greater_equal = (operand_a_i[31] ^ operand_b_i[31]) ? ~cmp_signed ^ operand_a_i[31]
                                                       : ~adder_result[31];
// (dạng rút gọn; mã thực dùng bảng chân lý trong comment :144-154)

unique case (operator_i)
  ALU_EQ:             cmp_result =  is_equal;
  ALU_NE:             cmp_result = ~is_equal;
  ALU_GE, ALU_GEU, ALU_MAX, ALU_MAXU: cmp_result =  is_greater_equal;
  ALU_LT, ALU_LTU, ALU_MIN, ALU_MINU, ALU_SLT, ALU_SLTU: cmp_result = ~is_greater_equal;
endcase
```

`comparison_result_o` → `branch_decision`; `is_equal_result_o` → MULDIV để phát hiện
chia cho 0.

### 2.3 Bộ dịch (Shifter) — 33 bit

`ibex_alu.sv:176-356`

Kiến trúc: **một** bộ dịch phải 33-bit. Dịch trái = đảo bit vào → dịch phải → đảo bit ra.

```systemverilog
// Đảo bit operand_a cho dịch trái / đếm bit
for (k = 0; k < 32; k++) operand_a_rev[k] = operand_a_i[31-k];
```

| Chế độ | `shift_left` | Ghi chú |
|---|---|---|
| `ALU_SLL`, `ALU_SLO`, `ALU_BFP` | 1 | |
| `ALU_SRL`, `ALU_SRA`, `ALU_SRO` | 0 | |
| `ALU_ROL` | `instr_first_cycle_i` | chu kỳ 1 trái, chu kỳ 2 phải |
| `ALU_ROR` | `~instr_first_cycle_i` | ngược lại |
| `ALU_FSL`/`ALU_FSR` | phụ thuộc `shift_amt[5]` và chu kỳ | |
| `ALU_BSET/BCLR/BINV` | 1 (`shift_sbmode`) | dịch `32'h1` để tạo mask |
| `ALU_BEXT` | 0 | dịch phải rồi lấy bit [0] |

Bit thứ 33 (`shift_ones`) dùng cho:
* `ALU_SRA` — nhân bản bit dấu.
* `ALU_SLO`/`ALU_SRO` — "shift ones" (dịch vào bit 1 thay vì 0), chỉ có ở
  `RV32BOTEarlGrey`/`RV32BFull`.

**Rotate (multi-cycle, 2 chu kỳ):**
```
shift_amt = rs2 & 31
kết quả   = (rs1 >> shift_amt) | (rs1 << (32 - shift_amt))
             └── chu kỳ 0 ──┘    └────── chu kỳ 1 ──────┘
```
Chu kỳ 0 ghi `imd_val_q[0]`, chu kỳ 1 OR với `shift_result`.

**Funnel shift (`fsl`/`fsr`, 2 chu kỳ):**
```
shift_amt      = rs2 & 63
shift_amt_compl= 32 - shift_amt[4:0]
if (shift_amt >= 33): kq = (rs1 >> compl) | (rs3 << shift_amt[4:0])
else if (1..31):      kq = (rs1 << shift_amt) | (rs3 >> compl)
if (shift_amt == 0):  kq = rs1
if (shift_amt == 32): kq = rs3
```
Chu kỳ 1 dùng `rs3` (đọc qua `use_rs3_q` ở decoder).

### 2.4 Logic bitwise

`ibex_alu.sv:358-410`

```systemverilog
bwlogic_op_b_negate = (operator_i inside {ALU_XNOR, ALU_ORN, ALU_ANDN}) |
                      shift_sbmode;                  // bclr cần ~mask
bwlogic_b = bwlogic_op_b_negate ? ~operand_b_i : operand_b_i;

bwlogic_and_result = operand_a_i & bwlogic_b;
bwlogic_or_result  = operand_a_i | bwlogic_b;
bwlogic_xor_result = operand_a_i ^ bwlogic_b;
```

Tái sử dụng cho `bset` (OR mask), `bclr` (AND ~mask), `binv` (XOR mask).

### 2.5 Khối bitmanip `RV32BOTEarlGrey`

`ibex_alu.sv:648-994` — khối `gen_alu_rvb_otearlgrey_full` **[BẬT]**.

| Khối con | Lệnh | Cấu trúc |
|---|---|---|
| Shuffle/Unshuffle | `shfl[i]`, `unshfl[i]` | 4 tầng butterfly với `SHUFFLE_MASK_L/R[4]` và `FLIP_MASK_L/R[4]` |
| xperm | `xperm.n` (nibble), `xperm.b` (byte), `xperm.h` (half) | 8/4/2 bộ mux |
| Bit-count | `clz`, `ctz`, `cpop` | Dùng `operand_a_rev` cho `clz`; cây cộng cho `cpop` |
| Min/Max | `min[u]`, `max[u]` | Mux theo `cmp_result` |
| Pack | `pack`, `packu`, `packh` | Ghép nửa từ |
| Sign-extend | `sext.b`, `sext.h` | |
| GREV/GORC | `grev[i]`, `gorc[i]` | 5 tầng hoán vị bit theo `shift_amt[4:0]` |
| CLMUL | `clmul`, `clmulh`, `clmulr` | Mảng 32×32 AND + XOR reduction |
| CRC32 | `crc32.b/h/w`, `crc32c.b/h/w` | **Multi-cycle**, dùng lại CLMUL: 2 chu kỳ với hằng `SN`/`S2N` |

Chi tiết CRC (`ibex_alu.sv:905-994`):
```systemverilog
crc_bmode = (operator_i == ALU_CRC32_B) | (operator_i == ALU_CRC32C_B);
// chu kỳ 0: clmul với hằng μ (Barrett)
// chu kỳ 1: multicycle_result = clmul_result_rev ^ (operand_a_i >> 8/16/0)
```

**Không có trong `RV32BOTEarlGrey`** (chỉ `RV32BFull`, khối `gen_alu_rvb_full`
`ibex_alu.sv:996-1312`):
`bcompress`/`bdecompress` (butterfly network), `bfp` (bit-field place),
`cmov`/`cmix` (ternary select).

Lưu ý: `fsl`/`fsr`/`rol`/`ror` **có** trong cấu hình này vì chúng được xử lý trực tiếp
bởi shifter (`ibex_alu.sv:305-330`) và mux multicycle nằm trong `if (RV32B != RV32BNone)`.

### 2.6 Mux kết quả

`ibex_alu.sv:1316-1398`

```systemverilog
unique case (operator_i)
  ALU_XOR, ALU_XNOR, ALU_OR, ALU_ORN, ALU_AND, ALU_ANDN: result_o = bwlogic_result;
  ALU_ADD, ALU_SUB, ALU_SH1ADD, ALU_SH2ADD, ALU_SH3ADD:  result_o = adder_result;
  ALU_SLL, ALU_SRL, ALU_SRA, ALU_SLO, ALU_SRO, ALU_BEXT: result_o = shift_result;
  ALU_EQ, ALU_NE, ALU_GE, ..., ALU_SLTU:                 result_o = {31'h0, cmp_result};
  ALU_FSL, ALU_FSR, ALU_ROL, ALU_ROR, ALU_CRC32*,
  ALU_BCOMPRESS, ALU_BDECOMPRESS:                        result_o = multicycle_result;
  ... (bitmanip khác)
endcase
```

---

## 3. `ibex_multdiv_fast` với `RV32MSingleCycle`

`ibex_multdiv_fast.sv`. Khối `gen_mult_single_cycle` (`:136-252`) **[BẬT]**.

### 3.1 Nhân — 3 bộ nhân 17×17

```systemverilog
mult1_res = $signed({mult1_sign_a, mult1_op_a}) * $signed({mult1_sign_b, mult1_op_b});
mult2_res = ...;   mult3_res = ...;
mac_res_signed = $signed(summand1) + $signed(summand2) + $signed(summand3);
```

Phân rã `A × B` với `A = {ah, al}`, `B = {bh, bl}` (mỗi phần 16 bit):
```
A × B = al·bl + (al·bh)<<16 + (ah·bl)<<16 + (ah·bh)<<32
```

**Trạng thái `MULL` (chu kỳ 1):**

| Bộ nhân | A | B | sign_a | sign_b |
|---|---|---|---|---|
| mult1 | `al` | `bl` | 0 | 0 |
| mult2 | `al` | `bh` | 0 | `sign_b` |
| mult3 | `ah` | `bl` | `sign_a` | 0 |

```systemverilog
summand1 = {18'h0, mult1_res_uns[31:16]};   // phần cao của al·bl
summand2 = mult2_res;                        // al·bh
summand3 = mult3_res;                        // ah·bl
mac_res_d = {2'b0, mac_res[15:0], mult1_res_uns[15:0]};   // = A*B[31:0]
mult_valid = mult_en_i;
```

→ `MUL` hoàn thành trong **1 chu kỳ**. `mult_hold = ~multdiv_ready_id_i` giữ kết quả
nếu WB chưa sẵn sàng.

**Trạng thái `MULH` (chu kỳ 2, chỉ khi `operator != MD_OP_MULL`):**

| Bộ nhân | A | B | sign_a | sign_b |
|---|---|---|---|---|
| mult3 | `ah` | `bh` | `sign_a` | `sign_b` |

```systemverilog
accum[17:0]  = imd_val_q_i[0][33:16];                    // mang từ chu kỳ trước
accum[33:18] = {16{signed_mult & imd_val_q_i[0][33]}};   // mở rộng dấu
summand1 = '0;  summand2 = accum;  summand3 = mult3_res;
mac_res_d = mac_res;
mult_valid = 1'b1;
```

→ `MULH/MULHSU/MULHU` mất **2 chu kỳ** (1 stall).

`signed_mode_i[1:0]`:
| Lệnh | `signed_mode` |
|---|---|
| `MUL` | `2'b00` |
| `MULH` | `2'b11` |
| `MULHSU` | `2'b01` |
| `MULHU` | `2'b00` |

```systemverilog
sign_a = signed_mode_i[0] & op_a_i[31];
sign_b = signed_mode_i[1] & op_b_i[31];
```

(So sánh `RV32MFast` — `gen_mult_fast`, `:274-390`: **một** bộ nhân 17×17, FSM 4 trạng
thái `ALBL → ALBH → AHBL → AHBH`; MUL 3 chu kỳ, MULH 4 chu kỳ.)

### 3.2 Chia — long division 7 trạng thái

`ibex_multdiv_fast.sv:384-530`

```
MD_IDLE ──► MD_ABS_A ──► MD_ABS_B ──► MD_COMP ──(×31)──► MD_LAST ──► MD_CHANGE_SIGN ──► MD_FINISH
   │                                                                                       │
   └──(div by 0 & !data_ind_timing)─────────────────────────────────────────────────────────┘
```

| Trạng thái | Nội dung | ALU operand phát ra |
|---|---|---|
| `MD_IDLE` | Khởi tạo: DIV → `remainder = '1` (tức -1); REM → `remainder = op_a`. Đặt `div_counter = 31`. Ghi nhận `div_by_zero_d = equal_to_zero_i` | `0 - op_b` (để test `op_b == 0`) |
| `MD_ABS_A` | `op_numerator = |op_a|`, `op_quotient = 0` | `0 - op_a` |
| `MD_ABS_B` | `op_denominator = |op_b|`, `remainder = {33'h0, numerator[31]}` | `0 - op_b` |
| `MD_COMP` | 31 lần lặp: dịch remainder, so sánh, trừ có điều kiện | `remainder - denominator` |
| `MD_LAST` | Lần lặp cuối; DIV lưu quotient, REM lưu remainder | như trên |
| `MD_CHANGE_SIGN` | Đảo dấu nếu cần | `0 - result` |
| `MD_FINISH` | `div_valid = 1`, giữ tới khi `multdiv_ready_id_i` | — |

Vòng lặp lõi:
```systemverilog
res_adder_h     = alu_adder_ext_i[32:1];             // remainder - denominator
is_greater_equal = ((imd_val_q_i[0][31] ^ op_denominator_q[31]) == 1'b0)
                   ? (res_adder_h[31] == 1'b0)       // cùng dấu → xem bit dấu kết quả
                   : imd_val_q_i[0][31];             // khác dấu → remainder âm thì nhỏ hơn

next_remainder = is_greater_equal ? res_adder_h[31:0] : imd_val_q_i[0][31:0];
next_quotient  = is_greater_equal ? (op_quotient_q | one_shift) : op_quotient_q;
one_shift      = 32'h1 << div_counter_q;

// MD_COMP:
op_remainder_d = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_d]};  // dịch trái + nạp bit
op_quotient_d  = next_quotient[31:0];
```

**Tổng số chu kỳ chia:** 1 (IDLE) + 1 (ABS_A) + 1 (ABS_B) + 31 (COMP) + 1 (LAST)
+ 1 (CHANGE_SIGN) + 1 (FINISH) = **37 chu kỳ** (36 stall).

**Chia cho 0:**
```systemverilog
md_state_d = (!data_ind_timing_i && equal_to_zero_i) ? MD_FINISH : MD_ABS_A;
```
* `data_ind_timing = 0`: nhảy thẳng `MD_IDLE → MD_FINISH` = **2 chu kỳ** (1 stall).
  Kết quả: DIV → `-1` (đã set `'1` ở IDLE), REM → `op_a`.
* `data_ind_timing = 1`: chạy đủ 37 chu kỳ; `div_by_zero_q` chặn đảo dấu cuối
  (`div_change_sign = (div_sign_a ^ div_sign_b) & ~div_by_zero_q`) để kết quả vẫn đúng `-1`.

### 3.3 Chia sẻ tài nguyên với ALU

MULDIV **không có bộ cộng riêng** — mọi phép cộng/trừ đều mượn adder của ALU:

```systemverilog
alu_operand_a_o / alu_operand_b_o  →  ibex_alu.multdiv_operand_a_i / _b_i
ibex_alu.adder_result_o      →  multdiv.alu_adder_i
ibex_alu.adder_result_ext_o  →  multdiv.alu_adder_ext_i
ibex_alu.is_equal_result_o   →  multdiv.equal_to_zero_i
```

Đây là lý do `multdiv_sel_i` xuất hiện trong mux toán hạng của adder ALU.

### 3.4 Điều khiển hold

```systemverilog
mult_en_internal = mult_en_i & ~mult_hold;
div_en_internal  = div_en_i  & ~div_hold;
multdiv_en       = mult_en_internal | div_en_internal;

imd_val_we_o[0] = multdiv_en;
imd_val_we_o[1] = div_en_internal;

valid_o = mult_valid | div_valid;
```

`mult_hold`/`div_hold` = `~multdiv_ready_id_i` ở trạng thái cuối. `multdiv_ready_id_o = ready_wb_i`
(`ibex_id_stage.sv:976`) → khi WB đầy, MULDIV giữ nguyên kết quả và **không** chuyển
trạng thái (vì `always_ff` chỉ cập nhật khi `*_en_internal`).

### 3.5 Kết quả

```systemverilog
multdiv_result_o = div_sel_i ? imd_val_q_i[0][31:0] : mac_res_d[31:0];
```

DIV lấy từ thanh ghi trung gian (đã ghi ở `MD_CHANGE_SIGN`); MUL lấy trực tiếp tổ hợp
từ `mac_res_d` — tổ hợp thuần, chính là lý do MUL đạt 1 chu kỳ.

---

## 4. Tổng kết độ trễ EX (cấu hình `opentitan`)

| Lệnh | Chu kỳ trong ID/EX | Stall |
|---|---|---|
| ALU đơn (add/sub/logic/shift/slt) | 1 | 0 |
| Bitmanip 1 chu kỳ (zba/zbb/zbs/clmul/shfl/xperm/grev) | 1 | 0 |
| Bitmanip 2 chu kỳ (`rol/ror/fsl/fsr/crc32*`) | 2 | 1 |
| `MUL` | 1 | 0 |
| `MULH/MULHSU/MULHU` | 2 | 1 |
| `DIV/DIVU/REM/REMU` (b≠0) | 37 | 36 |
| `DIV/REM` (b=0, DIT off) | 2 | 1 |
| `DIV/REM` (b=0, DIT on) | 37 | 36 |
| `JAL/JALR` | 1 | 0 (nhờ BT-ALU) |
| Branch không taken | 1 | 0 |
| Branch taken (DIT off) | 1 | 0 trong ID + N chu kỳ chờ I$ |
| Branch (DIT on) | 2 | 1 + N |
| `LW/SW` | 1 + chờ phản hồi | 1–N |
