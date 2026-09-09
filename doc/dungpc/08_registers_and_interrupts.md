# 08 — CSR, MMIO và interrupt

BASE-01. Không trộn CSR address 12-bit với địa chỉ MMIO 32-bit. CSR decoder là RTL viết tay ở [ibex_cs_registers](../../rtl/ibex_cs_registers.sv), enums ở [ibex_pkg](../../rtl/ibex_pkg.sv); MMIO có nguồn RTL timer/simctrl và header C, không có lần reggen được thực hiện trong phân tích này.

## CSR quan trọng cho các flow

| CSR | Address | Field/access semantics cần biết | Reset / side effect và scope |
|---|---|---|---|
| mstatus | 0x300 | MIE bit3, MPIE7, MPP12:11, MPRV17, TW21; WARL | MIE0/MPIE1/MPPU/MPRV0/TW0; current priv riêng reset M; trap/mret đổi state |
| misa | 0x301 | Giá trị đọc từ cấu hình, không là enable runtime viết tùy ý | Dynamic I/E/X masking trong dual mode; A/F/D/S=0 trong giá trị nguồn |
| mie | 0x304 | MSIE3, MTIE7, MEIE11, fast30:16 | Reset 0; gate pending để wake/controller |
| mtvec | 0x305 | RV32 mode ép vectored, base 256-byte aligned | Boot init từ boot_addr; CHERIoT mode truy cập integer CSR này illegal |
| mcounteren | 0x306 | Quyền U-mode đọc counters, có control `mcounteren_writable_i` | Không là interrupt enable; cần kiểm field mask/lock khi phát triển driver |
| mscratch | 0x340 | Scratch RW | State software; không có read-clear |
| mepc | 0x341 | PC trap, bit0 bị bỏ | Trap lưu/mret đọc; CHERIoT mode dùng capability state và integer CSR illegal |
| mcause | 0x342 | External/internal IRQ encoding và lower cause | Trap ghi; cần giữ riêng CHERIoT error và bus error |
| mtval | 0x343 | Fault PC/address/value theo controller | Split error chọn địa chỉ lỗi; không phải mọi trap đều là memory address |
| mip | 0x344 | Live read pending từ inputs, không phần mềm W1C | Không có pending flop trong CSR; muốn clear timer phải xử lý nguồn |
| pmpcfg/pmpaddr/mseccfg | Xem enum/CSR decode | Region permission/mode/lock, Smepmp | Optional theo PMPEnable/regions/reset params; không blanket RW |
| mcycle/minstret và high halves | 0xB00/0xB02, 0xB80/0xB82 | 64-bit architectural counters, split RV32 accesses | HPM số lượng/width cấu hình riêng; đọc snapshot cần protocol rollover |
| DCSR/DPC/DSCRATCH | 0x7B0 trở đi | Debug-only access policy | Debug entry/save/restore; Simple debug_req=0 |
| cpuctrlsts/secureseed | Xem enum và decoder | Cache/dummy/timing/security control, seed side effect | Tính năng theo parameters, không giả định fields đều implemented |

Bảng ưu tiên các CSR ảnh hưởng bảy flow, không phải register reference đầy đủ. Các field PMP/HPM/debug/security ít dùng và toàn bộ capability CSR cần sâu hơn trước khi viết driver hoặc chứng nhận ISA. Canonical full inventory nằm trong enum `csr_num_e` và decoder cùng BASE-01; Stage 10 CSR giải thích logic quyết định.

**FND-CSR-01:** CSR write được gate bởi operation-enable và illegal-access check; trong CHERIoT còn đòi quyền PCC.SR trừ debug. **Support:** SUPPORTED [RTL:ESTABLISHED], `ibex_cs_registers.sv:402–406,1013–1022`. Đọc CSR không có nghĩa được phép commit instruction: controller có thể trap ASR violation. `mret/dret/save_cause` cập nhật state theo priority logic riêng, không mô hình hóa thành một ngân hàng RW thông thường.

## Timer MMIO — tất cả register trong block

| Address | Register/field | Access, reset | Side effect / simultaneous event |
|---|---|---|---|
| 0x30000 | mtime low [31:0] | RW bytes, reset0 | Mtime tăng mỗi root cycle; write-half thay increment-half, half kia vẫn từ increment |
| 0x30004 | mtime high [63:32] | RW bytes, reset0 | Chưa bảo đảm snapshot atomic với low read |
| 0x30008 | mtimecmp low | RW bytes, reset0 | Request write offset này clear IRQ, kể cả BE=0 |
| 0x3000C | mtimecmp high | RW bytes, reset0 | Cùng clear semantics; cycle sau có thể set lại |
| Các offset khác trong aperture | Undefined | rdata=0, err=1 cùng rvalid | Không có register side effect được decode |

