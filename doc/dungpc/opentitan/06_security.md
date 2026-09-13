# 06 — Security review trên phần cứng đã chọn

Security review phải trả lời bốn câu cho từng cơ chế: state/tín hiệu nào được
bảo vệ; lỗi được quan sát tại đâu; bao lâu mới quan sát được; hệ thống phải làm
gì khi có alert. Tên `SecureIbex` không thay thế câu trả lời cho bốn câu này.

## Delayed lockstep và shared resources

Main core và shadow core nhận input lệch pha. `LockstepOffset=1`, còn
`OutputsOffset=LockstepOffset+1` vì shadow outputs có register bổ sung. Reset
shadow và compare enable được sequencing riêng; compare xét enable khác MuBi
Off. Không được dùng riêng offset để khẳng định mọi fault sẽ alert sau đúng
một cycle kể từ injection.

Output bundle chọn các quan sát như instruction/data request, địa chỉ/control,
cache RAM control/write, key request, capability write metadata, busy/IRQ/crash
state. Scalar RF write data/address/enable không xuất hiện như một tuple trực
tiếp để so mọi bit main với shadow ở top; RF read-address controls cũng không nằm
trong bundle đó. RF/parity và read ECC là đường kiểm liên quan. RF read payload
và cache RAM là shared
resources có đường integrity riêng. Vì thế hai core đồng ý không có nghĩa mọi
corruption ở shared input đã được phát hiện bằng redundancy.

