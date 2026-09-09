# 10 — Module analysis index

BASE-01; tất cả tài liệu module là phân tích nguồn **COMPLETE-WITH-LIMITATIONS**, chưa elaborate/mô phỏng/prove. Invariant ghi SUPPORTED từ phương trình hoặc INFERRED từ lập luận không phải FORMAL:PROVED. Instance path là ứng viên đọc từ instantiation; active path còn OQ-01/02.

| Tài liệu | Instance/configuration ứng viên | Ưu tiên và lý do | Flows |
|---|---|---|---|
| [ibex_top](ibex_top.md) | `ibex_top`; small/dual/secure branches | P0 — boundary gate/ECC/lockstep/TRVK | BOOT, PWR, CAP, ERR |
| [ibex_fetch_fifo](ibex_fetch_fifo.md) | core.IF.gen_prefetch_buffer + fifo, ICache=0 | P1 — reservation, branch discard, alignment | BOOT, IF, ERR |
| [ibex_controller](ibex_controller.md) | core.ID.controller | P0 — precise trap, IRQ/debug/sleep | BOOT, IRQ, PWR, ERR |
| [ibex_id_stage](ibex_id_stage.md) | core.ID và WB, WB=0/1 | P0 — hazard và memory/commit ownership | LSU, CAP, ERR |
| [ibex_load_store_unit](ibex_load_store_unit.md) | core.LSU, RV32/dual | P0 — split request/response và metadata | LSU, CAP, ERR |
| [ibex_cs_registers](ibex_cs_registers.md) | core.CSR và PMP, mode/config phụ thuộc | P1 — privilege/PCC/IRQ software state | BOOT, IRQ, CAP, ERR |
| [ibex_register_file_ff](ibex_register_file_ff.md) | top.gen_regfile_ff, RegFileFF | P1 — shared state và mode switch | CAP, ERR |
| [ibex_cheriot_ex](ibex_cheriot_ex.md) | core.g_cheriot_ex, BaseIsa dual | P0 — authorization và capability result | CAP, ERR |
| [ibex_trvk](ibex_trvk.md) | top.gen_cheriot_trvk; NumOutstanding=2 | P0 — FIFO ownership, bitmap liveness/tag | CAP, LSU, ERR |
| [timer](timer.md) | Simple.u_timer, DataWidth32 | P1 — software/hardware race có thể quan sát | IRQ, PWR |

Bus được phân tích đủ FSM-less response routing/priority/latency tại Stages 5/7/9; không tạo file rỗng riêng. ALU/multdiv/cache/compressed decoder/lockstep numeric details chưa được chứng minh hoặc đọc toàn diện; đã inventory và mô tả ảnh hưởng boundary trong Stages 2–4/11/14. Khi đổi một opcode, cache controller, backend RF hoặc security implementation, phải thêm module analysis tương ứng và configuration-specific execution.
