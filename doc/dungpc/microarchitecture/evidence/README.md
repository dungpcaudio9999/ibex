# Evidence của phân tích microarchitecture

Các paths/commands trong JSON ghi workspace thực tế lúc chạy. Để tái tạo trong
checkout khác, dùng scripts thay vì copy nguyên absolute command.

## Core run naming và stimulus

`<config>.<case>.d1.log` hoặc `.d4.log`, với config small/wb/bt/single/slow.
`<case>.hex` là instruction memory gồm cả boot code và handlers; data memory
riêng ban đầu điền `0x44332211`. Chương trình và expected registers được định nghĩa
trong `../scripts/run_core.py`, không phụ thuộc cross compiler.

D1: grant mỗi cycle, response latency 1. D4: grant mỗi 3 cycle, response latency 4.
Waveforms cho memory/control/compressed/error_split_load_second/event1 được giữ
dạng `.vcd.gz`; các case còn lại có textual cycle trace. Unit tests giữ textual
results, chưa xuất waveform.

## Log record schema

| Prefix | Fields theo thứ tự sau prefix |
|---|---|
| CONFIG | WB, BT, M, latency, ilatency, grant_period |
| C | cycle, PC_ID(hex), valid_ID, ID_FSM(0 FIRST/1 MULTI), stall_mem, stall_ld_hz, stall_multdiv, stall_branch, stall_jump, done_ID, ready_WB, data_req, data_gnt, data_addr(hex), data_rvalid, data_error, PC_IF(hex), instr_req, instr_gnt, instr_rvalid, pc_set |
| W | cycle, rd(decimal), data(hex); chỉ rd khác 0 |
| R | cycle, RVFI order(decimal), PC(hex), instruction(hex), trap |
| D | cycle, write flag, address(hex), byte enable(hex), write data(hex) |
| EVENT | cycle, kind(1 IRQ-load/2 debug-load/3 IRQ-div/4 debug-div) |
| REG | register index(decimal), final shadow value(hex) |
| MEM | byte address(hex), final word(hex) |

`REG` shadow theo dõi cổng ghi của RF thật; không đọc backdoor toàn physical RF.
`D` chỉ ghi transaction accepted; Wdata của read request không mang ý nghĩa
architectural. `C` payload PC/data phải đi kèm valid/request để diễn giải.
Các biểu thức được sample trước NBA tại rising edge; response/grant stimulus
được chuẩn bị ở falling edge. `R` và `W` có thể lệch cycle do RVFI pipeline.

## Artifact groups

- `core_results.json`: commands + final-register expectations/status của 160 runs.
- `trace_checks.json`: checker bổ sung trên chính logs đó, không phải simulation mới.
- `unit_results.json`, `cap_ex.log`, `cap_lsu.log`, `trvk.log`: 3 module simulations,
  tổng 20 directed checks. Không full-core CHERIoT/ISA-conformance claim.
- `negative_control.json`: mutate một RVFI instruction trong copy trace và xác
  nhận checker reject. Không sửa log gốc hoặc DUT.
- `*.build-command.json`, `*.build.log`: source list/flags và actual compiler logs.
- `*.hierarchy.json`, `*.elaboration.xml.gz`, `*.elaboration.log`: hierarchy và
  parameter constants sau Verilator XML elaboration cho 5 core configs.
- `*.dependencies.txt`, `source_dependencies_sha256.json`: dependencies thực tế
  parser đọc (kể cả source ở generate không active) và các RTL được phân tích.
  Có trong dependencies không đồng nghĩa được instantiate ở active hierarchy.
- `baseline.json`: revision/tool và explicit source hashes của core build.
- `artifact_manifest.json`, `validation_report.json`: integrity/link/result checks.
- `development_first_run.json`: chẩn đoán initial harness race và mtval prediction,
  đã được supersede bởi final runs; không thuộc pass-count.

Không có formal reports, coverage closure, PPA, full-top clock-gating run hoặc
cache/lockstep validation trong thư mục này.

## Đợt hoàn tất top-level

`extended/` bổ sung21top runs và6ordering checks; [báo cáo](../13_completion_results.md)
đối chiếu cache/predictor/Zcb/Zcmp, reset/fetch faults, debug/WFI/NMI,
CHERIoT end-to-end và PMP. `initial_top_tb.sv`/`initial_run_extended.py` giữ
harness/runner trước khi thêm instrumentation dành cho chuyên đề Secure.
Evidence Secure ở [thư mục riêng](../../secure_ibex/evidence/README.md).
