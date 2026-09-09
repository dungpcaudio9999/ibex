# 00 — Phạm vi phân tích Ibex

Phân tích theo [RTL and SoC Source Analysis Guide v3.1](rtl_soc_source_analysis_guide_v3.1.md), ngày 2026-09-08. Ngôn ngữ diễn giải: tiếng Việt; tên RTL, trạng thái và nhãn bằng chứng giữ nguyên để tìm kiếm được.

## Mục tiêu và quyết định

Mục tiêu chính là **Basic architectural understanding**: một kỹ sư có thể giải thích kiến trúc, xác định nơi sở hữu trạng thái, lần theo các luồng quan trọng và biết điều kiện cần kiểm tra trước khi tích hợp hoặc sửa RTL. Người dùng chưa chỉ định lỗi cần debug, thay đổi chức năng hay nền tảng silicon; vì vậy báo cáo khảo sát toàn repository rồi ưu tiên CPU, các thay đổi CHERIoT và Simple System làm ví dụ tích hợp cụ thể.

Đây là kết quả phân tích nguồn có giới hạn, không phải chứng nhận tuân thủ ISA, hoàn tất verification hoặc tapeout sign-off. Không lấy điểm benchmark, trạng thái nightly hay tuyên bố proof trong README làm kết quả chạy của checkout này.

## Baseline và cấu hình

- `BASE-01`: commit `8031c7dde749bb9d62391e5befbe55f1c014a171`; nguồn tracked sạch, patch nguồn rỗng. [Snapshot](evidence/baseline.json) và [manifest SHA-256](evidence/source_manifest.json).
- `CFG-small-intent`: cấu hình `small` trong `ibex_configs.yaml`, ý định RV32I, RV32MFast, Zca, pipeline hai tầng, không cache/PMP/security.
- `CFG-simple-source`: top ứng viên `ibex_simple_system`, giá trị mặc định đọc trực tiếp từ RTL; **BaseIsa dual RV32I/CHERIoT**, nhưng `cheriot_enable_i=IbexMuBiOff`. Đây không phải cấu hình small đã elaborate.
- `CFG-opentitan-intent`: cấu hình `opentitan` trong YAML dùng dual ISA, pipeline ba tầng, cache/ECC/scrambling, PMP và SecureIbex. Chỉ đối chiếu những khác biệt có ảnh hưởng kiến trúc.
- `CFG-formal-source`: harness `dv/formal/check/top.sv` cưỡng bức `BaseIsaRV32I`. Không đồng nhất với các cấu hình trên.

Các tên `*-intent` là cấu hình mong muốn, `*-source` là nhánh nguồn suy ra có điều kiện. **Chưa có cấu hình active được xác nhận bằng elaboration**; xem OQ-01 và OQ-02.

## Ranh giới và độ sâu

Trong phạm vi: manifest/dependency; `ibex_top`/`ibex_core`; IF/ID/EX/WB, prefetch/FIFO, LSU, CSR/controller, RF; boundary CHERIoT/PMP/TRVK; clock gate/reset/wakeup; RAM/bus/timer/simulator control và firmware khởi động của Simple System; testbench, checker và giả định formal.

Cache, nhân/chia, ECC, lockstep và primitive được đọc ở mức chức năng, lựa chọn generate, cấu hình, interface và rủi ro. Phân tích chuyên sâu ở Stage 10 tập trung các module sở hữu giao dịch, flush, quyền truy cập và ngắt; không duyệt chứng minh từng opcode/biểu thức số học của toàn bộ 25.816 dòng RTL gốc.

Ngoài mục tiêu hiện tại: đo PPA/CoreMark; chạy toàn bộ UVM/formal; chứng minh mọi phép toán CHERIoT theo ISA; triển khai FPGA/ASIC; phân tích cell library, MTBF, ATPG hoặc side-channel. Các kiểm chứng liên quan vẫn được ghi `NOT-RUN`, không dùng thiếu công cụ làm lý do `NOT-APPLICABLE`.

## Luồng được chọn

1. `FLOW-BOOT-01`: reset → vector → fetch → instruction được thực thi.
2. `FLOW-IF-01`: grant bị trì hoãn, branch/FENCE.I → bỏ response cũ và chuyển PC.
3. `FLOW-LSU-01`: load/store aligned và split misaligned → writeback hoặc exception.
4. `FLOW-IRQ-01`: timer → mip/mie → controller → trap handler → mret.
5. `FLOW-PWR-01`: WFI → gated clock → IRQ/debug wakeup.
6. `FLOW-CAP-01`: capability load hai word → TRVK bitmap → cập nhật capability/tag.
7. `FLOW-ERR-01`: lỗi bus/quyền/ECC → recovery, alert và giới hạn quan sát.

## Bằng chứng và gate

| Gate | Điều kiện hoàn tất | Đánh giá phiên này |
|---|---|---|
| G-01 | Nhận diện nguồn và dependency tái lập được | MET — hash 3.694 file tracked, patch và lockfiles |
| G-02 | Active top/parameter/define/primitive được xác nhận | LIMITED — chỉ có ý định và phân tích nguồn, thiếu elaborator |
| G-03 | Kiến trúc, interface, state và flow có dẫn chứng | MET trong phạm vi và độ sâu đã nêu |
| G-04 | Phân biệt yêu cầu, suy luận, kết quả chạy và gap | MET — chỉ có chạy Python, không có chạy RTL |
| G-05 | Có lệnh/artifact để lặp lại kiểm tra đã làm | MET — evidence scripts, logs, checksums |
| G-06 | Unknown quyết định tích hợp được giải quyết/chấp nhận | NOT-MET — OQ mở; chưa có người phê duyệt rủi ro |

Trạng thái tổng: **COMPLETE-WITH-LIMITATIONS** cho tài liệu phân tích nguồn; hiểu biết kiến trúc active ở mức **LIMITED**. Không diễn giải G-06 thành sự chấp thuận của người dùng.

## Applicability, chủ trì và điểm dừng

Quyết định từng Stage 0–16 nằm ở [README](README.md). Stages 6–8, 10–12 được kích hoạt do clock gating, CSR, giao dịch split và CHERIoT. Stage 14 chỉ là đánh giá các thay đổi giả định, không thực hiện sửa RTL.

Chủ trì tạo báo cáo: Codex. Reviewer/decision owner: người duy trì dự án, **chưa được chỉ định cụ thể**. Các vai trò trong OQ là đề xuất, không phải giao việc đã được chấp thuận.

Không có ngân sách thời gian do người dùng đặt. Điểm rà soát của phiên này là sau inventory/configuration, bảy luồng, các module ưu tiên, kiểm tra nguồn/mô hình và kiểm tra tài liệu ngày 2026-09-08. Dừng ở deliverable có bằng chứng và giới hạn minh bạch; không cài toolchain hay chuyển mục tiêu sang sửa thiết kế. Mọi file được tạo nằm trong `doc/dungpc`.
