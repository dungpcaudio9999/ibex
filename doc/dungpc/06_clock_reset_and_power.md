# 06 — Clock, reset, power và test

BASE-01. Bằng chứng nguồn: [top gate](../../rtl/ibex_top.sv#L302), [generic gate](../../vendor/lowrisc_ip/ip/prim_generic/rtl/prim_clock_gating.sv), [controller sleep](../../rtl/ibex_controller.sv#L598), [CSR pending](../../rtl/ibex_cs_registers.sv#L1045). Không có CDC/RDC/STA report.

## Domain và modes

| Clock/reset | Nguồn/quan hệ | Consumers/modes | Điều biết được |
|---|---|---|---|
| `clk_sys` Simple System | VERILATOR nối IO_CLK; nhánh khác sinh clock bằng delay | RAM/bus/timer/top, boot và functional | Không gán tần số vật lý từ delay testbench |
| `clk_i` tại ibex_top | Root clock do integrator cấp | core_busy flops, hạ tầng top | Tần số/IO delay chưa có |
| `clk` nội bộ | Clock cùng nguồn qua `prim_clock_gating` | core/RF/TRVK và logic theo kết nối top | Related gated domain; không phải asynchronous PLL domain |
| `rst_sys_n` / `rst_ni` | Active-low external; nhiều always_ff có negedge reset | CPU, bus/timer, valid state | Async assertion ở RTL; synchronous release chưa được bảo đảm |
| `scan_rst_ni`, `test_en_i` | Top test inputs | Shadow/test/reset/clock overrides tùy secure | Simple buộc scan reset=1, test=0; scan/ATPG chưa chạy |

WFI, debug, interrupt, reset và secure lockstep là những mode phải phân biệt. Không có power switch/isolation/retention domain được instantiate ở Simple System trong phạm vi đọc; power-gating implementation là NOT-APPLICABLE cho top mẫu này. Clock gating vẫn REQUIRED và physical power analysis NOT-RUN.

## FND-CLK-01 — Điều kiện wakeup và giới hạn core_sleep

**Support:** SUPPORTED [RTL:ESTABLISHED]. BASE-01, `ibex_top.sv:304–338`: nonsecure `clock_en=core_busy_q[0] | debug_req_i | irq_pending | irq_nm_i`; secure dùng so sánh đầy đủ `core_busy_q != IbexMuBiOff`. `core_sleep_o=~clock_en`.

Generic gate giữ `en_i | test_en_i` bằng latch khi clock thấp rồi AND với clock. Vì test enable có thể mở gate dù clock_en=0, `core_sleep_o` không phải phép đo clock đã ngừng, đặc biệt trong test mode. Đó cũng không phải tín hiệu cho phép tắt nguồn ngay lập tức. Thời điểm gating còn qua latch và root-clock sampling của core_busy.

CSR tạo `mip` trực tiếp từ IRQ và `irq_pending_o=|(mip & mie_q)` bằng combinational logic để có thể wake khi clock core đã tắt. `mstatus.MIE` ảnh hưởng nhận trap, không phải cùng điều kiện với wakeup. Timer thuộc root domain nên tiếp tục chạy khi CPU sleep. [RTL:ESTABLISHED; FLOW-PWR-01]

## Crossing và giả định

| Crossing | Payload/điều kiện | Cơ chế thấy ở nguồn | Bằng chứng còn thiếu |
|---|---|---|---|
| IRQ/debug external → clock enable/controller | Level/wakeup, cần ổn định đủ để xử lý | Top dùng trực tiếp; không được xem gate latch là synchronizer | ASM-RST-01/ASM-LIVE-01; CDC/timing và event capture |
| Root memory/bus → gated core/TRVK | response không có ready; core phải còn clock khi outstanding | busy/control giữ hoạt động theo thiết kế | Active transaction → WFI/reset tests, không mất response |
| External reset → root/gated/shadow state | Assert/release và transaction epoch | Asynchronous reset tại nhiều state regs | Recovery/removal, synchronous release và partial reset behavior |
| External key/nonce/valid → scramble registers | Multi-bit coherent payload/valid | Top chốt khi key_valid | Domain/source protocol, OQ-08 |
| Bitmap → TRVK | data/intg/err và pulse rvalid | Giao diện synchronous giả định, không async FIFO | Domain/ordering/response duration do integrator bảo đảm |

Chưa có clock domain setup trong tool hoặc constraints-match report. Việc source chỉ có một input clock không miễn kiểm tra IRQ/reset asynchronous và giao dịch root↔gated. Không có cơ sở cho MTBF hay “CDC safe”.

## Reset, state không reset và recovery

Controller reset về RESET; các valid/outstanding/discard/LSU/TRVK state về rỗng/idle; timer mtime/compare/IRQ về 0. Prefetch/FIFO payload/address tùy `ResetAll`; ở nonsecure có registers không reset, được che bằng valid và khởi tạo qua boot redirect. Không kết luận power-up value của storage chưa reset hoặc RAM không có init file là zero.

Reset local hủy obligation trong state machine. Nếu memory/bitmap không reset đồng bộ epoch mà trả response của request trước reset, state mới có thể nhận response không còn metadata. Phải drain hoặc thống nhất cancellation, không chỉ assert reset core rồi tiếp tục nhận bus cũ. OQ-04/12.

Trong lockstep, offset/reset sequencing/scan và compare-enable làm thêm state/delay; chưa chứng minh shadow alignment, reset fault hoặc width/ECC coverage. Xem module top/security và OQ-08.

## Timing/power constraints

`syn/tcl/flow_utils.tcl` sinh create_clock, input/output delay; `syn/ibex_top.nangate.sdc` đặt driving cell/load. Đây là input/ý định synthesis. Không có report clock objects, exception coverage, unconstrained paths, corners, lib/netlist provenance hay timing closure. Không đưa ra Fmax hoặc power số đo.

Không phát hiện power-switch protocol trong ranh giới Simple System đã chọn; nếu đem IP sang SoC nhiều power domains thì phải mở lại applicability isolation/retention/UPF. Scan/ATPG và debug transport ngoài top này không được bao phủ bởi functional analysis.

Stage 6 COMPLETE-WITH-LIMITATIONS: cấu trúc/reset assumptions đã ghi; CDC/RDC/STA/physical checks NOT-RUN, OQ-04/08/11/12.
