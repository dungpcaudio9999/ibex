# Ibex theo preset opentitan — CPU design analysis

Phân tích đúng `opentitan` trong checkout tại revision
`ec501f4ce5a7e492e1becb48b31200019ec5200b`, giữ production RTL/YAML. Bao gồm
RV32I và CHERIoT runtime modes của cùng một phần cứng; không đại diện một full
OpenTitan SoC release.

**Hoàn tất O1…O7:** 19/19 preset parameter checks, 54/54 directed runs,
90/90 trace/run checks, 1 negative control; lưu 23 waveforms.
[Báo cáo kiểm tra](evidence/validation_report.json).

| Đọc theo thứ tự | Câu hỏi kỹ sư thiết kế cần trả lời |
|---|---|
| [PLAN](PLAN.md) | Phạm vi, phương pháp và tiêu chí hoàn tất |
| [01 — Configuration](01_configuration.md) | Chính xác hardware nào được elaborate? |
| [02 — Contracts/modes](02_contracts_modes.md) | Software và SoC phải cung cấp điều kiện nào? |
| [03 — Datapath/state](03_datapath_state.md) | Instruction/state đang ở đâu, ai cho nó tiến hoặc flush? |
| [04 — Instruction flows](04_instruction_flows.md) | Từng loại instruction hoàn tất qua cả CPU thế nào? |
| [05 — Interactions](05_interactions.md) | Load/error/debug/IRQ/Zcmp/cache/capability cắt ngang nhau ra sao? |
| [06 — Security](06_security.md) | Cơ chế nào phát hiện lỗi nào, và giới hạn protection ở đâu? |
| [07 — Timing/resources](07_timing_resources.md) | Chi phí cycle/state và những path cần review trong STA? |
| [08 — Validation/findings](08_validation_findings.md) | Đã chứng minh gì, chạy lại thế nào, còn giới hạn nào? |

Nên review kỹ ba điểm: WB vẫn block lệnh trẻ khi load pending; Zcmp có debug/IRQ
boundary khác nhau; capability completion phụ thuộc tag/bitmap ngoài CPU.
Counter/DIT/cache measurements và RF/cache resource inventory đã tách khỏi
các thông số vật lý chưa đo. Chưa có Fmax/area/power hay security sign-off.

Tài liệu nền: [microarchitecture](../microarchitecture/13_completion_results.md),
[Secure Ibex plan](../secure_ibex/PLAN.md). Bộ này bổ sung bằng chứng exact-preset,
giữ nguyên các artifact trước để có thể đối chiếu.
