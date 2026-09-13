# Phân tích microarchitecture Ibex / CHERIoT

Ngày thực hiện: 2026-09-13. Baseline source: `fc3b3dd6`.
Ngôn ngữ: tiếng Việt, giữ tên RTL để tìm kiếm.

Đã lưu và thực hiện [kế hoạch](PLAN.md): phân tích datapath, state/FSM, stall,
forwarding, transaction và exception boundary từ RTL; thêm mô phỏng với bảng
từng chu kỳ. **160 core runs và 20 CHERIoT module checks PASS trong phạm vi
checker đã mô tả.** Đợt bổ sung có **21 top runs PASS**, gồm cache/predictor/Zcb/Zcmp,
debug/WFI/NMI, CHERIoT end-to-end và PMP; xem [báo cáo hoàn tất](13_completion_results.md)
và [throughput](14_throughput.md). Chuyên sâu bảo vệ ở [Secure Ibex](../secure_ibex/PLAN.md).

## Mục lục và thứ tự đọc

| Chương | Nội dung | Mức bằng chứng |
|---|---|---|
| [01 Configuration](01_configuration.md) | Cấu hình active, memory contract, source baseline | Build/elaboration + source |
| [02 Pipeline](02_pipeline.md) | Stage/register boundaries, valid/ready, side effects | Source + core simulation |
| [03 Fetch](03_fetch.md) | PC, outstanding/discard, FIFO/aligner | Source + branch/compressed tests |
| [04 Execution](04_execution.md) | Decode/RF/mux/ALU, mult/div FSM | Source + arithmetic tests |
| [05 Hazards/WB](05_hazards_writeback.md) | Forwarding, load-use, precise exception ordering | Source + WB0/WB1 tests |
| [06 LSU](06_lsu.md) | Requests/responses, byte lanes, split/error | Source + transactions/mtval tests |
| [07 Controller/CSR](07_control_csr.md) | Trap/IRQ/debug/return/WFI | Source + selected directed tests |
| [08 Variants/cache](08_variants_cache.md) | BTALU, cache fill tracking, predictor, Zcmp | Source + core/top directed simulation |
| [09 CHERIoT/protection](09_cheriot_protection.md) | Cap representation/EX/LSU/TRVK/PCC, PMP/ECC/lockstep | Source + unit/top CHERIoT tests |
| [10 Timing](10_timing.md) | Bảng chu kỳ trích từ logs, so sánh cấu hình | Measured RTL simulation |
| [11 Results](11_validation_and_findings.md) | Findings, trade-offs, limitations, reproduction | Scope và evidence index |

Đọc trọng tâm: **02 → 05 → 10 → 06 → 09**. Đọc 01 trước khi áp dụng các số đo.
Tài liệu tổng quan trước đó ở [thư mục cha](../README.md) vẫn giữ baseline/lịch sử
của nó; không thay kết quả source-only cũ bằng các run mới mà không ghi scope.

## Kết quả đáng chú ý

- WB1 vẫn đợi memory access cũ resolve để giữ exception chính xác. Load-use còn
  stall ngay response cycle vì không forward incoming load data vào arithmetic path.
- LSU ở IDLE không đồng nghĩa không còn response pending; ownership chia giữa
  LSU address FSM và ID/WB instruction state.
- Split fault đầu báo byte address gốc, split fault sau báo địa chỉ word sau.
- Fast MUL/MULH đo 3/4 cycles ID; SingleCycle đo 1/2; số đo DIV ví dụ là 37.
- TRVK đợi bitmap để trả metadata khi cần lookup, clear tag khi revoked hoặc
  bitmap error; toàn capability validity còn phụ thuộc tag cả hai memory words.

## Evidence chính

- [Core results](evidence/core_results.json), [trace checks](evidence/trace_checks.json),
  [unit results](evidence/unit_results.json), [negative checker control](evidence/negative_control.json).
- [Small hierarchy/parameters](evidence/small.hierarchy.json),
  [WB hierarchy/parameters](evidence/wb.hierarchy.json),
  [source dependency hashes](evidence/source_dependencies_sha256.json).
- [Validation report](evidence/validation_report.json),
  [scripts/harness entry](scripts/run_core.py).

Đây là phân tích microarchitecture có directed experiments, không phải ISA
compliance, coverage closure, formal proof hoặc PPA/sign-off report.
