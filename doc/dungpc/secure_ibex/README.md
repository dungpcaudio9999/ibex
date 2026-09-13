# Phân tích chuyên sâu Secure Ibex / CHERIoT

Đã lưu và triển khai [plan S1–S7](PLAN.md), trên checkout `fc3b3dd6`.
**40 top-level directed runs + 31 analysis checks PASS**, có fault injection,
waveform, archived harness, lệnh build và effective parameter evidence.
Không sửa production RTL. [Kết quả và giới hạn](06_experiments_findings.md).

| Thứ tự đọc | Nội dung |
|---|---|
| [01 — Configuration/threat model](01_configuration_threat_model.md) | SecureIbex bật gì, runtime/compile-time, trust boundaries |
| [02 — Lockstep/RF](02_lockstep_register_file.md) | Input/output delay, reset/clock/compare, shared RF và independent checkbits |
| [03 — Integrity/alerts](03_integrity_alerts.md) | Bus ECC, response ownership, PC/MuBi, NMI và containment |
| [04 — Timing/dummy](04_timing_dummy.md) | DIT branch/multdiv, LFSR/seed/mask, architectural isolation |
| [05 — Cache/integration](05_cache_and_integration.md) | ECC/refetch, tweak, scramble/key lifecycle; CHERIoT/PMP/debug |
| [06 — Findings/closure](06_experiments_findings.md) |40 runs, fault matrix, conclusions/limitations, đối chiếu S1–S7, reproduction |
| [07 — Measurements](07_measured_tables.md) | ID timing và observed detector latency |

Điểm cần nhớ: main RF giữ data/cap, shadow RF giữ checkbits; ShadowCSR=0;
lockstep phát hiện lỗi nhưng không rollback side effect. Load integrity error
đi qua internal NMI, trong khi bitmap error clear cap tag và báo top bus alert.
DIT làm phẳng execution latency của các đường đã cài, không chứng minh power
hoặc toàn hệ thống independent of secrets.

[Results](evidence/results.json) · [Checks](evidence/analysis_checks.json) ·
[Validation](evidence/validation_report.json) ·
[Microarchitecture đã hoàn tất](../microarchitecture/13_completion_results.md).
