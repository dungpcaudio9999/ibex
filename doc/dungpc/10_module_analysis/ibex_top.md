# Module — ibex_top

BASE-01; nguồn [ibex_top.sv](../../../rtl/ibex_top.sv), core, RF, lockstep, primitives. Mục đích: cung cấp IP boundary hoàn chỉnh quanh core, data/instruction ports, interrupts/debug, ECC sidebands, scan/gate, RAM config, key interface và revocation bitmap.

## Cấu trúc và state

BaseIsa chọn TRVK/bypass và capability paths; RegFile chọn FF/FPGA/latch; ICache tạo RAM; SecureIbex kéo theo lockstep và những cấu hình hardening. MemECC default đi theo SecureIbex nhưng là parameter riêng. `MaxOutstandingDSideAccesses=2`; không dùng default4 của module TRVK làm capacity top.

Main core dùng register data không ECC ở đường nội bộ chính theo wiring; shadow/checking paths có ECC widths phù hợp. `REGCAP_W=35`, top `RegFileCapEccWidth=REGCAP_W+7=42`; mọi thay đổi cap_t phải kiểm lại vector pack/unpack và lockstep. Không suy ra cả hai core có cùng widths chỉ từ tên module.

State: root-clock core_busy; scramble_key/nonce/valid/request; RF; cache RAM; lockstep input/output delay và compare-enable khi chọn secure. Architectural state phần lớn thuộc core/RF, request filtering state thuộc TRVK. Top không có timeout khôi phục bitmap hay external bus.

## Clock, reset, error

Generic gate chốt enable khi clock thấp; IRQ/debug/NMI có đường ungated ảnh hưởng clock_en. Core reset dùng rst_ni; scan và shadow reset cần review secure-specific. Scramble state reset nạp `RndCnstIbexKey/Nonce`, key_valid=1; do đó `scramble_key_valid_i=0` ở Simple **không đủ để kết luận boot luôn kẹt**. Sau khi invalidate tạo yêu cầu key mới, external service không phản hồi có thể làm request tồn tại; OQ-08.

TRVK bitmap integrity/device errors đi vào top alert_major_bus cùng core/lockstep bus alerts; metadata revoked làm giảm validity, không trực tiếp đổi downstream payload. Simple bỏ ngỏ alert outputs nên không là error-monitoring system.

## INV-top-01 — Giới hạn response tracking

Statement: external data response phải có accepted request thuộc cùng epoch; nhiều nhất hai word accesses đang pending tại top. Đây là contract và assertion target, chưa proof. Source checker `MaxOutstandingDSideAccessesCorrect`, `PendingAccessTrackingCorrect` dưới phần instrumentation; assumptions ASM-BUS-01/RST-01/CAP-01. Cần cover hai grants trước first response và response+grant cùng cycle; reset phải hủy pending cả hai đầu. OQ-05/12.

## Trade-off và change impact

Clock gating giảm switching theo thiết kế nhưng thêm boundary wakeup; lockstep đổi observation timing và reset/control width; RF/ECC thay bus payload cost; TRVK tăng response buffering và dependency bitmap. Đây là reasoning cấu trúc, không phải PPA đo được.

Các corner quan trọng: test_en trong sleep, reset shadow offset, partial ECC corruption, illegal MuBi, key invalidation giữa fetch, BaseIsa dual dù runtime Off. Đổi BaseIsa/SecureIbex/REGCAP_W/bitmap width cần retest top/core/RF/LSU/tracer/DV/formal/config và generated primitives; không chỉ lint một module. Flows BOOT/PWR/CAP/ERR; FND-CLK-01/CHERI-01, OQ-01/04/06/08/11.
