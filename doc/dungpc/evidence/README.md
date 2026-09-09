# Evidence index — BASE-01

Tất cả source claims ghim revision `8031c7dde749bb9d62391e5befbe55f1c014a171`. `source_manifest.json` định danh inputs; `artifact_manifest.json` định danh đầu ra phân tích (trừ chính manifest này và guide input). Không có external artifact store, không cần truy cập dịch vụ để đọc bằng chứng; giữ thư mục cùng checkout/revision khi chia sẻ.

| EVD | Kind/result | Artifact | Reproduction / phạm vi |
|---|---|---|---|
| EVD-01 | STATIC:ESTABLISHED — snapshot | [baseline](baseline.json), [source_manifest](source_manifest.json), [patch](source_changes.patch), git*.log | collect_evidence.py lần đầu tại checkout mới; 3.694 input hashes, không elaborate |
| EVD-02 | STATIC:ESTABLISHED — configuration emission | [small](config_small.log), [opentitan](config_opentitan.log) | python3 util/ibex_config.py CONFIG fusesoc_opts; exit0 |
| EVD-03 | STATIC:ESTABLISHED — text/path audit | [source_audit](source_audit.json), [audit log](audit_run.log) | python3 doc/dungpc/evidence/source_audit.py; không semantic lint |
| EVD-04 | STATIC:NOT-RUN — build/elaboration | [setup](simple_system_setup.log), [FuseSoC probe](fusesoc_version.log), [Verilator probe](verilator_version.log) | Command launch không được do executable thiếu; không có child exit |
| EVD-05 | STATIC:ESTABLISHED — planned firmware commands | [dry-run](firmware_dry_run.log) | make -n -C examples/sw/simple_system/hello_test; không ELF |
| EVD-06 | SIM:OBSERVED — **Python model only** | [model trace](model_positive.json), [log](model_run.log) | model_experiments.py; exit0; không chạy RTL |
| EVD-07 | SIM:OBSERVED — **negative model comparison only** | [negative trace](model_negative.json), [log](model_negative_run.log) | model_experiments.py --corrupt-check; expected exit1, edge5 |
| EVD-08 | RTL:ESTABLISHED — source facts có điều kiện | [source_extracts](source_extracts.txt) và source hashes | run_checks.py sao chép numbered source slices; không hierarchy/proof |
| EVD-09 | STATIC:ESTABLISHED — UVM enum option emission | [VCS options log](uvm_vcs_options.log) | Generator small vcs_opts + IBEX_CFG_ prefix; không launch VCS |

Lệnh chính dùng lại để kiểm những observation đã chạy:

```bash
python3 doc/dungpc/evidence/run_checks.py
python3 doc/dungpc/evidence/validate_analysis.py
```

[check_runs.json](check_runs.json) giữ argv, timestamp, exit/expected-exit và stdout của từng process. Script model negative có exit1 có chủ đích; run_checks không coi đó là thất bại của toàn bộ kiểm tra khi đúng marker và code kỳ vọng. Chạy lại ghi đè check/model logs riêng; muốn giữ evidence lịch sử phải dùng checkout copy/baseline mới. Collector từ chối ghi đè source baseline.

Không tồn tại waveform/HDL executable/coverage/proof/STA report do phiên này tạo ra; không có chỗ trống giả làm kết quả. Missing tools giữ trạng thái NOT-RUN. Artifact hash không chứng minh nội dung đúng, chỉ giúp biết đúng phiên bản đã được xem.
