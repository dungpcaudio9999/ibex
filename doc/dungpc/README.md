# Phân tích mã nguồn Ibex — BASE-01

Bộ tài liệu thực hiện theo [RTL and SoC Source Analysis Guide v3.1](rtl_soc_source_analysis_guide_v3.1.md), lưu tại `doc/dungpc` theo yêu cầu. Ngày phân tích: **2026-09-08**. Mục tiêu: hiểu kiến trúc, giao dịch và rủi ro tích hợp của local Ibex/CHERIoT, dùng Simple System để lần theo luồng phần mềm/phần cứng.

**Trạng thái: COMPLETE-WITH-LIMITATIONS cho phân tích nguồn. Chưa có active elaboration hoặc mô phỏng RTL.** Môi trường thiếu FuseSoC/simulator; các kiểm tra đã chạy là inventory/configuration và mô hình Python được định danh riêng. Xem [kết luận và gate assessment](16_final_summary.md) trước khi sử dụng làm căn cứ kỹ thuật.

## Baseline và cấu hình

Source revision `8031c7dde749bb9d62391e5befbe55f1c014a171`; tracked source sạch, patch nguồn rỗng. Hash3.694 files gồm vendor/config/generator inputs/firmware source. [Snapshot](evidence/baseline.json), [source hashes](evidence/source_manifest.json), [analysis artifact hashes](evidence/artifact_manifest.json).

`CFG-small-intent` và `CFG-opentitan-intent` là named YAML configs; `CFG-simple-source` là defaults/tie-offs đọc từ RTL; `CFG-formal-source` là harness RV32I riêng. **Không đồng nhất các cấu hình này**: đường BaseIsa chưa thống nhất, và UVM enum macros có mismatch consumer (FND-BUILD-01/03). Mọi kết luận nguồn có scope trong [00_scope](00_scope.md).

## Tài liệu và stage applicability

Tất cả rows valid cho BASE-01 ở scope source nêu trên. COMPLETE mô tả công việc tài liệu; không có nghĩa design verified. CONDITIONAL là stage được kích hoạt bởi feature/risk cụ thể.

| Stage / tài liệu | Mục đích | Applicability / lý do | Work status | Limitations |
|---|---|---|---|---|
| [00_scope](00_scope.md) | Mục tiêu, boundaries, gates | REQUIRED — áp dụng mọi objective | COMPLETE | Reviewer chưa chỉ định, không có sign-off |
| [01_repository_baseline](01_repository_baseline.md) | Source/execution snapshot | REQUIRED — áp dụng mọi objective | COMPLETE-WITH-LIMITATIONS | Execution baseline không establish |
| [02_source_inventory](02_source_inventory.md) | Source/dependency/target candidates | REQUIRED — architecture | COMPLETE-WITH-LIMITATIONS | Inventory không là active file list |
| [03_build_and_configuration](03_build_and_configuration.md) | Options, parameters, defines | REQUIRED — architecture | COMPLETE-WITH-LIMITATIONS | OQ-01/02, không elaborate |
| [04_architecture](04_architecture.md) | Blocks và owned state | REQUIRED — architecture | COMPLETE-WITH-LIMITATIONS | Sơ đồ nguồn, không hierarchy dump |
| [05_interfaces](05_interfaces.md) | Request/response/reset contracts | REQUIRED — architecture | COMPLETE-WITH-LIMITATIONS | Boundary assumptions chưa monitor |
| [06_clock_reset_and_power](06_clock_reset_and_power.md) | Gating/wakeup/reset/crossing | CONDITIONAL — clock gate/reset/test tồn tại | COMPLETE-WITH-LIMITATIONS | CDC/RDC/STA NOT-RUN |
| [07_memory_and_address_map](07_memory_and_address_map.md) | Decode, aliases, boot/linker | CONDITIONAL — Simple memory/MMIO/PMP | COMPLETE-WITH-LIMITATIONS | Chưa có ELF/macro implementation run |
| [08_registers_and_interrupts](08_registers_and_interrupts.md) | CSR/MMIO/IRQ semantics | CONDITIONAL — CPU CSR/timer | COMPLETE-WITH-LIMITATIONS | CSR ưu tiên theo flow, không exhaustive field audit |
| [09_system_flows](09_system_flows.md) | Bảy luồng hai chiều | REQUIRED — architecture | COMPLETE-WITH-LIMITATIONS | Không waveform hoặc measured cycle latency |
| [10_module_analysis](10_module_analysis/README.md) | Mười module groups ưu tiên | CONDITIONAL — state/ownership/security risks | COMPLETE-WITH-LIMITATIONS | Invariants chưa formal/RTL run |
| [11_verification_analysis](11_verification_analysis.md) | Requirements→checker và proof scope | CONDITIONAL — uncertain behavior/checker risks | COMPLETE-WITH-LIMITATIONS | Coverage/activation/ISS/formal NOT-RUN |
| [12_experiments](12_experiments.md) | Dự đoán, lệnh và actual outcomes | CONDITIONAL — kiểm config/arithmetic assumptions | COMPLETE-WITH-LIMITATIONS | Chỉ source tools và Python model |
| [13_open_questions](13_open_questions.md) | Questions/assumptions/dependency | REQUIRED — áp dụng mọi objective | COMPLETE | 12 OQ OPEN, chưa waiver |
| [14_change_impact](14_change_impact.md) | Tác động sửa đổi giả định | CONDITIONAL — hướng dẫn đọc/sửa về sau | COMPLETE-WITH-LIMITATIONS | Không triển khai patch hoặc regression |
| [15_glossary](15_glossary.md) | Thuật ngữ và identifier | REQUIRED — áp dụng mọi objective | COMPLETE | Không có claim verification |
| [16_final_summary](16_final_summary.md) | Findings, gates, next steps | REQUIRED — áp dụng mọi objective | COMPLETE-WITH-LIMITATIONS | Active architecture LIMITED, sign-off chưa establish |

## Thứ tự đọc

Đọc nhanh: [kết luận](16_final_summary.md) → [architecture](04_architecture.md) → [flows](09_system_flows.md) → [questions](13_open_questions.md).

Để tái lập: [baseline](01_repository_baseline.md) → [build/config](03_build_and_configuration.md) → [experiments](12_experiments.md) → [evidence index](evidence/README.md). Để chuẩn bị tích hợp: thêm interfaces, clock/reset, memory/CSR và các module ưu tiên; xem change impact trước khi sửa.

## Các hạn chế quyết định

Active top/config chưa được xác nhận. Simple bus chỉ hỗ trợ response1-cycle. Simple/UVM test top giữ CHERIoT runtime Off, formal harness chọn RV32I; không có evidence end-to-end capability/revocation. Macro assertions qua header hiện tại bị bỏ khi VERILATOR/SYNTHESIS. CDC/reset, mode switch, bitmap service và secure/cache backend còn cần validation.

Những limitation này được báo công khai, **chưa được owner chấp nhận thay cho kiểm chứng cần thiết**. Không sửa source guide, RTL, build config hoặc firmware; chỉ thêm tài liệu, scripts và evidence trong thư mục này.

## Kiểm tra bộ tài liệu

[validation_report.json](evidence/validation_report.json) ghi kiểm tra liên kết cục bộ, source hashes, stable finding IDs, nhãn bằng chứng và tính toàn vẹn source. Các kiểm tra đó xác nhận sự nhất quán cơ học của deliverable, không là review kỹ thuật độc lập hoặc chứng minh RTL đúng.
