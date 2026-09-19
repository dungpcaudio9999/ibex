# 09 — SecureIbex, lockstep, ECC và tag revocation

## 1. `SecureIbex` là một nhóm cơ chế

Trong tree hiện tại, `SecureIbex=1` trực tiếp hoặc mặc định kích hoạt:

- main/shadow lockstep;
- data-independent timing capability;
- PC increment checking;
- secure MuBi handling cho busy/fetch enable;
- mặc định memory ECC, dummy instructions, reset-all và I-cache tweak infection.

Tuy nhiên local FX1 profiles có thể override `MemECC`, `DummyInstructions` và
`ResetAll` độc lập. Vì vậy phải đánh giá từng cơ chế, không chỉ nhìn một bit
`SecureIbex`.

## 2. Threat model theo vùng

| Cơ chế | Lỗi nhắm tới |
|---|---|
| Lockstep | transient/permanent fault trong control/datapath |
| RF ECC | bit flip trong register storage |
| Mem ECC | corruption trên instruction/data bus |
| I-cache ECC/scramble | RAM corruption, probing và address/data manipulation |
| PC increment check | control-flow skip/repeat trái phép |
| Dummy instruction | side-channel power/EM analysis |
| Data-independent timing | timing leakage theo operand/branch |
| MuBi | fault ép enable/disable bit |
| PMP/CHERIoT | spatial authority violation |
| TRVK | sử dụng capability đã bị revoke |

Không cơ chế đơn lẻ bao phủ toàn bộ bảng.

## 3. Lockstep timeline

`ibex_lockstep` chạy shadow core trễ `LockstepOffset` chu kỳ. Với offset mặc
định 1:

```text
cycle N     : main nhận input X
cycle N+1   : shadow nhận X
cycle N+2   : shadow output được register và so với main output đã delay
```

`OutputsOffset = LockstepOffset + 1` vì shadow output có thêm một register trước
compare.

Input main được đóng gói và delay: memory responses, RF read data, interrupts,
debug, fetch enable, cache key valid và CHERIoT enable. I-cache RAM arrays có
delay riêng do kiểu unpacked array.

## 4. Reset và compare enable

Sau system reset:

1. shadow core vẫn bị reset;
2. counter hoặc fixed one-cycle delay đạt `LockstepOffset`;
3. shadow reset được nhả;
4. compare được enable sau đó qua MuBi flops.

`scan_rst_ni` có thể thay shadow reset qua clock mux khi test mode bật.

Với `ResetAll=0`, valid/control flops reset nhưng nhiều payload flops không reset.
Thiết kế dựa vào valid gating và trình tự compare. Profile
`fx1_secure_dev_resetall` tồn tại để cô lập vấn đề này; cần regression chứng
minh không có mismatch X hoặc mismatch chức năng sau reset.

## 5. Output comparison

Bundle so sánh gồm:

- instruction/data bus request, address và write controls;
- I-cache RAM request/write/address/data;
- interrupt pending;
- crash dump và double-fault;
- core busy;
- capability RF write metadata.

Compare bật khi `enable_cmp_q != IbexMuBiOff`; mọi encoding khác Off đều fail
safe theo hướng bật compare. Mismatch góp vào `alert_major_internal_o`.

Một số write signals nội bộ shadow RF không so trực tiếp; corruption sẽ xuất
hiện khi RF outputs kết hợp với ECC check hoặc khi ảnh hưởng output kiến trúc.

## 6. RF ECC tách main/shadow

Đây là thiết kế dễ hiểu sai nhất:

```text
main register file:
  data 32 bit + capability metadata 35 bit

shadow register file:
  7 ECC bits cho data + 7 ECC bits cho capability
```

Main core chạy `RegFileECC=0`. Shadow core chạy `RegFileECC=1` và nhận:

```text
{shadow_ecc_bits, delayed_main_rf_data}
```

để decoder SECDED kiểm 39/32. Khi ghi, shadow core sinh full codeword nhưng
shadow RF chỉ lưu phần ECC phía trên; data phía dưới vẫn do main RF giữ.

Capability 35 bit được zero-pad theo code 64/57 để sinh 7 check bits. Check
capability chỉ có ý nghĩa khi CHERIoT enable.

Hệ quả: tắt lockstep cũng loại cách bảo vệ RF này, vì `RegFileLockstepECC` bám
`Lockstep`.

## 7. Memory và I-cache integrity

### Memory bus

`MemECC=1` dùng inverted SECDED 39/32 cho I-side và D-side. Lỗi response hợp lệ
phải dẫn đến major bus alert trong số chu kỳ assertion cho phép.

### I-cache

Nếu I-cache bật:

- tag/data có ECC độc lập;
- tag/data RAM có thể scramble;
- tweak infection trộn thông tin address vào stored representation;
- lỗi RAM primitive hoặc ECC đi vào major internal alert.

FX1 hiện tắt I-cache và memory ECC; lockstep không thay thế khả năng phát hiện
corruption trên bus trước khi dữ liệu đi vào cả main lẫn shadow theo cùng cách.

