# 17 — Deep dive lockstep và ECC

## 1. Protection architecture

`ibex_lockstep` instantiate shadow `ibex_core`, delay its inputs và compare output
với main core delayed tương ứng. Shadow core đồng thời tạo/check RF ECC bits lưu
trong shadow RF.

Lockstep phát hiện divergence logic/state; ECC phát hiện storage corruption. Hai
cơ chế dùng chung shadow hardware nhưng có coverage khác nhau.

## 2. Reset sequencing

Parameters:

```text
LockstepOffsetW = vbits(LockstepOffset)
OutputsOffset   = LockstepOffset + 1
```

Nếu offset>1, saturating counter chờ trước khi nhả shadow reset. Offset=1 dùng
fixed sequential enable. `rst_shadow_set_q` điều khiển shadow reset qua clock mux;
`enable_cmp_q` bật sau nhịp phù hợp. Test mode chọn `scan_rst_ni`.

Counter error góp major internal alert.

## 3. Input-delay bundle

Delayed inputs gồm:

- instruction/data grants, responses, data/errors/tags;
- main RF read data/caps;
- IRQ/NMI/debug;
- fetch/counter/CHERIoT MuBi controls;
- I-cache key valid.

I-cache RAM read arrays delay qua registers riêng do unpacked types. Reset values
của delay pipeline là zero.

**Invariant I-LS-01:** Shadow nhận đúng cùng input transaction với main, chỉ dịch
`LockstepOffset` cycles.

## 4. Main-output delay

Compare bundle main được shift `OutputsOffset`, gồm instruction/data requests,
addresses/write payload/tag, cache RAM controls, IRQ pending, crash/double fault,
busy và RF capability write metadata.

Shadow output được register một cycle, giải thích `+1`. Compare equation:

```text
outputs_mismatch = enable_cmp_not_off
                && (shadow_outputs_q != delayed_main_outputs)
```

MuBi policy dùng “bất kỳ giá trị không phải Off” để bật compare, fail-safe với
encoding fault.

## 5. Shadow core equivalence

Shadow nhận cùng functional parameters: ISA, M/B/Zc, WB/cache/PMP/debug,
SecureIbex, ResetAll, Dummy, MemECC. Sai một parameter giữa main/shadow có thể
tạo deterministic mismatch, nên propagation list ở top là review checklist.

Shadow `SecureIbex` không recursively instantiate another lockstep vì nó là
`ibex_core`, không phải `ibex_top`.

## 6. Split RF ECC data path

Main RF stores 32 data bits. Shadow RF stores seven ECC bits. Shadow core receives:

```text
rf_rdata_ecc = {shadow_rf_ecc[6:0], delayed_main_data[31:0]}
```

Shadow core `RegFileECC=1` decodes SECDED 39/32, produces corrected logical data
for shadow execution and errors for alerts. On write it encodes 39-bit codeword;
only upper seven bits go shadow RF, lower data output is unused because main RF
already stores data.

This also makes shadow execution use corrected main data, not an independent
full copy of RF data. Logic duplication and storage-integrity protection are
therefore coupled but not identical dual modular redundancy.

## 7. Capability ECC

Main RF stores 35-bit `cap_t`. Encoder zero-extends logical payload into 57-bit
data domain of SECDED 64/57 and stores seven check bits in shadow RF. On read,
metadata + check bits reconstruct codeword. Check is relevant in CHERIoT mode;
NULL/tie behavior applies otherwise.

**Invariant I-LS-02:** Main data/cap write and shadow ECC write address/enable
must remain aligned across delay.

## 8. What is compared versus protected indirectly

Not all shadow RF internal write signals are in direct compare bundle. Fault in
them should later create ECC error or execution/output divergence. This creates
detection latency and assumes corrupted state is eventually read or otherwise
observable.

Lockstep also cannot detect a common-mode fault applied identically after the
comparison boundary, such as external bus returning the same wrong but
integrity-valid data to both executions.

## 9. MemECC relationship

MemECC protects bus data before it drives main/shadow at different times.
Lockstep can catch some transient response differences if delayed replay differs,
but a stable corrupted response captured into delay and replayed identically is
common input. FX1 disabling MemECC removes direct integrity detection for that
case.

## 10. ResetAll risk model

With ResetAll=0, control/valid state resets but output payload flops may be X
until enabled. Compare bundle includes fields not always paired with explicit
valid. If main delayed payload and shadow payload initialize differently in
4-state/gate simulation, mismatch could occur when compare enables.

**Open O-LS-01:** This is not declared a bug by static review; must run X-prop and
gate-level/reset stress comparing DEV vs DEV-resetall.

## 11. Alert classification

`outputs_mismatch`, shadow core internal alert và reset-counter error feed major
internal. Shadow bus integrity feeds major bus. Minor shadow alert remains minor.
Top buffers these before OR with main/cache/TRVK alerts.

## 12. Physical implementation constraints

`prim_buf`, `prim_flop` and explicit clock/reset structures create anchor points
to prevent synthesis merging main/shadow cones. RTL functional equivalence alone
does not ensure physical fault independence; backend constraints/netlist review
are required.

## 13. Findings

- **Fact F-LS-01:** Shadow RF is ECC storage, not a second complete RF data copy.
- **Fact F-LS-02:** Compare starts through MuBi reset/enable pipeline, not at
  reset release immediately.
- **Inference I-LS-03:** MemECC-off leaves a common-input corruption class outside
  lockstep coverage.
- **Open O-LS-02:** Fault-injection coverage and detection latency need L4/formal.
- **Open O-LS-03:** Backend must prove anti-optimization/physical separation.

## 14. L4 handoff

Reset sequences with random X, offset alignment, input pulse each boundary,
output bit fault injection, RF data/ECC/cap corruption, invalid MuBi enable,
MemECC common corruption and scan reset behavior.

## 15. Source anchors

- [`rtl/ibex_lockstep.sv`](../../../../rtl/ibex_lockstep.sv)
- [`rtl/ibex_top.sv`](../../../../rtl/ibex_top.sv)
- [`rtl/ibex_core.sv`](../../../../rtl/ibex_core.sv)
- [`rtl/ibex_register_file_ff.sv`](../../../../rtl/ibex_register_file_ff.sv)

