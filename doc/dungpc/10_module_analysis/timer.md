# Module — timer

BASE-01; [source](../../../shared/rtl/timer.sv), Simple.u_timer, DataWidth=32. Trách nhiệm: 64-bit mtime/compare, byte-masked MMIO và sticky timer interrupt trên root clock. Không có FSM nhiều trạng thái, không có ready/gnt tại slave interface.

## State và equations

mtime_q tăng1 modulo2^64 mỗi cycle, trừ half được ghi sẽ merge bytes từ old half; half không được ghi vẫn lấy mtime_inc. mtimecmp_q chỉ đổi khi write half được decode. IRQ q giữ tới compare-write clear. mtime/compare/IRQ/rvalid reset0 asynchronous; rdata/error không reset nhưng chỉ có nghĩa khi rvalid.

`rvalid_next=timer_req`; `timer_we=timer_req & timer_we_i`; address decode10 low bits chọn offsets0/4/8/12. Request write là side-effect event dù không có data BE bật. Vì write-enable decode không AND any-BE, compare write BE=0 vẫn clear IRQ mà không đổi compare data. FND-TMR-01.

## INV-timer-01 — Clear priority

Khi `mtimecmp_we | mtimecmph_we`, IRQ next=0 bất kể compare hay old IRQ. SUPPORTED từ phương trình RTL. Cạnh sau compare lại lấy state trước cạnh đó, có thể set IRQ. Ghi mtime thấp hơn compare không clear old IRQ. Đây không là combinational `irq=(mtime>=cmp)` timer.

Ví dụ trạng thái trước cạnh: mtime151, compare100, irq1; ghi mtime low0/all BE → mtime0, compare100, irq1. Python model EVD-06 đã quan sát recurrence này; negative comparison EVD-07 cố tình lật observed irq tại cạnh đó và exit1. **Đây là model execution, không compile/run module timer.**

## Corner và latency

Read request chốt pre-edge value, response sau một cycle; đọc low/high riêng có race rollover, software dùng high-low-high. So sánh interrupt dùng old mtime nên IRQ không nhất thiết cùng post-edge thời điểm counter mới chạm compare. Reset mtimecmp0 gây IRQ ở first active edge, mie CPU vẫn0.

Partial mtime write khi low half carry lên high, write compare khi đang IRQ, BE0, invalid offset và reset mid-response cần directed RTL tests. Access invalid vẫn response+error; không có timeout hoặc held ready logic.

## Rationale và change impact

Sticky IRQ tránh mất event khi software điều chỉnh counter nhưng làm clear contract khác timer level thuần; đây là interpretation nguồn, chưa có product decision. Nếu đổi sang level IRQ hoặc BE0 không-clear, phải cập nhật handler/driver assumptions, model stimulus/oracle, UVM tests và regressions compare multiword. Nếu đổi slave latency, bus demo phải đổi cùng lúc. OQ-01/10/12; FLOW-IRQ-01/PWR-01.
