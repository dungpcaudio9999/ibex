# Kế hoạch phân tích chuyên sâu Secure Ibex

Ngày lưu: 2026-09-13, sau khi hoàn tất phạm vi microarchitecture A–H và chạy
21 ca top bổ sung. Người dùng đã yêu cầu lưu và triển khai toàn bộ kế hoạch;
không cần chờ duyệt lại giữa các bước. Baseline: checkout `fc3b3dd6`.

## Mục tiêu

Giải thích từng countermeasure bằng datapath, state, timing và fault propagation:
fault ở đâu → được quan sát khi nào → detector nào → alert/exception/side effect.
Đặc biệt kiểm tra những khác biệt của fork CHERIoT với mô tả Ibex thông thường.
Tách SOURCE, INFERRED, SIM; không suy ra bảo đảm chống mọi tấn công từ directed test.

## Trình tự và đầu ra

| Bước | Phân tích / câu hỏi | Kiểm chứng dự kiến | File đầu ra |
|---|---|---|---|
| S1 | Parameter propagation và trust boundary: SecureIbex thực sự bật gì; phần nào tùy chọn/runtime | Elaborate top secure, offset1/2, cache ECC+scramble, dual CHERIoT | 01_configuration_threat_model.md |
| S2 | Main/shadow lockstep, delay registers, reset/compare enable, clock gate, output compare và RF parity | No-fault workloads; reset/WFI/debug; inject main EX/RF divergence | 02_lockstep_register_file.md |
| S3 | Bus/RF/cap ECC, PC increment, MuBi, response ownership, alert aggregation và exception boundary | Corrupt instruction/load data giữ ECC; RF/PC fault; invalid mode; unsolicited response; bitmap fault | 03_integrity_alerts.md |
| S4 | Data-independent timing, branch/multdiv, dummy insertion, seed/mask, architectural isolation | DIV zero/nonzero khi DIT off/on; branch taken/not-taken; dummy workload với final-state check | 04_timing_dummy.md |
| S5 | I-cache ECC, tweak infection, scramble data/address/key protocol và recovery | Bật cache, hit/miss/FENCE.I/key exchange; inject cache read corruption | 05_cache_and_integration.md |
| S6 | Secure × CHERIoT/PMP/debug; shared assets và assumptions ngoài core | Tagged capability/revocation trong secure top; xét tag/bitmap và cap RF coverage | 05_cache_and_integration.md |
| S7 | Tổng hợp evidence, fault matrix, observed detection latency, residual risks và closure | Kiểm log/config/source hash/link; giữ failure nếu là RTL finding | 06_experiments_findings.md, README.md |

Mỗi chương phải dẫn file/dòng nguồn, sơ đồ hoặc bảng control/state khi phù hợp,
phương trình detector, phạm vi update/hold/qualify và giới hạn bảo vệ. Tập test
là directed validation cho các đường chính, không exhaustive fault campaign.

## Cấu hình và phương pháp

Dùng `ibex_top` với primitives thực của checkout, WB=1/BTALU=1/RV32MSingleCycle,
FF RF. Đối chiếu nonsecure control từ đợt microarchitecture. Secure baseline
không cache/predictor; config riêng bật cache+ECC+scramble và dual CHERIoT.
Offset2 kiểm nhánh reset counter và input arrays khác offset1. Không sửa RTL.

Reuse harness và encoder tại `../microarchitecture/scripts/`, evidence Secure
ở `evidence/`. Mọi injection chỉ nằm trong harness, ghi điểm/thời điểm/độ dài;
không force alert hoặc comparator output để tự tạo PASS. So sánh run no-fault
trước injection. Log first alert và detector ở cycle thực; không coi alert lặp
nhiều cycle là nhiều independent faults. Fault làm mất tiến triển phải báo rõ.

Các test cache/RF fault có thể cần truy cập hierarchy; nếu simulator không hỗ trợ
một điểm injection thì đổi sang điểm tương đương có mô tả ranh giới chính xác.
Nếu phát hiện RTL issue, lưu reproducer và giải thích mức kết luận, không ngầm
sửa implementation hoặc đổi expected để PASS. Kết thúc là hoàn tất phân tích
và evidence/review findings, không yêu cầu thiết kế phải không có defect.

## Ranh giới kết luận

Không thực hiện silicon glitch/laser/EM campaign, leakage/power measurement,
physical separation/STA/PPA, formal exhaustive proof, synthesis hardening audit,
ISA compliance toàn bộ hay kiểm định entropy. Phân tích assumptions/verification
cần thiết cho các lớp đó và đánh dấu chưa đo; đây không phải chứng nhận bảo mật.

## Trạng thái triển khai

Hoàn tất S1–S7: [README](README.md), [closure/evidence](06_experiments_findings.md).
5 cấu hình actual top,40 directed runs,31 analysis checks; ranh giới mỗi bước
được đối chiếu trong bảng closure, không coi PASS là exhaustive security proof.
