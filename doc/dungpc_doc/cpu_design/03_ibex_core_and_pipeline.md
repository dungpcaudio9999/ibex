# 03 — `ibex_core` và tổ chức pipeline

## 1. Vai trò của `ibex_core`

`ibex_core` là điểm nối trung tâm của pipeline. Module này không chứa một FSM
khổng lồ duy nhất; nó kết nối các FSM phân tán:

- IF quản lý fetch và IF/ID register;
- ID/controller quản lý issue, stall, flush và event;
- MUL/DIV quản lý multi-cycle execution;
- LSU quản lý request/response;
- WB quản lý retirement và pending memory operation;
- CSR quản lý architectural privileged state.

Vì vậy một lệnh bị “kẹt” phải được chẩn đoán qua handshake giữa nhiều module,
không chỉ nhìn controller state.

## 2. Pipeline cấu hình được

### 2.1 Khi `WritebackStage=1`

```text
       IF                   ID/EX                         WB
 fetch/decompress  -> decode/read RF/execute -> hold result/await LSU/retire
       |                       ^  |                        |
       +---- PC redirect -------+  +---- forwarding ------+
```

Đây là pipeline ba tầng logic. “ID/EX” thực hiện decode, đọc RF và phần lớn EX
trong cùng một stage; ALU không có pipeline register riêng phía trước.

### 2.2 Khi `WritebackStage=0`

`ibex_wb_stage` vẫn tồn tại trong hierarchy nhưng hoạt động như passthrough.
Không có forwarding WB→ID và một load/store thường giữ ID cho đến response.

Các cấu hình `opentitan` và FX1 trong worktree đều đặt `WritebackStage=1`.

## 3. Các bundle liên tầng quan trọng

### 3.1 IF → ID

- `instr_valid_id`, `instr_new_id`;
- instruction 32-bit sau giải nén và instruction compressed gốc;
- `pc_id`;
- fetch/bus/PMP/CHERIoT fault bits;
- metadata Zcmp expansion;
- dummy-instruction marker.

`instr_valid_id` là ownership bit của IF/ID register. ID chỉ được phép thực thi
khi bit này hợp lệ và controller không kill lệnh.

### 3.2 ID → EX

- ALU operator và hai operand;
- branch-target operands;
- MUL/DIV operator, signed mode và operands;
- intermediate registers `imd_val_q_ex[2]` cho multi-cycle operation.

### 3.3 EX → ID/IF

- `result_ex`;
- `alu_adder_result_ex` làm địa chỉ LSU;
- `branch_decision`;
- RV32/CHERIoT branch target;
- `ex_valid` báo multi-cycle result hoàn tất.

### 3.4 ID → WB

- write address/data/enable;
- loại lệnh `LOAD`, `STORE` hoặc `OTHER`;
- PC và compressed marker;
- CHERIoT data/capability result;
- retire-counter eligibility.

### 3.5 WB → ID

- destination register;
- forwarded data/capability;
- `rf_write_wb`;
- `outstanding_load_wb`, `outstanding_store_wb`;
- `ready_wb`.

Đây là vòng back-pressure chính của pipeline ba tầng.

## 4. Quy tắc advance và back-pressure

Một instruction trong ID/EX chỉ hoàn tất khi:

```text
instr_done = instr_executing && !stall_id && !flush_id
```

`stall_id` là hợp của:

- load-use hazard;
- memory operation chưa đủ điều kiện tiến;
- MUL/DIV chưa valid;
- branch/jump cần thêm chu kỳ;
- ALU bitmanip multi-cycle;
- WB không sẵn sàng.

Khi lệnh hoàn tất, `en_wb` đưa metadata/result sang WB. IF chỉ ghi instruction
mới vào IF/ID register khi `id_in_ready` cho phép và không có PC redirect cần
flush dữ liệu vừa fetch.

## 5. Luồng một lệnh ALU bình thường

Với branch target ALU và WB đều bật:

