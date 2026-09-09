# 13 — Open questions và assumption register

BASE-01, ngày 2026-09-08. Tất cả owner bên dưới là **vai trò đề xuất, chưa chỉ định cá nhân**. Không có waiver mới hay rủi ro được người dùng chấp thuận. OPEN không đồng nghĩa một defect đã được xác nhận.

| ID | Câu hỏi / loại | Impact | Bằng chứng hiện tại / giả thuyết | Điều kiện đóng | Owner đề xuất | Status |
|---|---|---|---|---|---|---|
| OQ-01 | Có build/elaboration/run active nào cho BASE-01? TOOL-LIMITATION | HIGH — chặn xác nhận cấu hình/behavior | FuseSoC/simulator không có trong PATH | Tool versions, expanded filelist, parameter/hierarchy dump, baseline ELF/run/log | Build/DV maintainer | OPEN |
| OQ-02 | BaseIsa/RegFile/RV32ZC đi từ named config tới sim/DV top bằng cơ chế nào? CONFIGURATION-GAP | HIGH — ISA/topology có thể khác ý định | Simple manifest thiếu BaseIsa; UVM macro BaseIsa/RegFile khác tên consumer, RV32ZC không được forward; EVD-09 | Review option→define→parameter; chạy cả RV32I/dual và ZC variants, lưu hierarchy | Build + RTL maintainer | OPEN |
| OQ-03 | Consumer nào còn dùng src_files.yml/ibex_core.f? STALE-INPUT | MEDIUM | Ba path thiếu; danh sách ngắn không đủ core hiện tại | Tìm consumer CI/external; sửa hoặc deprecate có chủ đích; compile target liên quan | Build maintainer | OPEN |
| OQ-04 | Reset release, IRQ/debug/key/bitmap clock có đáp ứng boundary? MISSING-EVIDENCE | HIGH — wakeup/RDC | Generic gate cần enable synchronous; top không tự xác nhận CDC | Integration timing contract, CDC/RDC, reset-active transaction scenarios | Integrator | OPEN |
| OQ-05 | Các assertion thực sự có hoạt động trong build? CHECKER-GAP | HIGH — pass có thể không kiểm gì | VERILATOR/SYNTHESIS chọn dummy macro | Preprocess, checker activation/trigger/negative run ở tool đã chọn | DV maintainer | OPEN |
| OQ-06 | CHERIoT/trvk có spec/model/harness phù hợp không? MISSING-EVIDENCE | HIGH | Simple buộc mode/tag off; formal chọn RV32I | Tagged-memory/bitmap harness, ISA revision, legal/error/revoked tests + checker độc lập | CHERIoT + DV maintainer | OPEN |
| OQ-07 | Có được đổi cheriot_enable khi pipeline/giao dịch chưa drain? INTEGRATION-ASSUMPTION | HIGH | RF storage shared; CTX states kiểm runtime mode; chưa thấy protocol chuyển mode tại top | Chốt trusted control, quiescence/reset/state migration, tests switch với pending state | Architect/integrator | OPEN |
| OQ-08 | Secure/cache backend và key renewal hoạt động thế nào ở target chọn? MISSING-EVIDENCE | HIGH khi chọn opentitan | Simple key_valid=0; top boot có default key, renewal cần external service | Cache invalidate/key request test, ECC/lockstep injection, backend/constraints | Security/DV integrator | OPEN |
| OQ-09 | Formal assumptions/lemmas/vacuity có phù hợp baseline mới? MODEL-SCOPE | HIGH cho claim proof | RV32I only, no bus error/NMI/fast/debug; Live comment out | Exact generated model, assumptions, engine/bounds, covers, proof reports + discharge | Formal maintainer | OPEN |
| OQ-10 | SRAM instruction aliases, collision và timer semantics phù hợp sản phẩm? CONTRACT | MEDIUM | Instruction index bỏ upper addr; timer sticky IRQ, compare write kể cả BE=0 clear IRQ | Product memory contract; directed RTL tests; HW/SW review | SoC + firmware maintainer | OPEN |
| OQ-11 | Physical timing/power/test requirements nào áp dụng? MISSING-EVIDENCE | HIGH cho deployment | Có synthesis Tcl/SDC nguồn, không có applied report | Libraries/corners/netlist, clock/exception matching, timing/CDC/DFT reports | Implementation owner | OPEN |
| OQ-12 | Grant/response order, bounded service và reset cancellation được enforce ở đâu? INTEGRATION-ASSUMPTION | HIGH | Bus demo chỉ one-cycle; TRVK hai word liên tiếp và bitmap response sau grant | Protocol assertions/monitor, reset epochs, stall/error/unsolicited response tests | Bus/DV integrator | OPEN |

## Assumptions dùng trong lập luận

| ID | Điều kiện giả định | Source/điểm kiểm | Bên phải bảo đảm | Nếu sai / revisit |
|---|---|---|---|---|
| ASM-CFG-01 | Không có override/config ngoài snapshot trong phân tích intent | Baseline env/YAML; chưa elaborate | Build owner | Topology đổi; OQ-01/02 |
| ASM-BUS-01 | Input synchronous; req/payload giữ tới grant; đúng một in-order response mỗi accepted request, response muộn ít nhất một cycle | LSU protocol local docs, transaction monitor dự kiến | Memory subsystem | Sai metadata/response association; OQ-12 |
| ASM-BUS-02 | Simple bus devices response đúng một cycle, không stall device request | bus.sv contract và RAM/timer/simctrl equations | Integrator của bus mẫu | Response select có thể bị ghi đè; OQ-12 |
| ASM-RST-01 | Reset assert đủ, release đáp ứng recovery/removal, downstream hủy hoặc drain response cũ cùng epoch | Top/core async reset; chưa CDC/RDC | Clock/reset + interconnect | Stale response lọt sang epoch mới; OQ-04/12 |
| ASM-CAP-01 | Tagged capability load trả pointer rồi metadata, không chen response khác | trvk.sv comment/ptr state | LSU + tagged memory | Bitmap lookup gắn nhầm capability; OQ-06/12 |
| ASM-CAP-02 | Heap base ổn định/aligned; bitmap đúng nội dung; không có unsolicited response; service eventually | TRVK assertions/one outstanding | Trusted bitmap service | Stall, tag sai hoặc loss; OQ-06/12 |
| ASM-MODE-01 | Mode control trusted và ổn định trong instruction/giao dịch, switch theo protocol được thiết kế | Sharing RF, LSU mode guards | Platform control | Architectural state/capability sai; OQ-07 |
| ASM-LIVE-01 | Clock tiếp tục khi cần và môi trường cuối cùng grant/respond | Không có timeout core/TRVK | Integrator | Không có liveness/bound vô điều kiện; OQ-04/12 |

Những assumption này dùng để **giới hạn lập luận**, chưa được chấp nhận như yêu cầu sản phẩm hoặc chứng minh tại integration. Formal dùng giả định riêng cụ thể hơn trong Stage 11, không tự động discharge các assumption trên.

## Quy trình cập nhật

Khi đóng OQ phải thêm EVD, baseline/config, người review và những finding bị ảnh hưởng; không xóa câu hỏi lịch sử. `ACCEPTED-LIMITATION` chỉ dùng khi có decision owner thực sự chấp nhận phạm vi/hậu quả và trigger kiểm lại. Phiên này không tạo trạng thái đó để thay cho một câu trả lời chưa có.
