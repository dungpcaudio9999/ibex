# 05 — Hợp đồng giao dịch

BASE-01; nguồn local [LSU protocol](../../doc/03_reference/load_store_unit.rst), [instruction fetch](../../doc/03_reference/instruction_fetch.rst), [top ports](../../rtl/ibex_top.sv), [TRVK](../../rtl/ibex_trvk.sv). `SPEC:DECLARED` ở đây chỉ là yêu cầu trong tài liệu repository; chưa xác nhận bằng execution. Không gán giao diện này thành AXI/AHB chỉ vì có req/grant.

## Sampling và quy tắc chung

Tín hiệu được xét **trước cạnh lên** của clock tương ứng; state mới sau cạnh là kết quả nonblocking update. Accepted request = `req && gnt`; completion = `rvalid`, payload/error hợp lệ cùng cycle. Response không có ready để CPU backpressure. Grant và response là hai sự kiện khác nhau; store vẫn cần response. Theo protocol local, response đến ít nhất một cycle sau grant, đúng một lần và đúng thứ tự; hai response liên tiếp có thể giữ rvalid cao hai cycle cho hai giao dịch khác nhau. ASM-BUS-01/OQ-12.

Ví dụ dự đoán cho một request A ở boundary IP, không phải waveform đã chạy:

| Cạnh lấy mẫu | req | gnt | addr/control | rvalid | Nghĩa |
|---|---:|---:|---|---:|---|
| e0 | 1 | 0 | A | 0 | Bắt đầu, phải giữ payload |
| e1 | 1 | 0 | A | 0 | Stall grant |
| e2 | 1 | 1 | A | 0 | Accept A; có thể đổi payload sau cạnh |
| e3 | 0 | 0 | Không có nghĩa | 0 | Đang chờ response |
| e4 | 0 | 0 | Không có nghĩa | 1 | Nhận data/error của A, kết thúc bus obligation |

Không có bound e4 nếu memory không cam kết latency. Instruction retirement có thể muộn hơn và có thể không xảy ra nếu instruction bị flush/trap.

## Instruction interface

Producer: IF qua prefetch hoặc icache; consumer: instruction memory. Address `instr_addr_o` word-aligned 32-bit; data 32-bit, thêm 7 integrity bits ở top khi kiểm ECC; `instr_err_i` là access response error. Prefetch có hai outstanding word requests; cache có cơ chế fill riêng, không ngoại suy capacity prefetch sang cache.

Backpressure đi qua `instr_gnt_i`; prefetch giữ `valid_req_q`/`stored_addr_q` khi grant thấp. Branch không được tự bỏ bus obligation đã cấp; đánh dấu discard rồi drain response. Fetch FIFO→IF có `valid/ready`, đóng gói instruction 16/32-bit; out address halfword-aligned, `err_plus2` phân biệt lỗi ở word sau. Reset/clear có quyền hủy nội dung logic FIFO; response cũ từ môi trường cần xử lý cùng reset epoch. OQ-04/12.

## Data interface

Producer: LSU → TRVK khi BaseIsa dual, hoặc bypass → external memory. Signal gồm req/gnt/rvalid, write enable, 4 byte enables, addr/data, error, capability tag và integrity. Metadata phải giữ với request tới accepted edge; `data_err_i` chỉ có nghĩa khi rvalid.

**FND-LSU-01:** Một misaligned word hoặc halfword vượt biên word trở thành hai word-aligned bus accesses; request completion (`lsu_req_done_o`) và final response (`lsu_resp_valid_o`) khác nhau. **Support:** SUPPORTED [RTL:ESTABLISHED], BASE-01 RV32 path, `ibex_load_store_unit.sv:402`, FSM và outputs 632/694; giả định ASM-BUS-01.

Architecture không phát tự do vô hạn requests: controller/WB giữ một memory instruction đang chờ, nhưng split/capability có thể có hai accepted word requests. Top ghi `MaxOutstandingDSideAccesses=2`, có assertion tracker dưới instrumentation. Không gọi capacity bằng số bit address hoặc số tag bit.

