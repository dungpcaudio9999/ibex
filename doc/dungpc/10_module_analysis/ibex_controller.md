# Module — ibex_controller

BASE-01; [source](../../../rtl/ibex_controller.sv), instantiated trong ID stage. Trách nhiệm: điều phối fetch/decode/stall/flush, exception/interrupt/debug entry, return và sleep. Đầu vào instruction status/LSU error/WB readiness/IRQ; đầu ra PC mux/set, CSR save/restore, halt/flush/busy.

## State và FSM

| State | Vai trò và transition chính |
|---|---|
| RESET | Không request, PC_BOOT; sang BOOT_SET |
| BOOT_SET | Fetch boot PC/init mtvec; sang FIRST_FETCH |
| FIRST_FETCH | Chờ IF/ID ready; có thể chuyển IRQ/debug |
| DECODE | Chạy instruction; branch/jump/multicycle và exception preparation |
| FLUSH | Commit trap/return/WFI side effects với priority; ngăn old instruction tiếp tục |
| IRQ_TAKEN | PC_EXC, CSR cause save, chọn NMI/fast/external/software/timer |
| DBG_TAKEN_IF / DBG_TAKEN_ID | Entry debug theo nguyên nhân/PC stage thích hợp |
| WAIT_SLEEP | Dừng fetch/flush ID, hạ busy; sang SLEEP |
| SLEEP | Duy trì halt; IRQ/debug/single-step wake về FIRST_FETCH |

Ngoài ctrl_fsm: debug_mode_q, nmi_mode_q, illegal/exception latches, debug cause, internal integrity IRQ state. Reset ctrl_fsm=RESET; flags được reset theo always_ff cuối module. Không có queue interrupt độc lập thay cho mọi external source; inputs phải giữ theo platform contract.

## Priority và architectural boundary

handle_irq loại debug mode, single step, nmi mode và `INSTR_EXPANDED_COMMIT`; IRQ thường thêm global privilege enable. `IRQ_TAKEN` có NMI trước fast; fast index nhỏ thắng. Debug và exception có đường priority khác ngoài bảng IRQ, không dùng thứ tự đó để suy ra mọi simultaneous exception/debug scenario.

PC source lưu trap phụ thuộc stage đang sở hữu instruction; với WB, older instruction lỗi có thể chặn younger ID instruction. Memory transaction accepted không tự rollback khi controller flush. `PipeEmptyOnIrq` ở nguồn là obligation về transition IRQ, chưa chạy.

## Invariants và dự đoán

`INV-controller-01`: vào IRQ_TAKEN không để instruction cũ có side effect chưa được quản lý tiếp tục qua trap boundary. INFERRED composition controller+ID/WB/LSU; kiểm PipeEmptyOnIrq và RVFI order/memory monitor. Assumptions in-order memory/reset, không tắt assertion. OQ-05/12.

`INV-controller-02`: SLEEP không phát instruction request; wake condition không đòi mstatus.MIE cùng cách với trap. SUPPORTED từ SLEEP outputs và irq_pending path, FND-CLK-01. Không chứng minh physical clock ngừng chỉ từ FSM.

Không có fixed trap latency: fetch stalls, multdiv và memory pending ảnh hưởng entry. Hai tầng/ba tầng và Zcmp expanded sequences thay commit boundary. Corner quan trọng: IRQ khi load error, debug+NMI, nested NMI return, ebreak trong debug, WFI khi mask/global-enable khác nhau và fault ở upper-half fetched instruction.

## Validation và ảnh hưởng thay đổi

UVM có debug/interrupt sequences và fault tests, formal protocol loại NMI/fast/debug ở harness đã đọc. Chưa chạy hoặc xác nhận antecedent coverage. Đổi FLUSH/priority cần regression WB0/WB1, Zcmp, LSU split, debug single-step và CHERIoT exceptions; so mepc/mcause/mtval/PCC và RF/memory side effects, không chỉ PC cuối. Flows BOOT/IRQ/PWR/ERR; OQ-01/04/05/09/12.
