# 06 — Execution datapath và CHERIoT execution

## 1. Hai datapath execution song song

Khi `BaseIsaRV32IorCHERIoT` được chọn, core có hai đường execution:

```text
RV32 decode -> ibex_ex_block -------> result/branch/LSU address
CHERIoT decode -> ibex_cheriot_ex ---> data+cap/branch/LSU+SCR
```

`cheriot_enable_i` chọn mode runtime. Đây không phải hai core: chúng dùng chung
IF, ID controller, LSU, WB, CSR và register file vật lý.

## 2. `ibex_ex_block`

Khối EX tiêu chuẩn chứa:

- `ibex_alu`;
- branch-target adder tùy chọn;
- một implementation MUL/DIV được chọn lúc elaboration;
- mux intermediate registers dùng chung cho ALU multi-cycle và MUL/DIV.

Result cuối:

```text
result_ex = multdiv_selected ? multdiv_result : alu_result
```

`ex_valid` báo result đã hoàn tất. Với ALU multi-cycle, việc còn ghi
`imd_val_*` cho biết operation chưa xong; với MUL/DIV dùng `multdiv_valid`.

## 3. ALU

ALU chịu trách nhiệm cho:

- cộng/trừ và effective address;
- compare signed/unsigned và branch decision;
- boolean operations;
- shift/rotate;
- count/bit manipulation theo `RV32B`;
- một số operation nhiều chu kỳ dùng hai thanh ghi trung gian 34 bit.

Adder có output 33/34 bit mở rộng để MUL/DIV tái sử dụng. Vì vậy thay đổi adder
hoặc operand mux có thể ảnh hưởng cả branch, LSU và divider.

Ở FX1 DEV/PROD, `RV32BNone` giúp synthesis loại phần bitmanip; OpenTitan dùng
`RV32BOTEarlGrey` nên datapath lớn hơn đáng kể.

## 4. Branch target

Nếu `BranchTargetALU=1`, một adder 33 bit riêng tính target từ `bt_a_operand` và
`bt_b_operand`. ALU chính đồng thời compare điều kiện branch hoặc tạo link data.

Nếu parameter bằng 0, target lấy từ main ALU adder. ID controller phải phân
chu kỳ để không yêu cầu adder làm hai việc xung đột.

Mọi profile đang xét đều bật branch-target ALU.

## 5. Multiply/divide variants

| Parameter | Implementation | Đặc điểm |
|---|---|---|
| `RV32MNone` | không chọn result M | logic được synthesis bỏ |
| `RV32MSlow` | `ibex_multdiv_slow` | area nhỏ, nhiều chu kỳ |
| `RV32MFast` | `ibex_multdiv_fast` | multiplier nhiều bước nhanh hơn slow |
| `RV32MSingleCycle` | `ibex_multdiv_fast` | MUL thấp có thể xong một chu kỳ |

OpenTitan dùng single-cycle; FX1 dùng fast. Divider vẫn là FSM multi-cycle và
có thể dùng early-out khi data-independent timing tắt.

`data_ind_timing_i=1` ngăn các quyết định latency dựa trên giá trị operand cho
branch/divide. Mục tiêu là giảm timing side channel, đổi lại mất early-out.

## 6. Intermediate registers

Hai entry `imd_val_q_ex[2]`, mỗi entry 34 bit, nằm ở ID stage nhưng được EX đọc
và ghi. Mux ownership:

```text
multdiv selected -> imd value từ MUL/DIV
otherwise        -> imd value từ ALU
```

Khi debug multi-cycle operation, cần xem cả state FSM và `imd_val_we`; chỉ xem
`result_ex` có thể thấy giá trị trung gian chưa hợp lệ.

## 7. Capability representation

`ibex_cheriot_pkg` định nghĩa hai dạng:

### `cap_t` — dạng nén 35 bit

- 2 correction bits;
- valid/tag;
- reserved bit;
- 6 compressed permission bits;
- 3-bit object type;
- 4-bit exponent;
- top/base mantissa, mỗi trường 9 bit.

Dạng này được lưu trong RF, CSR và đi qua ECC/lockstep.

### `decoded_cap_t` — dạng mở rộng 112 bit

Ngoài toàn bộ 35 bit trên, nó có:

- absolute top 33 bit;
- absolute base 32 bit;
- 12 permission bits mở rộng.