PMP chặn external request và sinh completion lỗi nội bộ; CHERIoT access violation cũng có đường không phát request. ECC có path error/alert riêng; không đồng nhất `data_err` với mọi lỗi tính toàn vẹn.

## Simple System data bus

**FND-BUS-01:** `shared/rtl/bus.sv` lưu duy nhất host/device selection của cycle trước và không có device grant/ready. Nó đòi hỏi mọi device phản hồi sau đúng một cycle. **Support:** SUPPORTED [RTL:ESTABLISHED], BASE-01 bus source, ASM-BUS-02. Đây là contract bắt buộc khi tái sử dụng bus, không phải bus tổng quát hỗ trợ arbitrary latency.

Host priority thấp index thắng; device decode nếu chồng lấn thì index cao thắng do assignment sau ghi đè. CFG-simple-source có một host, ba vùng không chồng lấn. Decode miss vẫn grant host, cycle sau `decode_err_resp` đưa rvalid/error; dữ liệu không có nghĩa khi error. Không có timeout/arbitration fairness cho multi-host được kiểm chứng.

## Capability và revocation bitmap

`data_tag_o/i` là sideband validity, không phải transaction ID hay ECC bit. Capability trên memory là pointer word + metadata word với tag; RF có 35-bit `cap_t` metadata bổ sung correction bits.

TRVK request fork cần downstream và alignment FIFO cùng hoàn tất acceptance; từng nhánh có thể handshake ở cycle khác nhau và fork nhớ nhánh đã nhận. Response được FIFO giữ, join bitmap khi cần rồi gửi upstream không có ready. Bitmap có req/gnt/rvalid, address word-aligned, 32-bit data +7 integrity +err; chỉ một outstanding lookup.

`RevbmReqStable_A`, `AlignValidOnRsp_A`, `DsRspFifoNoOverflow_A`, `RevbmRspOnlyWhenOutstanding_A` là vị trí checker nguồn, không phải chứng minh đã pass. Bitmap response cùng cycle grant đầu tiên không thỏa assertion outstanding-q; chọn contract response từ cycle sau (ASM-CAP-02). Môi trường không được tự gửi bitmap response vì `upstream_tag_o` bị ảnh hưởng trực tiếp bởi rvalid bitmap.

## Control, debug, cache và RF boundary

| Interface | Contract nguồn và state owner | Integration gap |
|---|---|---|
| IRQ software/timer/external/fast/NMI | Mip combinational, mie gate, controller lấy trap | Đồng bộ input/level duration; wakeup khác trap acceptance |
| debug_req | Wake clock + controller debug entry, external debug memory | Simple tie-off 0; không có JTAG/DM trong top này |
| fetch_enable / mcounteren_writable / cheriot_enable | MuBi 4-bit; mode/permission control, không phải bus handshake | Stable/trusted controls, mode switch protocol chưa chốt |
| RF ở ibex_core | Hai read ports, một write port; data/cap widths theo ECC; WB owns write | Top chọn implementation và feedthrough/clock behavior |
| Cache SRAM ports | Request/write/address/data cho tag/data mỗi way | RAM read latency/collision/config backend phải tương thích |
| scramble_req/key_valid | Top giữ request tới valid, chốt key/nonce; reset có default key | Nguồn key synchronous? Renewal liveness; OQ-08 |
| alert/crash/lockstep shadow | Error/status ra platform | Simple bỏ ngỏ outputs; không có platform escalation được kiểm |
| RVFI | Quan sát retirement với order/PC/register/memory/cap fields | Tracer chỉ ghi; checker phải khớp fields và mode |

Không có kết quả protocol monitor/assertion activity trong phiên này. Nguồn cho phép xác lập boundary; các đảm bảo động phụ thuộc OQ-01/04/05/06/12.