Nguồn: [top lockstep integration](../../../rtl/ibex_top.sv#L873),
[delayed inputs](../../../rtl/ibex_lockstep.sv#L243),
[selected output bundle](../../../rtl/ibex_lockstep.sv#L357),
[output compare](../../../rtl/ibex_lockstep.sv#L729).

`prim_buf` tạo optimization barrier theo flow synthesis hỗ trợ. Mô phỏng generic
không chứng minh backend giữ khoảng cách vật lý, chống common-mode fault hoặc
không tối ưu hợp nhất redundancy; các thuộc tính đó cần audit netlist/constraints.

## RF ECC, bus ECC, cache ECC là ba phạm vi khác nhau

| Cơ chế | Implementation đang tồn tại | Không được suy quá phạm vi |
|---|---|---|
| Scalar RF | Main data FF 32 bit; shadow parity FF 7 bit và RF ECC decoder | Main core không bật RegFileECC; read qualification/forwarding ảnh hưởng thời điểm detection |
| Capability RF | Metadata 35 bit; parity 7 bit theo padded inverted 64/57 path | Kiểm metadata/tag internal khác integrity của memory tag pin |
| External words | 32 data + 7 inverted SECDED | Tag pin không nằm trong codeword 39-bit này |
| Cache data | Mỗi line 64 payload + 14 checkbits | Không tự coi mọi cache ECC error là corrected data đã được sử dụng |
| Cache tag | 22 tag/valid + 6 ECC | Error recovery/invalidate cần xét bên cạnh data array |
| Bitmap | Response word ECC; lỗi ảnh hưởng returned capability tag | Không đồng nhất bitmap error với load access trap |

RF ECC error được qualify với read/valid và forwarding; decoder corrected output
không được dùng làm một cơ chế sửa RF payload trong đường này. Bus load integrity
error chặn destination write và đưa internal NMI flow; bitmap error clear tag và
phát bus alert. Store đã grant vẫn có thể là side effect bên ngoài trước khi
delayed compare phát hiện sai khác.
[RF integrity](../../../rtl/ibex_core.sv#L1214),
[alert aggregation](../../../rtl/ibex_core.sv#L1340),
[TRVK integrity](../../../rtl/ibex_trvk.sv#L369),
[cache ECC](../../../rtl/ibex_icache.sv#L290).

## Fault matrix đã thực thi

Các số cycle dưới đây là root counter tại observation trong harness, chỉ mô tả
lịch này. Fault data/ECC được đưa vào sau khi sinh parity từ payload nguyên bản.

| Run / injection point | Quan sát | Kết luận được hỗ trợ |
|---|---|---|
| `rv.fault1`: instruction payload XOR bit 0, giữ ECC | Bus alert đầu ở 5 | Instruction integrity path hoạt động; đây là detector test, không có success marker oracle |
| `rv.fault2`: load response bit flip | Bus alert 8; internal NMI cause `0xffffffe0`; x2 không ghi | Corrupt load destination bị chặn trong ca này |
| `rv.fault3`: RF read A force ở 100…110 | Internal alert 103; shadow RF error sample | Shared read corruption được RF integrity bắt ở điểm dùng đã test |
| `rv.fault4`: main EX result force | Internal alert 105; output mismatch sample | Fault lan tới một quan sát khác nhau giữa main/shadow |
| `rv.fault6`: PC force | PC mismatch/internal alert từ 100 | PC increment check hoạt động trên đường đã test |
| `rv.fault7`: unsolicited data-valid tại 100 | Không alert; chương trình hoàn tất | Điểm vi phạm protocol này không được biến thành claim có detector |
| `rv.fault10`: packed cache RAM read way 0, bit flip ở 350…354 | Minor alert từ 350; không major; chương trình tiếp tục | Recoverable cache error/recovery tại point đã inject |
| `cap.invalid_mode`: MuBi mode=0 từ 100 | Mode error/internal alert từ 100 | Invalid encoding được phát hiện khi execution enabled |
| `cap.rf_ecc`: metadata read bị force 0 ở 100…110 | Shadow RF error; internal alert 102 | Capability RF integrity path hoạt động |
| `cap.bitmap_ecc`: bitmap payload bit flip, giữ ECC | Bus alert 16; CGETTAG=0 | Corrupted bitmap không giữ live tag trong ca này |

Generic `INJECT 100 fault=N` trong log là nhãn diagnostics dùng chung, **không
phải onset của mọi fault**. Fault1/2/9 nằm trên response combinational path từ
đầu simulation; fault10 có nhãn injection thực ở 350. Muốn tính latency phải
dùng đúng điều kiện force/XOR trong harness và response sample, không lấy dòng
diagnostic chung trừ dòng ALERT.

Fault10 force packed RAM output để Verilator xử lý đúng; không force phần tử
unpacked array hoặc giá trị read-modify-write trên signal downstream. Main cache
không lỗi là đối chứng riêng `rv.cache`. Tất cả ca không injection đều kiểm
không xuất hiện internal/bus/minor alert. [Stimulus và injections](scripts/opentitan_tb.sv),
[detector checks](evidence/analysis_checks.json), [results](evidence/results.json).

## Scrambling, DIT và dummy: chức năng khác nhau

Scrambled cache banks dùng address scrambling, key/nonce và PRINCE keystream;
ICacheTweakInfection gắn biến đổi với context địa chỉ trong đường ECC. Những
phép thử ở đây kiểm access/rekey/recovery đúng chức năng. Chưa đo khả năng chịu
probing, key recovery, fault attacks nhiều bit hoặc leakage trên silicon.
[RAM implementation](../../../vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_scr.sv),
[tweak datapath](../../../rtl/ibex_icache.sv#L340).

DIT làm một số instruction có thời gian ít phụ thuộc dữ liệu hơn: hai case DIV
37 cycles khi bật, branch taken/not-taken 2 cycles. Cache misses, memory wait,
bitmap lookup và interruption vẫn có thể thay đổi thời gian toàn chương trình.
Dummy instructions dùng LFSR và x0 dummy state để không thay kết quả kiến trúc;
test kết hợp xác nhận kiến trúc và activity, không chứng minh side-channel safety.

PMP là phân vùng truy cập theo policy; CHERIoT bổ sung bounds/permissions/tag và
temporal revocation của capability. Chúng không thay thế nhau. Debug phải có
policy lifecycle của SoC, boot phải thiết lập root of trust, alert phải có reaction
policy. Đợt này giữ preset để tạo baseline kỹ thuật cho các quyết định đó.

## Mức tin cậy của bằng chứng

Verilator chạy với `--assert`, nhưng macro `prim_assert` của dependency chọn
nhánh vô hiệu SVA cho Verilator: preprocessing đếm **0 `assert property`**.
Các immediate `$fatal` kiểm protocol của harness vẫn hoạt động, cùng Python
trace/oracle checks. Không gọi kết quả này là “toàn bộ RTL assertions đã pass”.
[Assertion audit](evidence/assertion_audit.json).

Fault campaign này là các điểm directed, chưa phải exhaustive fault coverage,
formal proof, ISO/security certification hoặc silicon validation. Đây là ranh
giới bằng chứng cụ thể, không phải lý do để thay cấu hình đang được phân tích.