## 8. PC increment, DIT và dummy instruction

- PC increment check so PC tuần tự thực với giá trị dự kiến 2/4 byte.
- DIT làm branch/divide tránh early-out phụ thuộc dữ liệu khi CSR bit runtime
  bật.
- Dummy instructions tạo hoạt động giả có kiểm soát bằng LFSR; marker đi xuyên
  pipeline để không commit như instruction thật.

FX1 DEV/PROD vẫn có DIT và PC check do `SecureIbex=1`, nhưng dummy instruction bị
override tắt.

## 9. CHERIoT tag revocation placement

`ibex_trvk` nằm giữa LSU và external data bus. Nó forward request xuống memory,
đồng thời theo dõi alignment/response để nhận biết một capability load hợp lệ.

Assumption cốt lõi được ghi ngay trong RTL: tagged capability load đến dưới
dạng đúng hai response 32 bit liên tiếp, không bị xen kẽ, từ một requester in-order.

Nếu interconnect vi phạm assumption này, revocation check có thể ghép sai pointer
và metadata.

## 10. TRVK request/response flow

### Request

`stream_fork` chỉ handshake upstream khi cả downstream bus và alignment FIFO đều
sẵn sàng. Address bit 2 được lưu để biết cặp response có align 64-bit hay không.

### Response buffering

Response downstream được lưu trong FIFO depth bằng số outstanding D-side
transactions. Pointer word của capability được lưu tạm khi tag hợp lệ và align
đúng.

### Bitmap lookup

Từ pointer và compressed metadata, TRVK:

1. mở rộng exponent;
2. tính capability base;
3. trừ `heap_base_addr_i`;
4. chia cho 8 byte/capability để lấy bitmap bit address;
5. tạo word address và bit select;
6. đọc revocation bitmap qua port riêng.

Sealing capability hoặc base ngoài vùng bitmap không dùng lookup theo cùng cách
capability heap thông thường.

### Tag result

Nếu bitmap bit bằng 1, bitmap bus error hoặc integrity error, returned tag bị
clear. Dữ liệu vẫn được forward; authority bị loại nhờ tag=0.

## 11. TRVK ECC và fail-safe

Nếu `MemECC=1`, response bitmap được kiểm SECDED 39/32. Bitmap device error và
integrity error đều đi vào `alert_major_bus_o`; đồng thời logic revoked đối xử
lỗi như capability không còn hợp lệ.

Assertions kiểm:

- mỗi upstream response có alignment metadata;
- response FIFO không overflow;
- không có bitmap response tự phát;
- bitmap request payload ổn định khi chưa grant.

## 12. Alert tree

### `alert_major_internal_o`

Hợp của:

- main core internal alert;
- lockstep mismatch/shadow internal alert;
- I-cache RAM/integrity alert.

Nguồn main core gồm PC mismatch, RF ECC, invalid MuBi, CSR-related fatal state và
các control-flow integrity conditions.

### `alert_major_bus_o`

Hợp của:

- main/shadow bus integrity alert;
- revocation bitmap device/integrity error.

### `alert_minor_o`

Hợp minor alert của main và shadow, thường dành cho lỗi có mức nghiêm trọng
thấp hơn theo policy tích hợp.

Mọi alert output có assertion không được X.

## 13. Đánh giá nhanh các profile

| Cơ chế | opentitan | fx1_secure_dev/prod |
|---|---:|---:|
| Lockstep | bật | bật |
| RF ECC qua shadow | bật | bật |
| Mem ECC | bật | tắt |
| Reset all payload | bật | tắt |
| Dummy instructions | bật | tắt |
| PC increment check | bật | bật |
| Data-independent timing support | bật | bật |
| I-cache ECC/scramble | bật | không có I-cache |
| PMP RV32 mode | bật | bật |
| CHERIoT + TRVK | bật | bật |

Đây là khác biệt countermeasure thực tế, không chỉ khác performance/area.

## 14. Verification bắt buộc cho FX1

- reset nhiều seed/initial-X với lockstep compare enable;
- inject fault main-core control/output và thấy major internal alert;
- corrupt main RF data/ECC và capability metadata;
- chứng minh data bus mapping khi `MemECC=0`;
- CHERIoT enable one-way và invalid MuBi encoding;
- revoked/not-revoked/out-of-range/sealing capability;
- bitmap bus error khi `MemECC=0` và khi bật ECC ở profile tham chiếu;
- WFI wakeup và lockstep alignment;
- DEV/PROD debug-trigger khác biệt.

## 15. Điểm vào source

- [`rtl/ibex_lockstep.sv`](../../../rtl/ibex_lockstep.sv)
- [`rtl/ibex_trvk.sv`](../../../rtl/ibex_trvk.sv)
- [`rtl/ibex_top.sv`](../../../rtl/ibex_top.sv)
- [`rtl/ibex_core.sv`](../../../rtl/ibex_core.sv)
- [`rtl/ibex_dummy_instr.sv`](../../../rtl/ibex_dummy_instr.sv)

