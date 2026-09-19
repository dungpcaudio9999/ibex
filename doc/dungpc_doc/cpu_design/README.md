# Phân tích thiết kế CPU Ibex theo hướng RTL top-down

## Mục tiêu

Bộ tài liệu này thực hiện **hướng B — RTL top-down**: bắt đầu từ biên tích hợp
`ibex_top`, đi xuống `ibex_core`, rồi lần theo từng tầng pipeline và các khối
đặc thù CHERIoT/security.

Đây là tài liệu cho đúng source tree hiện tại, không phải mô tả chung của Ibex
upstream. Baseline khi viết:

- nhánh: `feature/server-work`;
- commit: `cdf80233`;
- `upstream/master`: `90331a69`;
- worktree có thay đổi chưa commit liên quan đến các cấu hình FX1,
  `DummyInstructions`, `ResetAll`, `MemECC` và `DbgHwBreakNum`.

Vì vậy, mọi kết luận cấu hình đều ghi rõ đang nói về `opentitan` hay một profile
FX1. Khi source thay đổi, cần chạy lại checklist ở tài liệu 01.

## Cách dùng bộ tài liệu

Đọc theo đúng thứ tự dưới đây. Mỗi chương có bốn lớp thông tin:

1. trách nhiệm của module;
2. datapath và control path;
3. logic được generate theo parameter;
4. checklist đọc RTL/waveform để tự kiểm chứng.

| # | Tài liệu | Nội dung |
|---|---|---|
| 00 | [00_learning_approaches.md](00_learning_approaches.md) | Sáu hướng tiếp cận tổng thể, viết bằng tiếng Anh |
| 01 | [01_baseline_configuration.md](01_baseline_configuration.md) | Baseline, cấu hình và phương pháp xác định phần cứng thực sự được elaborate |
| 02 | [02_hierarchy_and_ibex_top.md](02_hierarchy_and_ibex_top.md) | Cây phân cấp và vai trò của `ibex_top` |
| 03 | [03_ibex_core_and_pipeline.md](03_ibex_core_and_pipeline.md) | `ibex_core`, pipeline, back-pressure và các đường phản hồi |
| 04 | [04_instruction_fetch.md](04_instruction_fetch.md) | IF, PC mux, I-cache/prefetch, compressed và IF/ID register |
| 05 | [05_decode_and_control.md](05_decode_and_control.md) | Decoder, controller FSM, operand, hazard, stall và forwarding |
| 06 | [06_execution_and_cheriot.md](06_execution_and_cheriot.md) | ALU, MUL/DIV, branch target và CHERIoT execution |
| 07 | [07_lsu_and_writeback.md](07_lsu_and_writeback.md) | LSU, giao dịch lệch hàng/capability và WB |
| 08 | [08_csr_pmp_events.md](08_csr_pmp_events.md) | CSR, PMP/ePMP, exception, interrupt, debug và counters |
| 09 | [09_security_lockstep_trvk.md](09_security_lockstep_trvk.md) | SecureIbex, ECC, lockstep, alerts và revocation |
| 10 | [10_rtl_review_playbook.md](10_rtl_review_playbook.md) | Quy trình review một thay đổi RTL và checklist hoàn tất hướng B |

## Kế hoạch và phân tích chuyên sâu

- [Kế hoạch L3/L4](plans/README.md)
- [L3 — RTL deep dive](l3_rtl_deep_dive/README.md)

L3 hiện gồm 21 chương phân tích cộng một mục lục, bao phủ configuration,
integration, toàn bộ pipeline, privileged/security blocks, cross-module
invariants và backlog rủi ro FX1. L4 mới được lưu kế hoạch; chưa chạy các
testcase cycle-accurate trong bộ tài liệu này.

## Sơ đồ đọc top-down

```text
ibex_top / ibex_top_tracing
│
├── clock gating + bus integrity + register file + I-cache RAM
├── ibex_core
│   ├── ibex_if_stage
│   │   ├── ibex_icache hoặc ibex_prefetch_buffer
│   │   ├── ibex_compressed_decoder
│   │   └── ibex_dummy_instr (tùy cấu hình)
│   ├── ibex_id_stage
│   │   ├── ibex_decoder
│   │   └── ibex_controller
│   ├── ibex_ex_block
│   │   ├── ibex_alu
│   │   └── ibex_multdiv_fast/slow
│   ├── ibex_cheriot_ex (khi BaseIsa hỗ trợ CHERIoT)
│   ├── ibex_load_store_unit
│   ├── ibex_wb_stage
│   ├── ibex_cs_registers
│   └── ibex_pmp
├── ibex_lockstep + shadow core (khi SecureIbex=1)
└── ibex_trvk (khi BaseIsa=BaseIsaRV32IorCHERIoT)
```

## Quy ước

- `_q`: trạng thái hiện tại lưu trong flop.
- `_d`: giá trị trạng thái kế tiếp.
- `_i`/`_o`: input/output nhìn từ module đang xét.
- “ID/EX” được dùng vì Ibex gộp decode và phần lớn execute control trong một
  tầng pipeline.
- “retire” nghĩa là lệnh đã hoàn tất về mặt kiến trúc, không chỉ đã tính xong
  ALU.
- “active” nghĩa là logic tồn tại sau elaboration cho cấu hình đang xét.

## Tài liệu chi tiết có sẵn

Bộ tài liệu này tối ưu cho luồng đọc thiết kế top-down. Các phân tích chi tiết
hơn theo từng khối vẫn nằm ở thư mục cha, đặc biệt:

- [phân cấp module](../01_phan_cap_module.md);
- [pipeline timing](../12_pipeline_timing.md);
- [mô phỏng VCS](../13_mo_phong_vcs.md);
- [flow test arithmetic](../14_flow_test_riscv_arithmetic_basic.md).
