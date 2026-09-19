# 09 — Deep dive `ibex_controller`

## 1. Contract

Controller serialization point cho normal execution, redirect, exception,
interrupt, debug và sleep. Nó không tính ALU result nhưng quyết định result có
được commit và PC/state chuyển hướng ra sao.

## 2. FSM states

| State | Core action |
|---|---|
| `RESET` | disable request, set boot selection |
| `BOOT_SET` | request fetch và initialize boot PC |
| `FIRST_FETCH` | chờ ID sẵn sàng/instruction đầu |
| `DECODE` | normal run và event arbitration |
| `FLUSH` | trap/return/WFI serialization |
| `IRQ_TAKEN` | save cause/PC và redirect interrupt |
| `DBG_TAKEN_IF` | debug entry lấy IF PC |
| `DBG_TAKEN_ID` | EBREAK/debug entry lấy ID PC |
| `WAIT_SLEEP` | halt/flush trước gate clock |
| `SLEEP` | busy low, chờ wakeup |

Default illegal state quay `RESET`; assertion giới hạn state encoding.

## 3. Event latching

Fault pulses được latch qua `_q/_d`: fetch/illegal/ECALL/EBREAK, load/store,
CHERIoT EX/WB/ASR. Điều này cho phép chờ WB older instruction mà không mất cause.
Priority qualifiers (`*_prio`) chọn đúng một cause trong FLUSH.

## 4. DECODE arbitration

Priority operational:

1. instruction đang chạy/multi-cycle và fault của nó;
2. debug request/single-step;
3. interrupt.

`special_req` giữ ID và halt IF. Controller chờ `ready_wb` hoặc WB exception để
đảm bảo older WB fault thắng younger ID event.

**Invariant I-CTRL-01:** Architectural event trẻ hơn không được vượt qua pending
fault/side effect của instruction già hơn.

## 5. Branch/jump

Trong DECODE, PC mux được preselect `PC_JUMP` cho timing. `pc_set` chỉ assert khi
branch taken/jump/CHERIoT branch và predictor chưa đã redirect. Not-taken
mispredict phát correction address riêng.

Branch event không dùng FLUSH state như exception; IF redirect/squash trực tiếp
theo stage protocol.

## 6. Exception FLUSH

FLUSH halt IF và clear ID. Nếu exception:

- PC mux = exception/debug-exception;
- chọn EPC từ ID hoặc WB;
- save cause/mtval;
- select precise cause priority;
- CHERIoT fault có packed detail trong mtval.

Nếu không exception, FLUSH xử lý MRET, DRET hoặc WFI.

## 7. Interrupt selection

`handle_irq` xét qualified IRQ, global enable, NMI và debug/NMI states. Cause
priority: external/internal NMI, fast (priority encoder), external, software,
timer. ID/WB phải drain trước `IRQ_TAKEN`.

IRQ state save IF PC đại diện instruction kế tiếp chưa thực thi. NMI sets
`nmi_mode` và recoverable-NMI CSR stack policy.

## 8. Debug entry

`DBG_TAKEN_IF` dùng cho external debug/single-step boundary; `DBG_TAKEN_ID` dùng
cho EBREAK cần lưu address instruction. EBREAK priority có thể thắng simultaneous
debug request. Debug exception khi đã trong debug dùng dedicated vector.

## 9. Sleep

WFI qua FLUSH→WAIT_SLEEP→SLEEP. WAIT_SLEEP hạ `ctrl_busy`, dừng request và flush.
Top chỉ gate clock khi IF/LSU cũng idle. IRQ/debug/single-step làm state rời sleep
về first fetch.

## 10. Exception cause details

- Fetch bus/PMP: instruction access fault; `mtval=PC` hoặc `PC+2`.
- PCC tag/bounds: CHERIoT fault và capability index/reason.
- Illegal: compressed/full bits ở RV32, CHERIoT có policy mtval riêng.
- LSU bus/PMP: load/store access fault.
- CHERIoT LSU: misaligned hoặc capability fault theo error info.
- EBREAK: debug entry hoặc breakpoint exception.

## 11. Output controls

Quan trọng nhất: `instr_req_o`, `pc_set_o`, PC/exc mux, `flush_id_o`,
`controller_run_o`, CSR save/restore, debug/nmi state và performance events.

`halt_if` và `retain_id` được chuyển thành ID-ready/clear behavior; cần đọc cùng
logic cuối module, không suy state chỉ từ tên.

## 12. Assertions/coverage

- Valid controller states.
- Pipeline empty/safe trên IRQ entry.
- Debug/IRQ transition coverage.
- FLUSH event coverage.
- Correct CSR save source.
- No illegal side effects during flush.

## 13. Findings

- **Fact F-CTRL-01:** WB exception được ưu tiên trước younger ID special request.
- **Fact F-CTRL-02:** CHERIoT adds three distinct fault phases: fetch, EX, WB/ASR.
- **Inference I-CTRL-02:** Những bug khó nhất nằm ở simultaneous events hơn
  single event; L4 test matrix phải pairwise combine.
- **Open O-CTRL-01:** Verify exact wakeup cycle and saved PC under WFI+IRQ.

## 14. L4 handoff

Simultaneous matrices: branch+IRQ, load response error+debug, EBREAK+debug_req,
NMI+normal IRQ, WFI+pending IRQ, CHERIoT WB fault+younger illegal.

Signals: FSM current/next, special/fault latches, all priority bits, halt/retain/
flush, PC mux/set, CSR save controls, debug/nmi modes.

## 15. Source anchors

- [`rtl/ibex_controller.sv`](../../../../rtl/ibex_controller.sv)
- [`rtl/ibex_pkg.sv`](../../../../rtl/ibex_pkg.sv)

