# 14 — Deep dive writeback

## 1. Contract

WB giữ instruction sau ID, serialize post-ID completion, chọn RF write source,
phát forwarding metadata và đánh dấu retirement. Nó là optional stage về phần
cứng state, nhưng module luôn instantiate.

## 2. Registered branch

Khi `WritebackStage=1`, registers giữ valid, PC, compressed/count flags,
instruction type, RV32 RF result và CHERIoT result/cap/load/store flags.

```text
wb_valid_d = (en_wb && ready_wb) || (wb_valid_q && !wb_done)
ready_wb   = !wb_valid_q || wb_done
```

Cho phép replace finishing instruction bằng next instruction trong cùng boundary
cycle khi `en_wb && ready_wb`.

## 3. Completion equation

`WB_INSTR_OTHER` done ngay, trừ CHERIoT operation được đánh load/store sau policy.
Memory instruction done khi `lsu_resp_valid`. Error vẫn làm operation complete
nhưng suppress normal retire/write theo LSU error gates.

**Invariant I-WB-01:** WB valid memory instruction không bị overwrite trước final
response/error.

## 4. RF write-source mux

Two sources:

- source 0: registered ID/EX or CHERIoT result;
- source 1: LSU returning load data/cap.

Data mux dùng masked OR; assertion `$onehot0` trên enables bảo đảm không trộn hai
nguồn. Capability chọn matching source hoặc NULL.

## 5. Forwarding

Forwarded value là registered non-load result. `rf_write_wb` vẫn báo destination
cho load đang chờ để ID hazard detector stall. Returning LSU data không forward
combinational vì path quá muộn; nó ghi RF và dependent instruction đọc sau.

CHERIoT forwarding gồm data+cap registered pair. Capability load chờ LSU source,
không dùng stored CHERIoT result cap.

## 6. Outstanding flags

`outstanding_load/store` derive từ valid/type và CHERIoT flags. ID dùng chúng cho
hazard/order; controller dùng WB exception readiness. Sai classification gây
hoặc deadlock/false stall, hoặc precise exception violation.

## 7. Retirement counters

Actual retire pulse:

```text
instr_done_wb && countable && !(lsu_resp_valid && lsu_resp_err)
```

Speculative retire pulses từ WB valid/count dùng CSR counter read compensation;
compressed pulse song song. Dummy marker đi WB để bảo vệ x0/dummy semantics.

## 8. Bypass branch

Khi no WB:

- ID and LSU write sources mux trực tiếp;
- ready constant one;
- no outstanding flags/forwarding;
- retire occurs at ID/LSU completion;
- PC WB tie zero.

Scope profiles không dùng nhưng formal/config code phải giữ behavior hợp lệ.

## 9. ResetAll

Valid always resets. Payload reset only in `g_wb_regs_ra`; no-reset branch writes
payload only on `en_wb`. Dummy marker tương tự. Valid gating bảo vệ functional
use, nhưng lockstep comparison/X behavior cần independent evidence.

## 10. Assertions

- One RF write source maximum.
- WB valid/ready ownership through memory wait.
- No retirement on LSU error.
- Forward/hazard consistency checked partly in ID.

## 11. Findings

- **Fact F-WB-01:** `ready_wb` can be true in same cycle current WB completes,
  enabling continuous throughput.
- **Fact F-WB-02:** load destination is advertised before data exists.
- **Open O-WB-01:** Simultaneous LSU response + new `en_wb` replacement trace.
- **Open O-WB-02:** X-prop compare with payload no-reset.

## 12. L4 handoff

Back-to-back ALU, WB full, load response same cycle new instruction, load error,
CHERIoT load/store classification, two source assertion negative test, dummy
instruction and counter read-after-retire.

## 13. Source anchors

- [`rtl/ibex_wb_stage.sv`](../../../../rtl/ibex_wb_stage.sv)
- [`rtl/ibex_id_stage.sv`](../../../../rtl/ibex_id_stage.sv)

