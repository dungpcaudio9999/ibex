# Kế hoạch phân tích CPU theo preset opentitan

Người dùng đã chọn giữ preset `opentitan` trong checkout và yêu cầu triển khai
kế hoạch theo góc nhìn kỹ sư thiết kế CPU. Mọi đề xuất thay đổi cấu hình sẽ được
tách khỏi baseline; không sửa production RTL hoặc YAML trong đợt này.

## Mục tiêu và trình tự

| Bước | Công việc | Đầu ra / điều kiện hoàn tất |
|---|---|---|
| O1 | Freeze revision/YAML; truy vết script/build/top/localparams/generate | 01_configuration.md; so khớp tất cả preset params bằng actual elaboration |
| O2 | Hợp đồng CPU/software/SoC, memory/debug map, mode, key/reset/alerts | 02_contracts_modes.md; harness tôn trọng top defaults và ghi rõ assumptions |
| O3 | Datapath, register boundaries, state ownership, update/hold/flush | 03_datapath_state.md; sơ đồ whole-core và bảng state/priority |
| O4 | Instruction đi qua toàn CPU: ALU/B/M/branch/memory/Zcmp/cap/CSR | 04_instruction_flows.md; source equations và cycle tables từ exact-preset runs |
| O5 | Memory/control/security interactions khi các tính năng cùng tồn tại | 05_interactions.md +06_security.md; directed scenarios và invariants |
| O6 | Review tài nguyên và đường tổ hợp giữa registers | 07_timing_resources.md; latency/throughput measured, structural path hypotheses |
| O7 | Đối chiếu dự đoán→test→trace→checker; findings và closure | 08_validation_findings.md, README; reproducible evidence và limitations |

Kế thừa source analysis microarchitecture/Secure Ibex trước đó, nhưng không
coi các config thí nghiệm trước là toàn preset này. Tập trung phần kết hợp:
BOTEarlGrey, Zcmp, PMP16, debug trigger, MHPM10×32, dual ISA, secure/cache cùng bật.

## Chế độ thực nghiệm

Một binary exact-preset; CHERIoT On/Off là runtime input trước release reset,
cache/DIT/dummy điều khiển bằng CSR trong program. Không dùng cách đổi BaseIsa,
M/B/ZC/cache hardware để làm testcase dễ chạy. Default debug addresses của top
được giữ; ROM debug có mapping riêng, không modulo-alias vào boot ROM.

Memory D1/D4, tagged words và bitmap modeled; reset system dùng epoch cancellation.
Ưu tiên các ca: arithmetic/control/compressed, B và performance counters, PMP,
Zcmp+debug/IRQ, DIV+debug, capability load+debug, cache redirect/invalidate/key,
DIT+dummy, WFI/wake, fetch/load/cache/RF/PC/bitmap faults và đối chứng không lỗi.
Chỉ kết luận properties có source hoặc actual checker; không đổi oracle để che
RTL failure. Simulation FINISH khác architectural program completion.

## Phương pháp kiểm chứng và ranh giới

Lưu source hashes, command, generated params/harness, elaboration XML/hierarchy,
program hex, logs, selected/full compressed waveforms và machine-readable results.
Check protocol ownership, architectural signatures, ordering, active feature
paths và detector classification. Audit assertion activation; Verilator không
mặc nhiên bật lại prim_assert macros. Giữ riêng failures do instrumentation.

Không có target technology/library/clock constraint được người dùng chọn.
O6 thực hiện structural timing/resource review và cycle measurements; không
bịa Fmax/area/power, không biến generic Yosys counts thành physical PPA.
Formal exhaustive proof, silicon fault/leakage campaign, full ISA compliance và
valid runtime mode migration exhaustive nằm ngoài directed analysis này; phải
chỉ rõ điều kiện/thông tin còn cần cho các bước sign-off đó.

Ba mốc review được tổ chức bằng tài liệu: cấu hình/hợp đồng → hoạt động toàn CPU
→ đánh giá thiết kế/evidence. Người dùng đã cho phép triển khai toàn bộ, không
chờ duyệt lại giữa các mốc.

## Trạng thái thực hiện

Đã hoàn tất O1…O7 tại revision `ec501f4ce5a7e492e1becb48b31200019ec5200b`.
Xem [README](README.md) và [closure/results](08_validation_findings.md).
19 parameter checks, 54 directed runs, 90 trace/run checks, một negative control;
23 compressed waveforms. O6 hoàn tất ở mức structural review và cycle evidence
như phạm vi đã xác định, không có physical PPA/STA sign-off. Các chiều verification
chưa quét hết được ghi riêng, không coi directed pass là exhaustive proof.
