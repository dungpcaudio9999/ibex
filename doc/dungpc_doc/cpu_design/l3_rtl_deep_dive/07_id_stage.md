# 07 — Deep dive `ibex_id_stage`

## 1. Contract

ID stage là nơi instruction giữ ownership lâu nhất. Nó kết hợp decode,
controller, RF operands, forwarding, immediate/operand mux, issue qualification,
multi-cycle sequencing và handoff sang WB.

## 2. Data/control separation

`ibex_decoder` tạo raw intent (`*_dec`). `ibex_controller` tạo run/flush/event
control. ID chỉ phát side effect sau khi intent được qualify bởi
`instr_executing`.

Ví dụ:

```text
lsu_req = instr_executing ? data_req_allowed && lsu_req_dec : 0
csr_op_en = csr_access && instr_executing && legality conditions
rf_we_id = rf_we_raw && instr_executing && !illegal_csr
```

**Invariant I-ID-01:** Stall hoặc retained instruction không được lặp side effect
của first cycle.

## 3. Immediate and operand muxes

Operand A sources: RF A, previous LSU address, current PC, immediate A. Operand
B: RF B hoặc immediate. Immediate selectors bao phủ I/S/B/U/J, PC increment và
address increment.

Separate BT operands cho branch-target adder. RF data forwarding áp dụng trước
operand mux; CHERIoT capability forwarding nằm trong CHERIoT EX.

## 4. ID FSM

Hai states:

| State | Meaning |
|---|---|
| `FIRST_CYCLE` | instruction chưa phát hoặc đang phát first-cycle work |
| `MULTI_CYCLE` | operation đã bắt đầu và cần giữ instruction/control |

State update chỉ khi `instr_executing`, vì một instruction bị hazard có thể giữ
`FIRST_CYCLE` nhiều chu kỳ mà chưa thực thi.

Transitions vào multi-cycle:

- LSU request chưa đạt `lsu_req_done`;
- CHERIoT LSU tương tự;
- MUL/DIV chưa `ex_valid`;
- branch cần second cycle do DIT/no BT-ALU;
- jump khi không có BT-ALU;
- ALU multi-cycle operation.

Quay về first cycle khi `multicycle_done && ready_wb`.

## 5. Stall decomposition

```text
stall_id = ld_hazard | memory | multdiv | jump | branch | alu
stall_wb = en_wb && !ready_wb
instr_done = !stall_id && !flush_id && instr_executing
```

`stall_wb` tham gia `id_in_ready`/execution gating dù không nằm trong biểu thức
`stall_id` trên; phải xem cả hai khi waveform ID không advance.

## 6. Writeback-stage branch

Với WB enabled:

- RF address compare tạo A/B hazards;
- ALU/CSR result từ WB có thể forward;
- outstanding load với matching source tạo `stall_ld_hz`;
- outstanding memory op có thể tạo `stall_mem` để giữ precise ordering;
- ID có thể nhường load cho WB sau request phase, trước response.

Không WB:

- không forwarding/hazard với WB;
- LSU giữ instruction đến response;
- `ready_wb` constant one;
- expecting-load/store signals dùng để kiểm response.

Scope profiles đều dùng first branch.

## 7. Forwarding equations

Destination x0 không tạo match. Khi match và WB sẽ write, forwarded data thay RF
read. Nếu outstanding load chưa có data, không forward response combinational;
ID stall.

**Critical candidate:** WB destination/data → match/mux → ALU → result/enable.

## 8. Branch and jump sequencing

Branch compare đến từ EX trong cùng logical ID/EX stage. `branch_set_raw_d`
capture decision khi cần second cycle. DIT force branch dùng fixed pattern dù
taken/not-taken. Predictor correction chỉ meaningful khi parameter enabled.

Jump link data và target có thể cần shared ALU nếu no BT-ALU; named profiles có
BT-ALU nên branch-target addition song song.

## 9. Memory instruction classification

ID phân `WB_INSTR_LOAD/STORE/OTHER`. CHERIoT load/store signals còn phụ thuộc
permission/bounds result, nên WB nhận dedicated flags ngoài enum. Điều này ngăn
capability faulting operation bị xử lý như normal `OTHER` done quá sớm.

## 10. Controller interaction

`instr_valid_clear`, `id_in_ready`, `flush_id`, `controller_run`, special request
và exception state tạo vòng control. `instr_executing_spec` là early timing
signal; `instr_executing` thêm kill/WB conditions.

Assertions yêu cầu executing ⇒ speculative executing, và valid non-executing
phải có stall/kill reason.

## 11. CHERIoT decode handoff

ID xuất immediates, one-hot operator, field/adderr selectors, load/store flags và
`cheriot_exec_id`. Assertions buộc tất cả CHERIoT-only semantic outputs tắt khi
runtime mode không On.

## 12. Assertions and coverage

- transition first→multi phải stall ID;
- ID ready dẫn state về first cycle;
- one valid stall reason cho illegal instruction;
- operand selectors valid/known;
- duplicate instruction copies identical;
- hazard coverage;
- taken/not-taken branch coverage;
- CHERIoT isolation when disabled.

## 13. Findings

- **Fact F-ID-01:** `stall_id` không phải toàn bộ back-pressure; phải xét WB.
- **Fact F-ID-02:** Load forwarding cố ý không dùng returning memory data.
- **Inference I-ID-02:** Sửa `instr_executing_spec` có timing impact rộng vì nó
  đi vào early control; functional fix cần kiểm synthesis timing.
- **Open O-ID-01:** L4 cần simultaneous WB exception + younger special request.

## 14. L4 handoff

ALU dependency, load-use, WB full, MUL/DIV, taken branch DIT on/off, LSU request
delayed, flush first/multi-cycle và illegal instruction sau outstanding store.

Signals: ID FSM, all stalls, executing/spec, done, ready, RF matches/forwarded
operands, raw versus qualified enables.

## 15. Source anchors

- [`rtl/ibex_id_stage.sv`](../../../../rtl/ibex_id_stage.sv)
- [`rtl/ibex_decoder.sv`](../../../../rtl/ibex_decoder.sv)
- [`rtl/ibex_controller.sv`](../../../../rtl/ibex_controller.sv)

