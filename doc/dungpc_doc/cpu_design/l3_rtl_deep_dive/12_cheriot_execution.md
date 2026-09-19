# 12 — Deep dive CHERIoT execution

## 1. Architectural split

`ibex_cheriot_ex` là capability policy/datapath nằm giữa ID/RF và LSU/CSR/PCC.
Nó không thay IF/controller/LSU; nó thêm authority checks và capability result,
rồi mux RV32/CHERIoT requests vào shared downstream blocks.

## 2. Capability formats

`cap_t` rộng 35 bit:

```text
cap_cor[1:0], valid, reserved, cperms[5:0], otype[2:0],
cexp[3:0], top[8:0], base[8:0]
```

`decoded_cap_t` thêm absolute `top33`, `base32`, expanded `perms[11:0]`, tổng
112 bit. RF/CSR lưu compressed form; datapath reconstruct bounds theo current
pointer/data.

## 3. Forwarding and operand gating

CHERIoT EX tự merge WB forwarding cho cả data và cap khi destination match nonzero
source. Sau đó gate operands về zero/NULL trừ khi instruction CHERIoT hoặc RV32
LSU cần authority cap, giảm switching vào decompression logic.

**Invariant I-CH-01:** Data pointer và capability metadata phải forward như một
atomic pair.

## 4. Capability expansion

Decode functions:

- expand compressed permission class;
- expand exponent;
- reconstruct base/top bằng pointer high bits và correction factors;
- derive valid/sealed/bounds state.

Correction fields trong RF tránh recompute một phần nhưng phải update khi pointer
đổi. `cheriot_set_address` clear tag nếu new pointer không representable.

## 5. Main operation classes

- Field extraction and equality/subset.
- Move/clear tag/permission AND.
- Set high/address/increment.
- Set bounds exact, rounded và CRAM/CRRL outputs.
- Seal/unseal.
- Capability load/store.
- SCR read/write.
- CJAL/CJALR/PCC update and sentry handling.

Most operations set `cheriot_ex_valid_raw` combinational; outputs are gated by
`cheriot_exec_id` to avoid side effects during stall/WB exception.

## 6. SetBounds datapath

Cycle/path computes requested top, length MSB, base alignment and candidate
exponents. Two exponent candidates run in parallel; overflow/rounding selects.
Exact request clears valid on unrepresentable rounding. Parent bounds check
prevents authority amplification.

SetBounds is a likely long combinational path due add, leading/trailing-bit
analysis, candidate arithmetic, comparisons and capability encode.

## 7. Permission checks

Expanded permissions include execute, system-register access, load/store data,
load/store capability, local/global and seal/unseal. Violation vector also
captures tag, sealed state, bounds/alignment and capability index.

Some relational operations such as subset/seal checks return boolean/tag-cleared
results instead of exceptions according to implemented semantics; review must
not assume every violation traps.

## 8. RV32 load/store under CHERIoT mode

Even normal-width RV32-style load/store can be checked against authority
capability from source. `check_rv32` computes access bottom/top for byte/half/
word, detects wrap/bounds and LD/SD/sealed violations.

`rv32_lsu_err` only active when CHERIoT mode On and not debug. The unified LSU
still sees normal width/type but error is classified CHERIoT.

## 9. Capability LSU

CLC/CSC use word type downstream but mark `lsu_is_cap`; LSU emits two aligned
beats. Address adds immediate and LSU `addr_incr_req` ×4. Store converts cap/data;
load supplies `cap_clrperm_t` derived from authority permissions.

With WB, capability request remains asserted according to execute/request-done
protocol; without WB it is first-cycle gated to avoid reissuing while waiting
response.

## 10. PCC/control flow

CJAL/JALR path constructs new PCC, clears address bit 0, unseals valid sentry,
checks target and creates backward sentry link in destination when required.
Sentry type may set/clear MIE. Outputs:

- speculative branch request for control timing;
- committed branch/PCC update;
- result capability link;
- CSR MIE set/clear.

`instr_fault` gates branch side effect but valid/result sequencing remains
coordinated with controller.

## 11. SCR and fault phase

SCR operation carries data+cap and 5-bit decoded address. Illegal SCR/address or
ASR permission may only become WB-class error. Error info registers capability/
SCR index and cause. `WritebackStage` selects registered versus combinational
WB error output.

Current source sets EX error info constant zero and routes most capability policy
faults through LSU/WB error classification; this must be followed from actual
assignments, not generic three-phase model alone.

## 12. Stack high-watermark

Successful store in configured stack range updates `mshwm` at 16-byte granularity.
Update qualifies LSU request, no CHERIoT error, write direction and bounds window.

## 13. Mode/debug gates

Runtime CHERIoT enable chooses unified LSU output. Debug mode suppresses many
capability faults and load clear-permission effects, enabling debugger access by
policy. One-way enable assertion in core prevents reverting RF interpretation.

## 14. Findings

- **Fact F-CH-01:** CHERIoT EX also checks RV32-size memory operations in CHERIoT mode.
- **Fact F-CH-02:** Capability data+metadata forwarding is implemented locally.
- **Fact F-CH-03:** `lsu_cheriot_err` is marked timing critical in RTL comments.
- **Open O-CH-01:** Validate all fault cause/index encodings against CHERIoT spec.
- **Open O-CH-02:** Synthesis timing for SetBounds and RV32 LSU bounds checks.

## 15. L4 handoff

Representability boundaries, all permissions, sealed/unsealed, sentry types,
debug bypass, forwarding dependency, CLC/CSC beat sequence, SCR illegal/ASR,
PCC near bounds and one-way enable.

## 16. Source anchors

- [`rtl/ibex_cheriot_ex.sv`](../../../../rtl/ibex_cheriot_ex.sv)
- [`rtl/ibex_cheriot_pkg.sv`](../../../../rtl/ibex_cheriot_pkg.sv)
- [`rtl/ibex_register_file_ff.sv`](../../../../rtl/ibex_register_file_ff.sv)

