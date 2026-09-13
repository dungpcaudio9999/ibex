# 07 — Timing và tài nguyên theo góc nhìn thiết kế

Có thể đánh giá cycle behavior và cấu trúc register/combinational paths từ RTL
và elaboration hiện tại. Chưa có công nghệ đích, library, SRAM macro timing,
clock target hay physical constraints, nên **chưa có Fmax, gate area hoặc power**.
Không đổi các số bit bên dưới thành diện tích vật lý hay dùng runtime mô phỏng
để ước lượng hiệu năng CPU.

## Cycle behavior đã đo

| Quan sát | Kết quả | Điều kiện |
|---|---|---|
| ADD/MUL ID occupancy | 1/1 cycle | D1, cache runtime off, no dummy, straight-line window |
| MULH ID occupancy | 2 cycles | Operand/case cụ thể trong arithmetic |
| DIV nonzero | 37 cycles ID, 36 stall counter events | DIT off và on đều đo |
| DIV by zero | 2 off / 37 on | CSR setup token được kiểm trực tiếp từ hex |
| Branch DIT | 2 cycles cho taken và not-taken | Không branch predictor |
| D4 load grant→write | 4 cycles | Grant mỗi 3 root cycles, response delay 4 |
| Younger independent ADDI | Write sau load 1 cycle | Có WB nhưng không issue quanh pending load |
| Cached loop `addi; bne` | 3 cycles/iteration trong cửa sổ 300…600 | 99 intervals, tất cả bằng 3 |
| Cùng loop lúc initial invalidate | 5 cycles/iteration trong cửa sổ 80…240 | 31 intervals, tất cả bằng 5; đang dùng bypass |
| Capability roundtrip | 6 data beats, 2 bitmap requests | Load→store→load, D4; xem bảng instruction flow |
| WFI | Đủ 20 root sleep cycles được quan sát | Wake event281, completion marker284 |

Khoảng 3 cycles cho loop hai lệnh cho thấy redirect overhead ngay cả khi cache
đã warm. Không chuyển nó thành CPI trung bình của mọi workload. D1/D4 là memory
model; số miss/hit toàn run gồm self-loop sau marker nên không dùng để tính
finite-workload miss rate. [Machine-readable timing](evidence/timing.json),
[measurement/checker](scripts/analyze.py).

## Inventory cấu trúc, không phải synthesis area

| Thành phần | Tính từ giá trị elaborate | Ý nghĩa |
|---|---:|---|
| Main dual-mode RF | `16×32 + 16×35 = 1072` payload FF bits | Bao gồm entry0 dùng cho dummy/shared x16 |
| Shadow RF parity banks | `16×7 + 16×7 = 224` FF bits | Parity, không phải RF dữ liệu thứ hai 1072 bit |
| Tổng hai loại RF storage | 1296 bits | Chưa tính input-delay registers, mux/decode/ECC logic |
| Cache instruction payload | `2×256×64 = 32768` bits = 4 KiB | 2 ways, 256 lines/way, line 8 bytes |
| Cache data arrays gồm ECC | `2×256×78 = 39936` bits | Hai 39-bit codewords/line |
| Cache tag arrays gồm ECC | `2×256×28 = 14336` bits | Tag+valid 22, ECC 6 |
| Tổng tag/data arrays | 54272 bits = 6784 bytes | 6.625 KiB raw storage; không phải dung lượng cache dành cho instruction |
| Programmable-width HPM counters | `10×32=320` bits/core | Events 3…12 cố định; không đếm logic cập nhật |
| mcycle + minstret | `2×64=128` bits/core | Cộng với HPM là 448 logical counter bits/core; chưa tính speculative bookkeeping |
| Cache fill buffers | 4/core cache controller | Không có nghĩa 4 outstanding data instructions |
| Maximum D-side outstanding | 2 access beats | Một instruction split; TRVK tổ chức theo giới hạn đó |
| Bitmap address space | 11 byte-address bits = 2 KiB bitmap | Một bit / 8-byte capability → 128 KiB covered heap window |
| PMP/debug | 16 regions/core, 1 execute trigger/core | Main/shadow logic đều được elaborate |

Cache arrays shared tại top; không nhân đôi dung lượng thành 8 KiB chỉ vì có
hai core. Các controller, compare/input pipelines, PRINCE/address-scramble state,
LSU/TRVK/CSR/capability-special state và routing vẫn có chi phí ngoài inventory
trên. Logic có thể được tối ưu theo mapping; raw declared state không bằng số
cell thực tế.

