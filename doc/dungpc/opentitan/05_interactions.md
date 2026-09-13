# 05 — Tương tác và các điểm phải giữ precision

Review CPU không dừng ở chức năng từng block. Cần theo dõi instruction nào sở
hữu state, event nào được phép cắt ngang và side effect nào đã ra ngoài core.
Các kết quả dưới đây được kiểm tự động từ trace trong
[analyze.py](scripts/analyze.py), không chỉ đọc marker cuối chương trình.

## Load chậm / lỗi và instruction trẻ

| Ca | Load grant | Load write | ADDI độc lập write | ADDI phụ thuộc write |
|---|---:|---:|---:|---:|
| `rv.independent_d1` | 7 | 8 | 9 | 10 |
| `rv.independent_d4` | 15 | 19 | 20 | 21 |
| `rv.error_young` D4 | 15 | Không | Không | Không |

Do WB outstanding memory blocking, instruction độc lập không vượt load. Error
case lưu cause 5, MEPC `0x84`, MTVAL `0x208`. Negative control chèn một dòng write
x3 giả vào trace lỗi: chính checker no-younger-write phải từ chối. Việc chỉ so
final registers sẽ yếu hơn nếu một write sai sau đó bị ghi đè.
[ID blocking](../../../rtl/ibex_id_stage.sv#L1000),
[negative control](evidence/checker_negative_control.json).

## Debug đến khi CPU đang bận

| Ca | Debug request | Kết quả lệnh đang bận | Kết quả tiếp theo |
|---|---:|---|---|
| `rv.div_debug` | 26, trong divider stall | x4=65 ở 63 | Debug entry sau write; marker debug ở 72; DRET trở lại marker 84 |
| `rv.zcmp_debug` | 19, push store đang chờ | SP giảm ở 23 | Debug marker 33; DRET rồi pop, SP khôi phục ở 50 |
| `cap.debug` | 26, bitmap đang chờ | c2 ghi ở 31 | Debug entry sau c2 write; marker debug 42; DRET hoàn tất |

Điều kiện ở controller chặn debug entry trong `INSTR_EXPANDED` và
`INSTR_EXPANDED_COMMIT`. Do đó ca push/pop không phải “debug chỉ sau cả cặp”:
entry xảy ra giữa push đã hoàn tất và pop chưa chạy. Với capability, một lệnh
CGETTAG trẻ có thể hoàn tất trước debug entry trong ca này; guarantee đã kiểm
là kết quả pending capability được drain trước entry, không phải cấm mọi lệnh
trẻ kể từ cycle request.
[Controller debug qualification](../../../rtl/ibex_controller.sv#L474),
[DIV trace](evidence/rv.div_debug.log), [Zcmp debug trace](evidence/rv.zcmp_debug.log),
[cap debug trace](evidence/cap.debug.log).

## IRQ giữa Zcmp: phase quyết định restart PC

`handle_irq` chỉ cấm phase `INSTR_EXPANDED_COMMIT`, khác điều kiện debug. Hai
ca cùng phát IRQ sau store đầu tiên được chấp nhận tại cycle 30:

| Ca | Phần push | Kết quả khi handler chạy |
|---|---|---|
| `rv.zcmp_irq` | Chỉ RA | SP=`0x2f0`; MEPC=`0x9a`, trỏ pop kế tiếp |
| `rv.zcmp_irq_multi` | RA và hai saved registers | Hai store đã grant tại 30/36; SP vẫn `0x300`; MEPC=`0x98`, trỏ lại push |

Không được suy “IRQ xảy ra → không có store nào”, hoặc “đã grant store đầu → SP
đã commit”. Ca multi cho thấy side effects của phần restartable có thể tồn tại
trước trap. Software/system phải cho phép các store đó được thực hiện lại khi
restart, phù hợp ngữ nghĩa stack memory. Các ca này dừng trong IRQ handler để
kiểm state; không chạy MRET/replay cả multi-register push trong đợt này.
[IRQ qualification](../../../rtl/ibex_controller.sv#L498),
[expander phases](../../../rtl/ibex_compressed_decoder.sv#L630),
[multi trace](evidence/rv.zcmp_irq_multi.log).

## Priority, hardware trigger và debug map

`rv.debug_irq` đưa external debug và timer IRQ cùng lúc khi load pending;
debug marker xuất hiện trước IRQ cause. `rv.nmi_return` kiểm NMI vector, cause
`0x8000001f`, MRET và completion trở lại. Đây là hai ordering point cụ thể,
không phải exhaustive cross-product mọi synchronous exception/NMI/debug.

`rv.debug_trigger` vào debug lần đầu bằng external request, lập TDATA2=`0x98`,
TDATA1.execute=1 và DRET. Lần thứ hai vào đúng debug entry vì PC match; handler
tắt trigger rồi DRET để tránh retrigger vô hạn. x14 đếm đúng hai entry và marker
chương trình xuất hiện sau entry thứ hai. TDATA được ghi trong debug mode vì
RTL bỏ qua programming ngoài mode đó; trigger là execute/address match, không
phải arbitrary load/store watchpoint.
[Trigger CSR](../../../rtl/ibex_cs_registers.sv#L1758),
[trigger trace](evidence/rv.debug_trigger.log).

## Cache, FENCE.I, key và debug

Cache reset FSM đi OUT_RESET → AWAIT_KEY → INVAL → IDLE. Có 256 indices cần
invalidate; CPU vẫn có thể lấy instruction bằng bypass trong lúc cache lookup
bị chặn. Initial key-valid tại top khác một fresh key response của SoC provider.
FENCE.I phát invalidate/key request; một invalidate đến trong invalidate có thể
đưa FSM quay lại đợi key. Không lấy số startup này làm boot latency cố định
khi key provider hoặc memory timing khác.

Trong `rv.cache_debug_key`, loop warm kết thúc, event debug phát lúc key request
tại 655; key response và debug marker cùng ở 659; chương trình marker ở 663.
Cache tự bị disable trong debug, rồi có thể dùng lại khi điều kiện runtime cho
phép. Test chứng minh progress và key response dưới một lịch stimulus; không
đòi CPU đợi toàn bộ invalidate xong mới thực thi instruction sau FENCE.I.
[Cache invalidate FSM](../../../rtl/ibex_icache.sv#L1212),
[runtime cache gating](../../../rtl/ibex_cs_registers.sv#L1970),
[trace](evidence/rv.cache_debug_key.log).

## DIT, dummy, cache và sleep

CPUCTRL=7 bật cache/DIT/dummy cùng lúc trong một loop hữu hạn. Architectural
loop result đúng, có dummy và cache-hit activity, không alert. Trace kết thúc
còn self-loop nên tổng hit/dummy toàn run chỉ là activity evidence; không dùng
nó để tính tỷ lệ overhead cho workload hữu hạn.

WFI đến trước khi cache hết khởi tạo vẫn phải chờ busy hạ. Harness đợi đủ 20
root sleep cycles mới đưa IRQ: wake event 281, marker tiếp tục tại 284.
Sleep counter toàn run có thể bao gồm trạng thái đầu reset ở các ca khác;
không xem sleep=1 mặc định là instruction WFI được thực thi.
[Clock gate](../../../rtl/ibex_top.sv#L303),
[WFI trace](evidence/rv.sleep.log), [combined trace](evidence/rv.dummy_dit_cache.log).

## Các chiều đã review bằng RTL nhưng chưa quét hết

Redirect với mọi trạng thái fill buffers, lỗi trên từng phase của Zcmp popret,
IRQ/NMI đúng COMMIT cycle, bitmap có backpressure grant kéo dài, reset giữa fresh
key response và RAM write, PMP overlap/privilege transitions, valid runtime ISA
migration và các tổ hợp hai fault cùng lúc cần test space lớn hơn. Chúng được
ghi thành verification follow-up; không đánh dấu đã chứng minh chỉ vì 54 ca
directed hiện tại đạt. [Validation scope](08_validation_findings.md).
