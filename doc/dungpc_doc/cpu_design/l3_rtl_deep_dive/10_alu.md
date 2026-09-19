# 10 — Deep dive ALU

## 1. Contract

`ibex_alu` nhận operator, hai operand, first-cycle marker và intermediate values;
trả result, extended adder, compare và optional intermediate writes. ALU còn cho
MUL/DIV mượn adder operands/result.

## 2. Shared adder

Adder mở rộng chọn negate B cho SUB/compare/minmax, shift A trước cộng cho SH1/2/3ADD.
Outputs:

- 32-bit add result cho normal ALU/LSU;
- extended result/carry/sign phục vụ compare và MUL/DIV;
- equality/greater-equal derivations.

Signed compare xử lý sign bits trước magnitude; unsigned dùng extended carry.
Branch decision lấy compare result chứ không từ `result_o` mux cuối.

## 3. Logic and shift

Bitwise block dùng optional negate B để chia sẻ XOR/XNOR, OR/ORN, AND/ANDN.
Shifter hỗ trợ logical/arithmetic, rotate, funnel và bit set/clear/invert/extract
theo RV32B level. Left shifts có thể dùng bit reversal quanh right-shift fabric.

## 4. Result classes

Final mux bao phủ:

- arithmetic/address;
- comparisons;
- bitwise;
- shifts/rotates/funnel;
- min/max;
- count/pack/sign-extend;
- single-bit ops;
- reverse/or-combine/shuffle/xperm;
- carry-less multiply/CRC;
- compress/decompress/BFP;
- multi-cycle ternary operations.

Decoder legality phải ngăn operator thuộc feature inactive; ALU vẫn tạo safe
constant/default paths để tránh X/lint.

## 5. RV32B generate hierarchy

`RV32BNone` tie-off intermediate values và loại large bitmanip tree. Non-none tạo
common Zba/Zbb/Zbs-related hardware. `OTEarlGrey/Full` thêm shuffle, xperm,
carry-less multiply và CRC. `Full` thêm compress/decompress và các full-only
paths.

FX1 `RV32BNone`: main critical ALU còn add/sub/compare/logic/shift. OpenTitan
`OTEarlGrey`: area/timing/ID multi-cycle behavior rộng hơn.

## 6. Multi-cycle ALU protocol

CMOV/CMIX/funnel/rotate/CRC/bit compress classes có thể:

1. first cycle ghi `imd_val_d` và assert `imd_val_we`;
2. ID FSM giữ instruction;
3. later cycle combine intermediate với new partial result;
4. deassert write enable để `ex_valid` lên.

`ibex_ex_block` dùng `~|alu_imd_val_we` làm ALU validity. Vì vậy write-enable là
protocol state, không chỉ storage enable.

## 7. Shared use by MUL/DIV

Khi multdiv selected, EX mux intermediate write/data sang MUL/DIV và ALU adder
operands có thể đến từ multiplier/divider. Changes trong adder width, negate hoặc
carry semantics phải regression cả M extension.

## 8. First-cycle semantics

`instr_first_cycle_i` đổi direction/partial result cho rotate/funnel/ternary.
Nếu ID giữ first-cycle marker sai qua stall, ALU có thể lặp phase 1 hoặc chọn sai
phase. Assertion nằm chủ yếu ở ID; ALU dựa vào contract input.

## 9. Critical-path candidates

- RF/forward mux → shared adder → LSU address.
- RF → compare → branch decision → controller redirect.
- OTEarlGrey permutation/xperm/CLMUL result mux.
- operator decode → final wide result mux.

Đây là structural candidates; synthesis report mới định lượng.

## 10. Assertions/review checks

- Operator known khi instruction valid (ở ID/core).
- Intermediate write chỉ ở supported multi-cycle op.
- Feature-inactive outputs constant.
- Compare result matches signed/unsigned class.
- Multdiv ownership của shared adder/intermediate exclusive.

## 11. Findings

- **Fact F-ALU-01:** `imd_val_we` trực tiếp quyết định `ex_valid`; sửa intermediate
  logic có thể deadlock ID.
- **Fact F-ALU-02:** FX1 loại bitmanip hardware nhưng firmware compatibility giảm.
- **Inference I-ALU-01:** Branch compare/shared-adder paths cần timing review sau
  CHERIoT LSU policy mux.
- **Open O-ALU-01:** L4 exhaustive arithmetic corner vectors và synthesis timing.

## 12. L4 handoff

ADD/SUB carry/overflow boundaries, all compare signs, shifts 0/31, inactive B
illegal, OpenTitan multi-cycle rotate/CRC, branch compare under stalls, LSU
address and divider shared-adder activity.

## 13. Source anchors

- [`rtl/ibex_alu.sv`](../../../../rtl/ibex_alu.sv)
- [`rtl/ibex_ex_block.sv`](../../../../rtl/ibex_ex_block.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)

