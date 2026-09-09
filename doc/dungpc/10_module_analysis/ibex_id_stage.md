# Module — ibex_id_stage và writeback boundary

BASE-01; [ID](../../../rtl/ibex_id_stage.sv), [WB](../../../rtl/ibex_wb_stage.sv), decoder/ex_block/ALU/multdiv. Trách nhiệm: giữ instruction và operands khi multi-cycle, xử lý hazard, chỉ phát side effect khi được phép, chuyển result/destination/metadata đúng instruction tới RF/WB.

## State và datapath

ID FSM FIRST_CYCLE/MULTI_CYCLE phối hợp multdiv, branch/jump và LSU. ALU là datapath arithmetic/AGU; multiplier implementation chọn bởi RV32M; CHERIoT EX có result/cap/error path riêng. `stall_id` OR các stall_ld_hz, stall_mem, stall_multdiv, stall_jump, stall_branch, stall_alu. `instr_done=~stall_id & ~flush_id & instr_executing`; `en_wb_o=instr_done`.

WB khi bật lưu wb_valid, PC, rd/write enables, loại instruction, result, compressed/count metadata và CHERIoT flags/result/error; valid reset0, payload reset phụ thuộc ResetAll. `ready_wb=~wb_valid | wb_done`; `instr_done_wb=wb_valid & wb_done`. LSU read/error completion ảnh hưởng wb_done/perf retirement. Architectural result bus không được lấy từ payload khi valid=0.

Khi không có tầng WB, WB module chọn nhánh passthrough, ready=1, các outstanding-WB indicators=0. ID vẫn stall memory cycle đầu và tới response. Không diễn giải “không WB stage” thành “không có module/writeback logic”.

## Hazard và ownership

WB path đặt `outstanding_memory_access=(outstanding_load_wb|outstanding_store_wb) & ~lsu_resp_valid`; `data_req_allowed=~outstanding_memory_access`. Vì vậy architectural memory instruction không tùy ý overwrite LSU response metadata trước completion. Split instruction vẫn có nhiều bus words.

ALU/CHERIoT results có forwarding từ registered WB result; matching rd/read ports loại x0. Load data tới muộn nên ID dùng `stall_ld_hz`, không giả định forward memory rdata trực tiếp cùng cycle vào critical EX path. CHERIoT EX nhận data/cap forwarding riêng, cần kiểm cả hai cùng architectural register identity.

## Invariants và latency

`INV-id-01`: instruction stalled/killed không được phát lặp một architectural load request sau khi request đã accepted. INFERRED end-to-end; nguồn có `IbexStallMemNoRequest`, `instr_executing`, `lsu_req_done`, busy/WB guards. Cần scoreboard đếm accepted requests và biết split-count; assertion phát request=0 mọi khi stall là quá mạnh và sai cho ongoing split.

`INV-wb-01`: younger instruction không commit khi older WB exception cần flush. INFERRED, dựa instr_kill/wb_exception và controller ordering. Kiểm RVFI/order cùng architectural side effects, không dùng riêng `rf_we_wb_o` như retirement (RF write có thể khác event count).

CPI phụ thuộc instruction mix/memory. BranchTargetALU giảm nhu cầu dùng lại main ALU cho target (rationale từ source), WB cho overlap nhưng có load-use hazard. Không có CPI/Fmax đo được. Corner: back-to-back loads, load→dependent branch, zero register, CHERIoT result+error, IRQ giữa expanded Zcmp commit, illegal decode với pending memory.

## Change impact

Đổi WB hoặc ALU latency phải cập nhật ID FSM, LSU req_done/resp_valid interpretation, RF forward/data-cap pairing, controller trap PC, counters/RVFI và DV/ISS. Regression cả WB0 và WB1, delayed response, same-cycle completion/new-request, exception suppression. Không áp dụng property proof của một cấu hình sang cấu hình khác. OQ-01/05/06/09/12.
