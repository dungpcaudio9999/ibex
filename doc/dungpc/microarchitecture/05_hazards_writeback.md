# 05 — Hazard, forwarding và writeback

## ID FSM không đồng nhất với việc có stall

SOURCE — [ID FSM](../../../rtl/ibex_id_stage.sv#L870): FIRST_CYCLE có thể kéo
dài nếu instruction chưa được phép execute. MULTI_CYCLE biểu diễn operation cần
nhiều bước, không phải tên chung cho mọi lý do chờ.

| Trigger ở FIRST_CYCLE | WB0 | WB1 |
|---|---|---|
| Load/store | Luôn sang MULTI_CYCLE | Chỉ sang nếu `~lsu_req_done` |
| Mult/div chưa `ex_valid` | Giữ RF write off, stall, sang MULTI_CYCLE | Tương tự |
| Branch taken, BTALU=0 | Thêm cycle tính target | Tương tự |
| Jump, BTALU=0 | Thêm cycle cho target/link | Tương tự |
| ALU multicycle | Giữ RF write off, sang MULTI_CYCLE | Tương tự |

Trong MULTI_CYCLE, trở lại FIRST_CYCLE khi `multicycle_done & ready_wb`.
`stall_wb` tách khỏi OR `stall_id`, vì nó mô tả backpressure của consumer.

## WB0: RF đã cập nhật trước instruction sau

Không có forwarding từ một stage WB đăng ký; instruction ALU ghi RF khi kết
thúc ID/EX. Instruction sau đọc giá trị mới sau cạnh lên.
Load/store stall cycle đầu, sau đó đến khi response:

```text
data_req_allowed = instr_first_cycle
stall_mem = instr_valid & is_memory & (~lsu_resp_valid | instr_first_cycle)
multicycle_done(memory) = lsu_resp_valid
```

`instr_first_cycle` ngăn phát một memory instruction lại trong các cycle chờ.
Request chưa grant được LSU giữ bằng FSM của nó; không cần ID liên tục tạo một
request mới. Split access vẫn có hai transaction hợp lệ.

## WB1: forwarding khác load-use interlock

SOURCE — [hazards](../../../rtl/ibex_id_stage.sv#L1015),
[WB mux](../../../rtl/ibex_wb_stage.sv#L182):

```text
match_A = (WB.rd == ID.rs1) & (ID.rs1 != 0)
hazard_A = match_A & rf_ren_A
forward_A = match_A & rf_write_WB ? registered_WB_result : RF.read_A
stall_ld_hz = outstanding_load_WB & (hazard_A | hazard_B)
outstanding_memory = (outstanding_load_WB | outstanding_store_WB) & ~lsu_resp_valid
instr_executing = valid_ID & ~instr_kill & ~stall_ld_hz & ~outstanding_memory
```

Forwarding lấy **registered arithmetic/capability result**, không lấy incoming
load data. Load data đến muộn; thêm đường đó vào ALU sẽ kéo dài combinational path.
Do `outstanding_load_WB` vẫn cao trong response cycle, dependent instruction
còn chờ cycle đó, rồi đọc RF ở cycle sau.

Instruction không phụ thuộc load có thể execute ngay response cycle nếu response
không lỗi. Trước response, ngay cả instruction độc lập cũng bị chặn bởi
`outstanding_memory`: memory access cũ có thể fault, cần giữ precise exceptions.
WB stage không tạo cửa sổ out-of-order execution.

## Speculative execution enable trong ID

`instr_executing_spec` bỏ một số điều kiện response/error của WB để phát control
branch sớm, tránh đường tổ hợp dmem-error→imem-request.
`instr_executing` là điều kiện đầy đủ cho architectural effects. Đây là cách tách
đường timing của control; không phải reorder buffer hoặc speculative retirement.

## Bảng load→use — INFERRED

Giả sử WB1, load được grant ở t, response ở t+3:

| Cycle | ID | WB | Lý do |
|---|---|---|---|
| t | Load: req_done, transfer | Trống | Address phase xong |
| t+1 | Dependent ADD chờ | Load pending | outstanding_memory + load hazard |
| t+2 | Dependent ADD chờ | Load pending | Như trên |
| t+3 | Dependent ADD vẫn chờ | Load response, RF write | load hazard vẫn cao |
| t+4 | ADD execute, transfer | WB nhận ADD | RF có load result |

Nếu ADD không phụ thuộc, t+3 có thể execute. Nếu response fault, ID bị kill và
controller flush; không ghi kết quả instruction trẻ.

## Ranh giới store và exception

Store data có thể tới memory khi grant, trước response và retirement. WB chờ
response để biết có exception; không có cơ chế rollback byte đã ghi ở memory.
Instruction younger bị chặn không biến split store thành atomic transaction.

SIM: `memory`, các `error_*`, các `event*` chạy WB0/WB1; trace ghi riêng
`stall_mem`, `stall_ld_hz`, `instr_done`, ready và response. Các bảng trích ở
[timing](10_timing.md) cho thấy load-use bubble và completion boundary.

Invariants cần giữ khi sửa RTL: rd=0 không tạo hazard; data/cap forwarding cùng
register identity; memory metadata cũ không bị overwrite trước response; WB fault
thắng side effect của ID trẻ. Các run hiện tại hỗ trợ các ca đã kích hoạt,
chưa formal hóa invariant cho mọi chuỗi instruction.
