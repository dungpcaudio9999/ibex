# Kế hoạch L3 — RTL deep dive

## 1. Mục tiêu

L3 phải đủ sâu để người đọc review hoặc sửa RTL an toàn. Sau khi hoàn tất phải
trả lời được module nào sở hữu state/side effect, điều kiện hợp lệ của từng
đường dữ liệu, mọi nguyên nhân stall/flush quan trọng, parameter nào thay đổi
netlist và assertion nào bảo vệ invariant.

## 2. Baseline cấu hình

Phân tích đầy đủ `opentitan` và `fx1_secure_dev`; hai profile
`fx1_secure_prod` và `fx1_secure_dev_resetall` được phân tích theo delta.

Mỗi kết luận cấu hình phải truy được qua:

```text
ibex_configs.yaml -> util/ibex_config.py -> top/testbench parameter
                  -> generate branch -> active hardware
```

## 3. Template bắt buộc cho mỗi module

1. Vai trò và architectural boundary.
2. Parameters và generate tree.
3. Ports theo nhóm contract.
4. Internal state/register inventory.
5. Combinational equations và mux quan trọng.
6. FSM transition table.
7. Valid/ready, stall và back-pressure.
8. Reset, flush, kill và mode-switch behavior.
9. Error, exception và alert propagation.
10. Khác biệt RV32/CHERIoT và OpenTitan/FX1.
11. Assertions/coverage hooks.
12. Critical-path candidates.
13. Findings, assumptions và câu hỏi mở.
14. Danh sách tín hiệu chuyển giao cho L4.

## 4. Work packages

| WP | Phạm vi | Đầu ra chính |
|---|---|---|
| L3.0 | Baseline/elaboration | manifest, parameter truth table, active hierarchy |
| L3.1 | `ibex_top` | integration, RF/RAM, ECC, TRVK, alerts |
| L3.2 | `ibex_core`/pipeline | ownership, valid-ready, feedback paths |
| L3.3 | Front end | IF, prefetch, I-cache, compressed, dummy, prediction |
| L3.4 | Decode/control | decode matrix, controller và ID FSM, hazards |
| L3.5 | RV32 execution | ALU, branch-target, MUL/DIV, DIT |
| L3.6 | CHERIoT execution | capability representation, checks, PCC/SCR |
| L3.7 | LSU/WB | bus FSM, misalignment, two-beat cap, retirement |
| L3.8 | CSR/events | privilege, exception, interrupt, debug, counters |
| L3.9 | PMP/ePMP | matching, priority, Smepmp và mode gating |
| L3.10 | Security wrappers | lockstep, RF ECC, TRVK, alert tree |
| L3.11 | Cross-module closure | invariants, FX1 findings, L4 handoff |

## 5. Cấu trúc đầu ra

```text
l3_rtl_deep_dive/
├── README.md
├── 00_baseline_manifest.md
├── 01_configuration_elaboration.md
├── 02_ibex_top.md
├── 03_ibex_core.md
├── 04_if_stage.md
├── 05_prefetch_and_icache.md
├── 06_compressed_decoder.md
├── 07_id_stage.md
├── 08_decoder.md
├── 09_controller.md
├── 10_alu.md
├── 11_multdiv.md
├── 12_cheriot_execution.md
├── 13_lsu.md
├── 14_writeback.md
├── 15_csr_and_events.md
├── 16_pmp.md
├── 17_lockstep_and_ecc.md
├── 18_trvk.md
├── 19_cross_module_invariants.md
└── 20_fx1_findings.md
```

## 6. Quality gates

- Mọi local link và source path phải tồn tại.
- Parameter tables phải khớp output thật của `ibex_config.py`.
- State names phải khớp source.
- Không coi logic chỉ có trong source là active nếu generate branch loại nó.
- Mọi finding phải phân loại: fact, inference, assumption hoặc open question.
- `git diff --check` phải sạch.
- Mỗi module phải có L4 handoff signals/scenarios.

## 7. Definition of done

L3 hoàn tất khi toàn bộ 21 tài liệu tồn tại, active hierarchy của bốn profile đã
được phân biệt, các FSM và cross-module contracts quan trọng đã được mô tả,
những rủi ro FX1 được gom thành backlog có thể kiểm chứng ở L4.