Nguồn: [cache constants](../../../rtl/ibex_pkg.sv#L400),
[width localparams](../../../rtl/ibex_top.sv#L212),
[RF FF banks](../../../rtl/ibex_register_file_ff.sv#L85),
[bitmap addressing](../../../rtl/ibex_trvk.sv#L293),
[actual hierarchy/parameters](evidence/hierarchy.json).

## Danh sách đường timing cần review trong STA

Đây là **các ứng viên đường dài theo cấu trúc**, chưa có thứ tự criticality.
Một path list tốt ghi rõ launch/capture, điều kiện hoạt động và hậu quả nếu cần
thêm register; không kết luận “multiplier chắc chắn critical” từ tên khối.

| Launch / nguồn | Logic giữa các mốc | Capture / đích | Điều kiện và đánh đổi |
|---|---|---|---|
| RF FF hoặc WB result | RF mux → forwarding → operand select → ALU/B result mux | WB result FF | BOTEarlGrey tăng logic operator; chọn operand/forwarding cũng nằm trong path |
| RF/operand state | Fast multiplier partial products và kết hợp | WB/intermediate M-D state | MUL 1 cycle khiến arithmetic depth nằm trong cycle; thêm stage sẽ đổi stall/forwarding |
| Divider/intermediate state | Shared arithmetic, compare, remainder/quotient selection | M-D state FF | Multi-cycle latency không tự tạo multicycle timing exception cho từng đường tổ hợp |
| IF-ID PC và operands | Compare + branch-target ALU → redirect select | Frontend PC/prefetch state | BTALU giảm sequencing nhưng cần xét fanout/redirect logic |
| LSU address/capability state | Address arithmetic → bounds/permission/PMP → request qualification | Bus output hoặc request state | Output delay/load của interconnect là constraint thiết yếu |
| Data response input | Integrity/byte assembly → WB selection + valid qualification | RF write state | Late external arrival có thể chi phối; error-to-control cần kiểm tách đường |
| Cache IC0 state | Index/way arbitration → address scramble → RAM input | SRAM macro | Cần macro setup, write mask và clock topology thực tế |
| SRAM read output / IC1 state | Descramble/tweak/ECC/tag compare/way select/alignment | Fetch/IF-ID state | Macro access time và placement có thể lớn hơn logic ALU |
| Capability operand/state | Bounds decode/permissions/result compression | CHERIoT/WB result state | Không dùng timing RV32I-only để đại diện mode capability |
| Pending capability/bitmap input | Bitmap address/selection, ECC, tag qualification | TRVK/output state | Cần constraint bitmap provider; pending request không được mất association |
| Delayed main/shadow outputs | Wide equality/reduction + error aggregation | Alert interface | Xác định downstream capture/response deadline; preserve redundancy |
| Busy register + IRQ/debug | Clock-enable logic → clock gate | Gated clock domain | Clock-gating checks, reset recovery/removal và test enable cần constraints riêng |

Điểm bắt đầu đọc RTL: [EX](../../../rtl/ibex_ex_block.sv),
[ALU](../../../rtl/ibex_alu.sv), [M/D](../../../rtl/ibex_multdiv_fast.sv),
[PMP](../../../rtl/ibex_pmp.sv), [LSU](../../../rtl/ibex_load_store_unit.sv),
[cache arbitration](../../../rtl/ibex_icache.sv#L249),
[CHERIoT EX](../../../rtl/ibex_cheriot_ex.sv),
[lockstep compare](../../../rtl/ibex_lockstep.sv#L729).

## Cách chuyển baseline này sang quyết định thiết kế

Giữ cấu hình hiện tại làm reference. Khi có target, thêm library/corners, clock
period/uncertainty, input/output delays, SRAM models, generated/gated clock rules,
reset/test-mode constraints và redundancy-preservation constraints. Chạy synthesis
và STA để lấy path thực tế, sau đó dùng workload đại diện đo cycles, cache misses,
interrupt latency và toggle activity. Mỗi đề xuất thay pipeline/cache/ECC phải
được kiểm lại cả architectural ordering lẫn thời hạn detection/reaction.

Trước đó, các quyết định có bằng chứng ở mức CPU là: memory latency ảnh hưởng
trực tiếp do outstanding-load blocking; cache warm giảm fetch/branch loop cost;
DIT tăng worst-case latency của divide-by-zero; bitmap làm capability completion
phụ thuộc hệ thống; lockstep và protection state có chi phí nhưng không có đủ
dữ liệu để gán phần trăm area/power. Không đề xuất tắt protection để “tối ưu”
khi chưa có yêu cầu threat model và PPA cụ thể.
