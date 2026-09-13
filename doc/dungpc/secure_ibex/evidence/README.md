# Evidence Secure Ibex

Ma trận chính: `results.json` (40 runs), `analysis_checks.json` (31 checks),
`checker_negative_control.json`; dữ liệu source-derived timing trong
`timing_metrics.json`, observed detector cycles trong `detector_metrics.json`.

5 cấu hình chính: secure, secure_offset2, secure_dual, secure_cache, secure_combo.
Mỗi cấu hình có command JSON, harness/runner snapshot, build/elaboration logs,
hierarchy JSON, XML gzip và dependency list. Mỗi run có log và gzip VCD; hex
program dùng chung giữa configs khi cùng case. Source/baseline và SHA256 ở các
manifest. Simulator binaries không lưu trong repo, được build tại /tmp.

`secure_cache_ecc` và `secure_cache_notweak` chỉ là exploratory builds khi điều
tra instrumentation; không có directed results và không thuộc40runs chính.
`instrumentation_issue/` giữ harness/log/waveform của thử nghiệm force vào biến
mux RMW gây no-fault false alerts; các run đó đã bị loại khỏi ma trận chính.
Không trộn số alert của chúng vào số liệu cuối.

Xem [báo cáo](../06_experiments_findings.md) để biết oracle, chronology của
instrumentation fix và phạm vi mà một PASS thực sự xác nhận.
