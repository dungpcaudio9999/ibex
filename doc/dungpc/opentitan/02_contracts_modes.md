# 02 — Hợp đồng CPU, software và SoC

Cấu hình hardware đã cố định. Công việc tiếp theo là xác định ai sở hữu từng
quyết định runtime và điều kiện để CPU có thể thực thi đúng. Một parameter
secure không tự cung cấp boot policy, memory tags, entropy hay alert response.

## Ma trận runtime của cùng một binary

| Biến | Chủ sở hữu | Cách sử dụng trong thí nghiệm | Nghĩa đối với thiết kế |
|---|---|---|---|
| `cheriot_enable_i` | SoC | MuBi Off hoặc On trước nhả reset | Chọn cách decode, RF mapping, capability checks |
| `fetch_enable_i` | SoC/boot controller | MuBi On | Chỉ mã On hợp lệ cho phép fetch theo secure path |
| Cache enable | Software, CPUCTRL CSR `0x7c0` bit 0 | Ca cache đặt 1; các ca khác reset 0 | Bật lookup/cache allocation; không thay hardware |
| Data independent timing | Software, CPUCTRL bit 1 | So sánh 0/1 trên cùng DIV/branch | Vô hiệu hoá một số early-out/data-dependent timing |
| Dummy instruction enable | Software, CPUCTRL bit 2 | Bật cùng cache/DIT trong ca phối hợp | Chèn lệnh giả, cần quản lý LFSR seed/mask |
| PMP/MSECCFG | Boot/privileged software | Mặc định reset; hai ca locked deny region 0/15 | Policy truy cập không tự xuất hiện do PMPEnable |
| Interrupt mask/global enable | Software + SoC IRQ | Điều khiển theo từng ca | Wake, trap và debug là ba quyết định khác nhau |
| Debug trigger | Debug software | Ghi trong debug mode; execute match PC | Trigger enable không có nghĩa debug được phép ở mọi lifecycle |
| Key/nonce và key-valid | SoC provider | Provider trả key theo handshake | Cache invalidate/key wait có ảnh hưởng progress |

CPUCTRL thực tế còn bị điều kiện debug chặn cache enable:
`icache_enable = cpu_ctrl.icache_enable & ~(debug_mode | debug_mode_entering)`.
Xem [CSR runtime control](../../../rtl/ibex_cs_registers.sv#L1970).

Dual ISA dùng bank chung: RV32I x16…x31 và capability metadata trong CHERIoT.
Vì vậy việc đổi một pin mode khi đang chạy không đủ để bảo toàn context. Baseline
này chỉ kiểm hai mode ổn định từ reset và invalid encoding injection. Nếu sau này
cần migration hợp lệ khi đang chạy, phải đặc tả quiesce, flush, interrupt/debug,
PCC/DDC/special capabilities, RF save/restore và cache policy trước khi verification.
[RF mapping](../../../rtl/ibex_register_file_ff.sv#L85).

## Hợp đồng memory và các mốc không thể nhập nhằng

`req && gnt` chuyển quyền sở hữu một request sang memory. `rvalid` trả lời một
request đã nhận; không được đổi address/control của request đang chờ grant.
Store được chấp nhận là side effect có thể đã xảy ra ngoài CPU, không thể xoá
bằng pipeline flush. Một lệnh unaligned hoặc capability có thể sinh nhiều beat;
số beat outstanding không phải số instruction được issue ngoài thứ tự.

| Giao diện | CPU yêu cầu môi trường cung cấp | Harness dùng ở đây |
|---|---|---|
| Instruction | Data 32 + integrity 7, grant/response/errors đúng thứ tự | ROM 4 KiB tại 0; boot PC `0x80`; codeword inverted SECDED 39/32 |
| Debug fetch | Region chứa entry và exception handlers | ROM riêng `0x1a110000…0x1a110fff`, đúng top defaults |
| Data | Byte enables, data 32 + integrity 7, tag, errors | RAM 4 KiB độc lập; stores áp dụng BE tại grant |
| Tagged capability | Hai word và tag nhất quán; scalar stores không được tạo tag hợp lệ | Capability 8 byte tại `0x200`; tag model theo word, cả hai word ban đầu tagged |
| TRVK bitmap | Bitmap data, integrity, handshake; mapping nhất quán với heap base | Heap base `0x1000`; bitmap sống/thu hồi; response đợi 7 root cycles theo model |
| Scramble key | Key/nonce hợp lệ trước khi dùng response valid | Provider đợi 6 bước counter; initial top default key-valid khác fresh-key handshake |
| Reset | Không trả response của epoch trước reset vào core mới | Reset ca 7 xoá request queues và architectural monitor |

ROM và RAM ở đây là **hai không gian mô phỏng Harvard** cùng vùng numeric thấp;
đây không phải memory map OpenTitan. Address ngoài model báo lỗi, không modulo
alias vào chương trình. Debug ROM là mapping riêng để địa chỉ default cao vẫn
được kiểm đúng. Không mô phỏng TL-UL, lifecycle controller, alert handler hay
memory subsystem của một SoC OpenTitan hoàn chỉnh.

D1 mở grant mọi cycle, đặt response sau 1 root cycle; D4 mở grant mỗi 3 cycle,
đặt response sau 4 cycle. Các số này là điều kiện stimulus, không phải thông số
latency cố hữu của Ibex. Bitmap và key có bộ đếm riêng, không bị suy thành D1/D4.
Xem [harness](scripts/opentitan_tb.sv), [program generator](scripts/run.py).

## Reset, sleep, debug và xử lý lỗi thuộc hợp đồng hệ thống

Clock gate phụ thuộc registered main-core busy, debug request, IRQ pending và
NMI. Secure path chỉ đóng clock khi busy đúng MuBi Off; encoding bất hợp lệ giữ
clock hoạt động. `core_sleep_o = ~clock_en`. Shadow state được căn chỉnh trong
lockstep; không được suy rằng clock-enable là OR hai busy signals.
[Clock gate](../../../rtl/ibex_top.sv#L303).

WFI có thể đợi cache hết busy trước khi gate clock. IRQ có thể đánh thức mà
không vào trap nếu global MIE chưa bật: ca WFI đặt MTIE nhưng không đặt MIE,
kiểm CPU tiếp tục sau WFI. Ca debug/IRQ khác đặt cả mask và global enable để
kiểm priority. Reset test chứng minh trường hợp cụ thể có epoch cancellation,
không chứng minh reset giữa mọi transaction/key transition.

Các output alert là thông báo cho hệ thống. Harness chỉ ghi nhận, không tự reset
hoặc khóa memory sau alert. Do đó không thể lấy “alert xuất hiện” làm bằng chứng
mọi faulty side effect đã bị ngăn chặn. Hệ thống cần thiết kế thời hạn reaction,
quyền debug theo lifecycle, secure boot, entropy/provisioning, tag storage,
bitmap coherency và PMP policy. Các hạng mục này là đầu vào cho tích hợp sản phẩm,
không phải thay đổi preset đang được ngầm thực hiện.