Read data và error được chốt khi request; rvalid là request trễ một cycle. Rdata/error flops không reset, chỉ có nghĩa khi rvalid. Byte mask bảo toàn byte không ghi dựa trên giá trị cũ; với mtime điều này khác “increment rồi merge tất cả bytes”. Không có read-clear, FIFO-pop hay W1C pending register trong timer.

## FND-TMR-01 — IRQ sticky, compare-write clear thắng

**Statement:** `interrupt_next=((mtime>=mtimecmp) | interrupt_q) & ~(mtimecmp_we | mtimecmph_we)`. Ghi mtime lùi xuống dưới compare không tự clear ngắt đã latched. Ghi bất kỳ half compare clear tại cạnh đó; nếu compare vẫn quá hạn ngắt có thể set lại cạnh kế tiếp. Reset compare=0 dẫn đến IRQ set ở cạnh hoạt động đầu tiên sau reset dù software chưa lập lịch, nhưng CPU mie reset0 nên chưa trap timer.

**Support:** SUPPORTED [RTL:ESTABLISHED]; EVD-06 [SIM:OBSERVED **chỉ mô hình Python**] kiểm phép tính recurrence trên 10 cạnh, không là RTL run. **Applies:** BASE-01 timer standalone/CFG-simple-source. **Depends on:** `shared/rtl/timer.sv:75–110`, clock/reset, bus write acceptance; ASM-BUS-02. **Freshness:** CURRENT. **Impact:** driver phải clear nguồn bằng compare write; đọc/ghi mip không giải quyết nguồn ngắt. **Uncertainty:** không có RTL trace/simulator, OQ-01/10. **Review:** chưa review độc lập; không supersede finding khác.

Firmware `timer_read()` đọc high-low-high và lặp nếu high đổi; `timecmp_update()` ghi low=0xFFFFFFFF, high, low cuối. Đây là sequence hiện hữu được đối chiếu nguồn, không phải test kết quả runtime. `timer_enable()` lập compare rồi enable mie.MTIE và mstatus.MIE. Mọi half-write compare đều tạm clear IRQ; handler không nên coi clear một lần là bảo đảm ngắt không trở lại nếu deadline cũ.

## Simulator control MMIO

0x20000: write khi `req & we & be[0]` ghi ASCII `wdata[7:0]` vào file; đọc0. 0x20008: write bit0=1, BE0=1 và sim_finish đang0 bắt đầu termination. State 3-bit tiến qua 1 rồi2, `$finish` khi pre-edge `sim_finish>=2`; có độ trễ sau request, không kết thúc ngay ở grant. Rvalid request trễ1; các offset khác trả0/không side effect và không có device error. Decode `addr[9:2]` bỏ hai bit thấp; LSU cung cấp word-aligned address. Không dùng peripheral này cho phần cứng sản phẩm.

## Interrupt routing và priority

| Nguồn | Cause | Pending/mask | Clear/priority |
|---|---|---|---|
| Software | 3 | mip.MSIP & mie.MSIE | Clear ở nguồn external; dưới external, trên timer |
| Timer | 7 | timer_irq→MTIP & MTIE | Ghi compare; thấp nhất trong thứ tự maskable ở đây |
| External | 11 | MEIP & MEIE | Platform external source; không có PLIC trong Simple |
| Fast [14:0] | 30:16 | mip.fast & mie.fast | Fast ưu tiên hơn IRQ thường, index **thấp** thắng |
| NMI external | 31 | Không dùng mie thông thường | Ưu tiên cao; nmi_mode chặn nested NMI theo controller |
| Integrity internal | Internal cause enum | Internal pending path | Error handling riêng; không gộp thành data_err |

**FND-IRQ-01:** Trong `IRQ_TAKEN`, thứ tự là NMI → fast → external → software → timer, và vòng `gen_mfip_id` làm fast index thấp thắng. **Support:** SUPPORTED [RTL:ESTABLISHED], `ibex_controller.sv:503–510,725–761`; khớp local exception_interrupts.rst cho fast priority.

Debug mode/single step, nmi_mode và expanded commit sequence ảnh hưởng `handle_irq`. Trap controller ngừng/flush pipeline đúng boundary, lưu mepc/mcause/mstatus, redirect IF; **wakeup không đồng nghĩa nhận interrupt**. Mip không latch nên input pulse ngắn hoặc source clear sớm cần platform protocol. Simple chỉ nối timer; software/external/fast/NMI/debug bị tie-off, do đó hello_test không kiểm các đường này. OQ-04/09/12.
