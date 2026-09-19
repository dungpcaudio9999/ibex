# 04 — Deep dive `ibex_if_stage`

## 1. Contract

IF biến control redirect/request thành một stream instruction cho ID. Output chỉ
có nghĩa khi `instr_valid_id_o=1`; payload phải ổn định đến khi ID clear hoặc
nhận instruction mới.

## 2. Input/control groups

- Request control: `req_i`, `id_in_ready_i`.
- Redirect: `pc_set_i`, `pc_mux_i`, branch target, mispredict address.
- Trap/debug targets: MEPC, DEPC, MTVEC, cause.
- Protection: PMP I/I2 results, PCC decoded capability.
- Runtime features: dummy controls, cache enable/invalidate, CHERIoT mode.
- Memory/cache interface: external instruction bus và physical RAM ports.

## 3. PC equations

```text
PC_BOOT = {boot_addr[31:8], 8'h80}
PC_JUMP = branch_target_ex
PC_EXC  = exception/debug mux result
PC_ERET = mepc
PC_DRET = depc
PC_BP   = predictor target
```

`pc_mux_internal` chọn `PC_BP` chỉ khi predictor enabled, predicts taken và chưa
có authoritative `pc_set_i`. Redirect address bit 0 bị clear.

`csr_mtvec_init_o` lên khi boot PC được set, cho CSR block khởi tạo MTVEC từ
boot base.

## 4. Fetch stream ownership

Cache/prefetch tạo `fetch_valid_raw`, data, address và errors. IF squash valid
khi redirect khiến response thuộc wrong path. `fetch_ready` chỉ lên khi ID có
chỗ, dummy không giữ stream và predictor skid logic cho phép.

**Invariant I-IF-01:** Mỗi accepted fetch item hoặc được ghi IF/ID một lần, hoặc
bị squash do redirect/error protocol; không được vừa consume vừa replay.

## 5. IF/ID valid equation

```text
valid_d = (if_instr_valid && id_in_ready && !pc_set)
        | (valid_q && !instr_valid_clear)
```

`instr_new_id_d` tạo write enable payload. Valid reset luôn có; payload reset phụ
thuộc `ResetAll`. Payload groups gồm instruction copies, PC, compressed original,
error bits, expansion state và CHERIoT violation.

**Invariant I-IF-02:** Bất kỳ payload không reset nào cũng chỉ được quan sát khi
valid tương ứng đã được set bởi cùng write event.

## 6. Error construction

```text
pmp_err = pmp_I || (pc[1] && !compressed && pmp_I2)
fetch_err = bus_or_integrity || pmp_err || PCC access || PCC bounds
```

`err_plus2` chỉ đánh dấu lỗi nửa thứ hai nếu nửa đầu không đã lỗi. Controller
dùng nó để chọn `mtval=PC+2`.

## 7. PCC bounds arithmetic

IF tính `headroom = PCC.top - PC` 34-bit; compressed cần ≥2 byte, instruction
32-bit cần ≥4. `base_ok` yêu cầu PC≥base. Full-address-space capability có case
wraparound riêng cho PC `0xffff_fffe`.

Access violation tách khỏi bound violation: tag/otype/EX permission thuộc access;
base/top thuộc bounds. Debug mode bypass một số CHERIoT fetch enforcement theo
RTL policy.

## 8. Constant-time force-uncached

Khi quyền/bounds chỉ đủ cho một phần fetch, IF có thể ép prefetch path uncached
để không lộ permission/bounds qua cache timing. Signal này vẫn được nối/tie
unused phù hợp khi I-cache branch thay đổi.

## 9. Dummy insertion

Dummy module quyết định `insert_dummy_instr`. IF mux dummy thay instruction thật,
clear compressed/error metadata và giữ fetch bằng `stall_dummy_instr`. Marker
được register song song payload.

Assertion downstream yêu cầu dummy chỉ tạo write x0 và không thay architectural
state. FX1 generate-out toàn khối.

## 10. Predictor branch

Khi enabled, skid register giữ instruction nếu predicted redirect và ID
back-pressure giao nhau. Predictor chỉ decode branch pattern ở fetch, không biết
register comparison; ID phát not-taken mispredict correction.

Named configs tắt predictor nên toàn bộ skid/predictor path inactive; assertions
vẫn giới hạn mux selector hợp lệ cho no-predictor branch.

## 11. PC increment check

Khi enabled, IF ghi expected sequential address từ instruction đã chấp nhận và
so với next PC khi flow vẫn sequential. Branch/exception/debug redirect phải
clear/disable comparison. Mismatch đi thẳng alert, không tạo architectural trap.

## 12. Assertions and coverage

- PC/exc mux encoding known và hợp lệ.
- Predictor request/mispredict consistency.
- IF/ID payload stability under stall.
- PC increment mismatch conditions.
- Dummy insertion coverage.
- Compressed expansion events.

## 13. Findings

- **Fact F-IF-01:** FX1 dùng prefetch buffer; cache signals là dead/tie-off.
- **Fact F-IF-02:** PCC checks vẫn active vì dual ISA, dù runtime có thể đang RV32.
- **Inference I-IF-03:** `ResetAll=0` risk tập trung ở invalid payload/lockstep
  compare, không phải IF valid bit.
- **Open O-IF-01:** Cần L4 cross-word bus/PMP error trace để xác nhận `plus2`.

## 14. L4 handoff

Scenarios: reset-first fetch, ID stall payload stability, PC redirect với response
đồng thời, compressed cross-word, PCC near-top, PC wraparound, fetch disable và
PC mismatch injection.

Signals: `fetch_*`, `if_instr_*`, `if_id_pipe_reg_we`, valid/new, PC mux/set,
PMP I/I2, CHERIoT violations.

## 15. Source anchors

- [`rtl/ibex_if_stage.sv`](../../../../rtl/ibex_if_stage.sv)
- [`rtl/ibex_branch_predict.sv`](../../../../rtl/ibex_branch_predict.sv)
- [`rtl/ibex_dummy_instr.sv`](../../../../rtl/ibex_dummy_instr.sv)

