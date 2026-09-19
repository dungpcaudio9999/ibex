# 11 — Deep dive multiplier/divider

## 1. Elaboration variants

`ibex_ex_block` chọn:

- no selected M result cho `RV32MNone`;
- `ibex_multdiv_slow` cho `RV32MSlow`;
- `ibex_multdiv_fast` cho Fast/SingleCycle.

OpenTitan dùng SingleCycle; FX1 dùng Fast. ISA result giống nhau, timing/FSM và
area khác.

## 2. Interface protocol

Inputs tách dynamic enables (`mult_en`, `div_en`) khỏi static result selects
(`mult_sel`, `div_sel`). `multdiv_ready_id` cho phép unit giữ finished result khi
WB/ID chưa nhận. Output `valid` kết thúc ID multi-cycle.

Intermediate values nằm ở ID flops, không bên trong hoàn toàn unit; reset/hold
contract đi xuyên module boundary.

## 3. Fast divide FSM

States:

```text
MD_IDLE -> MD_ABS_A -> MD_ABS_B -> MD_COMP ...
        -> MD_LAST -> MD_CHANGE_SIGN -> MD_FINISH -> MD_IDLE
```

- IDLE phát hiện denominator zero và initialize count.
- ABS states chuẩn hóa signed operands.
- COMP long-divides từng bit.
- LAST chọn quotient/remainder.
- CHANGE_SIGN phục hồi sign.
- FINISH giữ valid đến `multdiv_ready_id`.

State/data chỉ update khi internal enable; hold ngăn nhận lại operation khi
finished nhưng consumer chưa ready.

## 4. Divide special cases

Divide by zero:

- DIV quotient = all ones;
- REM result = numerator.

Khi DIT off, FSM có thể nhảy nhanh đến finish. Khi DIT on, full algorithm chạy
và tự tạo cùng result, đồng thời tránh latency leak. Signed overflow
`0x80000000 / -1` phải tuân RISC-V result semantics qua sign path.

## 5. Single-cycle multiplier

SingleCycle branch dùng ba multiplier 17×17 để tạo low product trong một cycle;
high product đi qua `MULL/MULH` sequencing. Tên “single cycle” không có nghĩa mọi
M instruction, đặc biệt MULH và divide, đều một cycle.

## 6. Fast multiplier

Fast non-single-cycle branch chia partial products thành states như ALBL, ALBH,
AHBL, AHBH. Shared accumulator/intermediate registers gom signed partials. Exact
latency phụ thuộc low/high operator và ready; phải xác nhận L4.

## 7. Slow unit

Slow implementation dùng iterative shift/add cho multiplication và division,
tối ưu area. Nó dùng shared ALU extensively và có FSM cùng nhóm ABS/COMP/LAST/
SIGN/FINISH nhưng data scheduling khác fast.

Không active trong bốn scope profiles; tài liệu giữ để hiểu parameter contract.

## 8. DIT impact

`data_ind_timing_i` chủ yếu khóa early termination dựa trên operand như zero
denominator. DIT support được compile do SecureIbex, nhưng runtime CSR bit quyết
định behavior. Test phải set/read CSR, không chỉ nhìn parameter.

## 9. Arbitration with ALU

`multdiv_sel = mult_sel || div_sel` nếu M enabled. It selects:

- EX result;
- intermediate data/write enables;
- validity source;
- ALU shared adder operands.

Decoder phải bảo đảm mult và div selects/enables consistent, không đồng thời
claim với multi-cycle bitmanip.

## 10. Assertions

- enables known;
- FSM state valid;
- internal idle signal cho hierarchical checking;
- result held while consumer not ready;
- ID must stall on first→multi transition.

## 11. Findings

- **Fact F-MD-01:** OpenTitan MUL-low và FX1 MUL-low có different latency class.
- **Fact F-MD-02:** DIV timing can remain data-dependent unless runtime DIT set.
- **Inference I-MD-01:** Firmware performance assumptions based on OpenTitan
  cannot be copied to FX1.
- **Open O-MD-01:** Measure exact cycles for all four MUL/DIV result forms under
  WB back-pressure and DIT.

## 12. L4 handoff

Operand matrix: 0, 1, -1, min-int, max-int, random; DIV/REM signed/unsigned;
MUL/MULH/MULHSU/MULHU; ready deassert at finish; reset during operation; compare
OpenTitan/FX1 cycles.

## 13. Source anchors

- [`rtl/ibex_multdiv_fast.sv`](../../../../rtl/ibex_multdiv_fast.sv)
- [`rtl/ibex_multdiv_slow.sv`](../../../../rtl/ibex_multdiv_slow.sv)
- [`rtl/ibex_ex_block.sv`](../../../../rtl/ibex_ex_block.sv)

