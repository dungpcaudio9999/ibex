# L3 — RTL deep dive cho Ibex/CHERIoT/FX1

## Trạng thái

Bộ tài liệu này triển khai kế hoạch
[L3 RTL deep dive](../plans/01_l3_rtl_deep_dive_plan.md) trên source tree cục bộ.
Nó là phân tích tĩnh: đọc parameter, generate branch, state, phương trình,
interface contract và assertions. Bằng chứng cycle-accurate sẽ thuộc L4.

## Baseline

- branch `feature/server-work`, HEAD `cdf80233`;
- upstream reference local `90331a69`;
- worktree có thay đổi chưa commit cho FX1;
- ngày snapshot: 2026-09-19;
- primary configurations: `opentitan`, `fx1_secure_dev`;
- delta configurations: `fx1_secure_prod`, `fx1_secure_dev_resetall`.

## Mục lục

| # | File | Nội dung |
|---|---|---|
| 00 | [00_baseline_manifest.md](00_baseline_manifest.md) | Baseline và giới hạn bằng chứng |
| 01 | [01_configuration_elaboration.md](01_configuration_elaboration.md) | Parameter propagation và active hierarchy |
| 02 | [02_ibex_top.md](02_ibex_top.md) | Integration boundary, RF/RAM/ECC/alerts |
| 03 | [03_ibex_core.md](03_ibex_core.md) | Pipeline interconnect và ownership |
| 04 | [04_if_stage.md](04_if_stage.md) | PC, fetch, protection, IF/ID registers |
| 05 | [05_prefetch_and_icache.md](05_prefetch_and_icache.md) | Hai implementation front-end memory |
| 06 | [06_compressed_decoder.md](06_compressed_decoder.md) | Zca/Zcb/Zcmp expansion |
| 07 | [07_id_stage.md](07_id_stage.md) | Operand, forwarding, hazard và ID FSM |
| 08 | [08_decoder.md](08_decoder.md) | Decode contract và legality |
| 09 | [09_controller.md](09_controller.md) | Global control FSM và event priority |
| 10 | [10_alu.md](10_alu.md) | ALU/shared adder/bitmanip |
| 11 | [11_multdiv.md](11_multdiv.md) | M-extension variants và latency control |
| 12 | [12_cheriot_execution.md](12_cheriot_execution.md) | Capability datapath/PCC/SCR/faults |
| 13 | [13_lsu.md](13_lsu.md) | Bus FSM, misalignment và capability beats |
| 14 | [14_writeback.md](14_writeback.md) | WB ownership, forwarding và retirement |
| 15 | [15_csr_and_events.md](15_csr_and_events.md) | CSR, privilege, traps/debug/counters |
| 16 | [16_pmp.md](16_pmp.md) | PMP/ePMP matching và policy |
| 17 | [17_lockstep_and_ecc.md](17_lockstep_and_ecc.md) | Shadow timeline và split RF ECC |
| 18 | [18_trvk.md](18_trvk.md) | Revocation interceptor và assumptions |
| 19 | [19_cross_module_invariants.md](19_cross_module_invariants.md) | Invariants đi qua nhiều module |
| 20 | [20_fx1_findings.md](20_fx1_findings.md) | Findings/risk backlog cho FX1 |

## Mức độ khẳng định

- **Fact**: thấy trực tiếp trong RTL/config hiện tại.
- **Inference**: suy ra từ kết nối/phương trình nhưng chưa chạy L4.
- **Assumption**: môi trường hoặc protocol phải bảo đảm.
- **Open**: cần simulation/formal/integration evidence.

Các cycle count không được coi là đã xác minh nếu chưa có L4 trace.

