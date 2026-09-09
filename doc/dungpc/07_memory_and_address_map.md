# 07 — Memory và address map

BASE-01, CFG-simple-source trừ khi ghi rõ khác. Source authority cho implementation: [Simple System decode](../../examples/simple_system/rtl/ibex_simple_system.sv#L116), [bus](../../shared/rtl/bus.sv), [RAM wrapper](../../shared/rtl/ram_2p.sv), [linker](../../examples/sw/simple_system/common/link.ld). Memory map này **thuộc ví dụ Simple System**, không phải map bắt buộc của mọi Ibex IP.

## Data address space

| Vùng | Base | End inclusive | Size | Decode/attributes | Error/side effect |
|---|---|---|---|---|---|
| RAM | 0x00100000 | 0x001FFFFF | 1 MiB | `(addr & 0xFFF00000)==0x00100000`; 32-bit words, 4 BE | RAM data err tied 0; read/write |
| Simulator control | 0x00020000 | 0x000203FF | 1 KiB aperture | `(addr & 0xFFFFFC00)==0x00020000` | Output/halt, read 0; device_err tied 0 |
| Timer | 0x00030000 | 0x000303FF | 1 KiB aperture | `(addr & 0xFFFFFC00)==0x00030000` | Chỉ offsets 0,4,8,C hợp lệ; offsets khác error |
| Không match | Các địa chỉ còn lại | — | — | Không request device | Host vẫn grant, cycle sau decode error response |

Không có memory type attribute/tag cacheability truyền trên bus mẫu; MMIO side effects suy ra từ slave. Core parameter PMP có thể bảo vệ địa chỉ khi bật; CFG-small-intent/CFG-simple-source PMPEnable=0. Không có data cache trong đường mẫu này.

## FND-MEM-01 — Instruction fetch alias khác data decode

**Support:** SUPPORTED [RTL:ESTABLISHED], BASE-01 Simple System: instruction request nối trực tiếp port B RAM, `instr_gnt=instr_req`, `instr_err=0`; không đi qua vùng data decode.

Depth RAM=`1024*1024/4=262144`, Aw=18, index=`addr[19:2]`. Vì bỏ upper bits, instruction addresses 0x00000080, 0x00100080, 0x00200080 có cùng RAM index 0x20. Data address 0x00200080 không match và trả lỗi. Đây là alias do wrapper mô phỏng, không phải bằng chứng CPU/PMP cho phép mọi fetch. CPU còn có thể chặn request trước boundary khi cấu hình protection tương ứng được bật.

EVD-06 tính 12 address cases bằng mô hình số học và xác nhận phép tính alias/decode; **không mô phỏng RTL**. OQ-10 để quyết định behavior này có phù hợp target sản phẩm không.

## Boot, trap và linker

**FND-BOOT-01:** IF dùng `{boot_addr_i[31:8],8'h80}` cho PC_BOOT; Simple nối boot_addr=0x00100000 nên reset entry=0x00100080. **Support:** SUPPORTED [RTL:ESTABLISHED], `ibex_if_stage.sv:243`, top simple:247; boot input phải 256-byte aligned theo `IbexBootAddrUnaligned`.

Trong RV32 mode, mtvec khởi tạo vectored với base 0x00100000; synchronous exception về base, timer cause 7 về base+0x1C, NMI external cause31 về base+0x7C. Các vector là địa chỉ entry, chưa chứng minh firmware handler thực thi. CHERIoT có capability trap vectors/CSR policy khác (Stage 8).

Linker khai báo `ram ORIGIN=0x00100000 LENGTH=0x30000` (192 KiB) và stack `0x00130000 LENGTH=0x8000` (32 KiB). Cả hai nằm trong 1 MiB hardware RAM. `_stack_start=0x00138000`, `_min_stack=0x2000`, entry=`_vectors_start+0x80`; `tohost=0x20008` khớp simulator halt. **Không coi 224 KiB software allocation và 1 MiB RAM là mâu thuẫn**: phần mềm dùng một subset. Chưa có ELF sections/map để xác nhận binary cụ thể vừa vùng nhớ.

`crt0.S` cung cấp vector/startup; `common.mk` dùng RV32IMC/ILP32. Cần giữ ISA, reset mode, linker, memory image và metadata tags thống nhất; image RV32 thông thường không kiểm chứng boot CHERIoT.

## Access alignment và byte order

External data address được LSU word-align; byte enables và rotate/assemble thực hiện byte/halfword/misaligned words. Ví dụ store word tại A+1 tách BE=1110 ở A và BE=0001 ở A+4. Không bảo đảm atomicity hai phần: phần đầu có thể đã ghi trước lỗi phần sau, đặc biệt nguy hiểm nếu tách qua MMIO/permission boundary.

RAM wrapper ánh xạ BE thành mask 8 bit mỗi lane. Hành vi collision đọc/ghi cùng địa chỉ qua hai port còn phụ thuộc primitive backend; không dùng mô hình generic thay cho SRAM macro sản phẩm. RAM không có tag storage trong Simple System, `data_tag_i=0`, write tag bỏ ngỏ. OQ-06/10.

## CHERIoT bitmap ở boundary IP

Địa chỉ bitmap không nằm trong data map mặc định như một peripheral đã tích hợp. TRVK có port riêng; top params width=11 và base=0 chỉ mô tả vùng meta memory **dự kiến**. `heap_base_addr_i` là đầu vào riêng; Simple nối 0 và không cấp service. Mỗi bit phủ 8 bytes, word32 chứa 32 bits →256 bytes heap/bitmap word; 512 words bitmap →128 KiB heap.

Trừ unsigned `cap_base-heap_base`, shift 3 và kiểm các high bits xác định out-of-range. Không suy ra capability ngoài vùng bị thu hồi: source bỏ lookup khi out-of-range hoặc sealing capability. Chốt trust/heap map trong OQ-06/12 trước khi dùng kết luận security.