Dạng mở rộng chỉ dùng trong datapath để compare bounds/permission. Không nên
ước lượng storage RF theo 112 bit.

## 8. Register operands trong CHERIoT mode

Mỗi operand gồm:

```text
pointer/data 32 bit + capability metadata 35 bit
```

`ibex_cheriot_ex` nhận data/cap từ RF và đường forwarding WB. Nó decode metadata
dựa trên pointer hiện tại để dựng absolute bounds.

Nếu WB destination trùng source, forwarding phải thay đồng thời cả data và
capability; chỉ forward data sẽ tạo capability không nhất quán.

## 9. Các nhóm operation CHERIoT

CHERIoT EX thực hiện:

- lấy/đổi address của capability;
- set bounds và exact bounds;
- đọc base/top/length/permissions/type/tag;
- seal/unseal và sentry control flow;
- capability branch/jump;
- capability load/store;
- SCR read/write;
- permission reduction và tag clearing.

Set-bounds là datapath đáng chú ý: tính candidate exponent, kiểm parent bounds,
làm tròn representable base/top và có thể clear valid nếu exact request không
biểu diễn được.

## 10. PCC và control flow

PCC là decoded capability đại diện quyền thực thi hiện tại. CHERIoT branch/jump
phải kiểm:

- tag/valid;
- executable permission;
- sealing/sentry rules;
- target trong bounds;
- alignment.

Output gồm branch request, speculative branch request, target mới và PCC mới.
IF dùng PCC mới để bảo vệ các fetch tiếp theo.

Debug mode có xử lý riêng để debugger không bị chặn bởi policy thông thường
trong những trường hợp đã được thiết kế cho phép.

## 11. Capability memory request

CHERIoT EX đứng trước LSU về policy:

1. chọn authority capability;
2. tính effective address;
3. kiểm tag, sealed state, bounds và LD/SD/MC permissions;
4. sinh `lsu_cheriot_err` nếu vi phạm;
5. nếu hợp lệ, đưa `lsu_is_cap`, data/cap write payload và clear-permission rules
   xuống LSU.

LSU không tự quyết định capability có quyền truy cập hay không; nó chịu trách
nhiệm protocol, alignment, encoding và response assembly.

## 12. Fault split EX và WB

- Fault biết ngay từ operand/policy phát ở CHERIoT EX.
- Fault phụ thuộc load response/tag hoặc SCR completion có thể chỉ biết ở WB.
- Controller giữ `cheriot_ex_err_info` và `cheriot_wb_err_info`, sau đó đổi thành
  `ExcCauseCheriFault` cùng mã `mtval`.

Phân tách này giúp precise exception nhưng khiến debug cần theo tín hiệu qua
nhiều stage.

## 13. Runtime mode safety

RTL assertion yêu cầu `cheriot_enable_i` chỉ chuyển từ Off sang On và giữ On tới
reset. Lý do chính là RF storage `rf_shared` đổi ý nghĩa giữa x16..x31 và
capability metadata x0..x15. Chuyển ngược sẽ diễn giải metadata thành GPR data.

Encoding MuBi không hợp lệ đưa vào major internal alert.

## 14. Tín hiệu nên xem

```text
alu_operator_ex, alu_operand_a_ex, alu_operand_b_ex
result_ex, alu_adder_result_ex, ex_valid
branch_decision, branch_target_ex_rv32
mult_en_ex, div_en_ex, multdiv_valid, imd_val_q_ex
cheriot_enable_i, instr_is_cheriot_id
rf_rdata_a/b, rf_rcap_a/b
cheriot_operator, cheriot_ex_valid, cheriot_ex_err
pcc_cap_r, pcc_cap_w
cheriot_branch_req, branch_target_ex_cheriot
lsu_is_cap, lsu_cheriot_err
```

## 15. Điểm vào source

- [`rtl/ibex_ex_block.sv`](../../../rtl/ibex_ex_block.sv)
- [`rtl/ibex_alu.sv`](../../../rtl/ibex_alu.sv)
- [`rtl/ibex_multdiv_fast.sv`](../../../rtl/ibex_multdiv_fast.sv)
- [`rtl/ibex_multdiv_slow.sv`](../../../rtl/ibex_multdiv_slow.sv)
- [`rtl/ibex_cheriot_ex.sv`](../../../rtl/ibex_cheriot_ex.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../rtl/ibex_cheriot_pkg.sv)

