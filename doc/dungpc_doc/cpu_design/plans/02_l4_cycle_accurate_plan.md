# Kế hoạch L4 — Cycle-accurate verification

## 1. Mục tiêu

L4 xác nhận hoặc bác bỏ các kết luận L3 bằng bằng chứng chạy thật:

```text
source program -> disassembly -> expected architecture -> expected cycles
               -> RTL waveform -> RVFI -> Spike/checker -> conclusion
```

L4 không được kết luận từ waveform đơn lẻ mà thiếu binary, seed, configuration
hoặc pass/fail oracle có thể tái tạo.

## 2. Template cho mỗi trace

1. Mục tiêu và feature.
2. Commit/worktree/config/tool versions.
3. Source và disassembly.
4. Initial register/memory state.
5. Expected architectural result.
6. Expected cycle table.
7. Actual cycle/waveform table.
8. RVFI và Spike/cosim comparison.
9. Assertions/checkers liên quan.
10. Pass/fail criteria.
11. Delta giữa OpenTitan và FX1.
12. Findings/open questions.

## 3. Work packages

| WP | Scenario groups |
|---|---|
| L4.0 | environment manifest, smoke tests, signal groups |
| L4.1 | ALU, dependency, forwarding, compressed, CSR baseline |
| L4.2 | branch, jump, redirect, predictor/DIT, PC check |
| L4.3 | MUL/MULH/DIV, zero, overflow, early-out, config latency |
| L4.4 | load/store sizes, load-use, misaligned, delays và errors |
| L4.5 | exception, IRQ, NMI, MRET, WFI, double fault |
| L4.6 | debug request, EBREAK, trigger, DRET, DEV/PROD delta |
| L4.7 | PMP modes, priority, MPRV, Smepmp, cross-word fetch |
| L4.8 | CHERIoT arithmetic, bounds, sentry, PCC, CLC/CSC, SCR |
| L4.9 | lockstep reset/alignment, ECC injection, TRVK/revocation |
| L4.10 | differential regression trên các profile |

## 4. Golden traces tối thiểu

- ALU dependency có forwarding.
- Load-use hazard.
- Misaligned word với hai request.
- Taken/not-taken branch, DIT on/off.
- MUL và DIV theo hai cấu hình M.
- Illegal/fetch/load/store fault.
- Interrupt trong multi-cycle operation.
- WFI sleep/wakeup.
- PMP I/I2/D deny.
- Debug request khi WB có outstanding load.
- CHERIoT CLC/CSC và bounds fault.
- Revoked capability clear tag.
- Lockstep mismatch injection.
- `ResetAll=0` so với `ResetAll=1` dưới X-prop.

## 5. Evidence policy

Không version-control FSDB hoặc toàn bộ run directory. Chỉ giữ:

- testcase source;
- command/config/seed;
- disassembly;
- log và RVFI excerpt tối thiểu;
- cycle table;
- Verdi bookmark/signal list;
- script tái tạo.

## 6. Cấu trúc đầu ra dự kiến

```text
l4_cycle_accurate/
├── README.md
├── 00_environment_manifest.md
├── 01_signal_dictionary.md
├── 02_pipeline_golden_traces.md
├── 03_branch_jump_traces.md
├── 04_multdiv_traces.md
├── 05_lsu_traces.md
├── 06_exception_interrupt_traces.md
├── 07_debug_traces.md
├── 08_pmp_traces.md
├── 09_cheriot_traces.md
├── 10_lockstep_ecc_traces.md
├── 11_trvk_traces.md
├── 12_configuration_differential.md
├── 13_failures_and_open_questions.md
└── evidence/
```

## 7. Execution order

Thứ tự mặc định là xoắn ốc theo module: dùng L3 handoff để tạo test L4 ngay cho
từng khối. Tuy nhiên L4 chỉ bắt đầu sau khi baseline, tool versions và smoke test
của profile mục tiêu đã ổn định.

## 8. Definition of done

Mỗi kết luận temporal quan trọng của L3 có ít nhất một trace tái tạo được hoặc
một formal/assertion result tương đương; mọi khác biệt profile được phân loại là
expected, tool/testbench assumption, RTL defect hoặc open issue.