1. IF nhận response, giải nén và ghi instruction + PC vào IF/ID.
2. Decoder chọn ALU op, RF addresses, immediates và writeback destination.
3. RF đọc tổ hợp; mux forwarding có thể thay giá trị từ WB.
4. `ibex_alu` tạo result trong chu kỳ ID/EX.
5. `instr_done` và `en_wb` lên nếu không stall/flush.
6. WB lưu result/destination.
7. Chu kỳ sau WB ghi RF và phát retire pulse.

Trong steady state, một lệnh có thể retire mỗi chu kỳ dù latency từ fetch đến
retire dài hơn một chu kỳ.

## 6. Luồng load

1. ID/EX dùng ALU adder tính effective address.
2. LSU phát address phase; instruction có thể chuyển sang WB khi request phase
   đã hoàn tất (`lsu_req_done`).
3. WB giữ ownership của load bằng `outstanding_load_wb`.
4. Response LSU đi trực tiếp tới RF write mux.
5. `lsu_resp_valid` kết thúc WB; error sẽ ngăn retire bình thường và kích hoạt
   exception flow.

Nếu lệnh kế tiếp đọc cùng destination trong khi load chưa trả data, forwarding
không đủ vì data về quá muộn; ID phát `stall_ld_hz`.

## 7. Luồng branch và redirect

RV32 branch target đến từ `ibex_ex_block`; CHERIoT branch target đến từ
`ibex_cheriot_ex`. Core mux hai đường theo instruction hiện tại:

```text
branch_target_ex = instr_valid_id && instr_is_cheriot_id
                 ? branch_target_ex_cheriot
                 : branch_target_ex_rv32
```

Controller quyết định `pc_set`, `pc_mux` và clear IF/ID. IF biến chúng thành
request redirect. `BranchTargetALU=1` tách target addition khỏi ALU chính, giảm
stall cho jump/branch.

## 8. Exception phải chính xác

Với WB stage, một exception trẻ hơn không được vượt qua lệnh memory cũ hơn đang
ở WB. Controller giữ hoặc flush theo thứ tự để architectural state phản ánh tất
cả lệnh cũ hơn và không phản ánh lệnh gây lỗi.

Ba nhóm tín hiệu cần xem cùng nhau:

- yêu cầu exception ở ID/controller;
- `outstanding_*_wb` và LSU error response;
- `csr_save_if/id/wb`, `csr_save_cause`, `pc_set`.

## 9. Busy và sleep nhìn từ core

- `if_busy`: prefetch/cache còn hoạt động;
- `lsu_busy`: LSU FSM không idle;
- `ctrl_busy`: controller chưa ở trạng thái cho phép sleep.

`core_busy_o` là hợp được mã hóa MuBi. WFI chỉ làm controller đi qua
`WAIT_SLEEP -> SLEEP` sau khi giao dịch ngoài pipeline đã drain.

## 10. Biên RVFI

Khi `RVFI` được define, core thu thập PC, register operands/result, memory
operation, trap/interrupt và capability metadata. Đây là quan sát kiến trúc tại
điểm retirement, không phải bản sao trực tiếp mọi tín hiệu pipeline.

Khi debug khác biệt Spike:

1. xác định instruction nào có `rvfi_valid` đầu tiên bị sai;
2. kiểm tra PC/insn và source operands;
3. xác định sai ở EX, memory hay CSR;
4. mới truy ngược vào stage tương ứng.

## 11. Checklist waveform mức core

Tập tín hiệu tối thiểu:

```text
pc_if, pc_id, pc_wb
instr_valid_id, instr_first_cycle_id, instr_id_done
id_in_ready, instr_valid_clear
stall_id, stall_wb, stall_ld_hz, stall_mem, stall_multdiv
pc_set, pc_mux_id, branch_target_ex, branch_decision
en_wb, ready_wb, instr_done_wb
lsu_req, lsu_req_done, lsu_resp_valid
rf_raddr_a/b, rf_waddr_wb, rf_we_wb
rvfi_valid, rvfi_order, rvfi_insn
```

## 12. Điểm vào source

- [`rtl/ibex_core.sv`](../../../rtl/ibex_core.sv)
- [`rtl/ibex_pkg.sv`](../../../rtl/ibex_pkg.sv)
- [`pipeline timing chi tiết`](../12_pipeline_timing.md)

