# 19 — Cross-module invariants

## 1. Mục đích

Bug CPU thường xuất hiện ở biên module dù mỗi module riêng lẻ đúng. Danh sách
này là contract cần assertion, simulation hoặc formal evidence xuyên hierarchy.

## 2. Pipeline ownership

### I-X-01 — Một instruction, một owner

Instruction được IF/ID valid sở hữu ở ID; sau `en_wb && ready_wb` ownership sang
WB. Không được cả ID và WB phát cùng architectural side effect cho cùng lệnh.

### I-X-02 — Một retirement

Mỗi instruction kiến trúc tạo tối đa một RF/CSR/memory semantic completion và
một RVFI retirement; Zcmp micro-op obey macro contract.

### I-X-03 — Payload guarded by valid

Mọi unreset payload chỉ được dùng/compare khi matching valid/control initialized.
Đặc biệt quan trọng cho `ResetAll=0` và lockstep.

## 3. Stall and side effects

### I-X-04 — No replay under stall

LSU request, CSR write, branch/PCC update và RF write chỉ pulse/advance theo
first-cycle/request-done protocol; retained instruction không reissue.

### I-X-05 — Back-pressure closure

WB not ready propagates đến ID; ID not ready propagates đến IF; external response
buffers absorb already granted transactions without data loss.

### I-X-06 — Load-use correctness

ALU result may forward; load result stalls consumer until RF write/read safe.
Capability data+metadata follow same dependency.

## 4. Redirect and precise events

### I-X-07 — Wrong-path squash

Any branch/trap/debug redirect prevents stale fetch response entering ID and
prevents younger ID side effects.

### I-X-08 — Older fault priority

WB memory fault wins over younger ID illegal/debug/interrupt. EPC source matches
stage where fault belongs.

### I-X-09 — Interrupt boundary

IRQ taken only after current non-interruptible/multi-cycle/expanded instruction
reaches safe point; saved PC is next architectural PC.

## 5. Memory protocol

### I-X-10 — Grant/response accounting

Every response maps to a granted request; at most two D-side requests outstanding;
ordering matches LSU/TRVK assumption.

### I-X-11 — Split access atomic ownership

Both halves belong same instruction; error address/cause identifies failing half;
only one architectural completion.

### I-X-12 — Capability pair

Two 32-bit beats, tags, errors, permission-clear control and TRVK metadata remain
associated until reconstructed `cap_t`.

## 6. Mode and protection

### I-X-13 — Exclusive runtime ISA semantics

RV32 and CHERIoT execution paths never both issue side effects. Enable only
switches Off→On until reset; RF bank interpretation stays coherent.

### I-X-14 — Exactly one access-control domain

RV32 uses PMP/ePMP; CHERIoT uses PCC/capability. Transition must not create a
cycle where both disabled or conflicting.

### I-X-15 — Authority non-amplification

SetAddress/SetBounds/permission/seal/load-clear operations cannot create more
bounds/permissions/tag authority than source/root rules allow.

## 7. Security

### I-X-16 — Main/shadow temporal equivalence

Shadow input at N+offset equals main input N; compared outputs represent same
logical step. Reset/clock gating cannot break alignment.

### I-X-17 — RF data/ECC alignment

Main RF data/cap and shadow RF check bits share address/write epoch; decoder
checks matching codeword.

### I-X-18 — Alert completeness

Detected ECC, lockstep mismatch, invalid MuBi, PC mismatch and TRVK bitmap errors
reach correct alert class without X.

### I-X-19 — Fail-closed revocation

Revoked or failed bitmap lookup cannot return valid capability tag.

## 8. Verification mapping

| Invariants | Best evidence |
|---|---|
| X-01..06 | assertions + directed pipeline traces |
| X-07..09 | event-pair tests + RVFI/Spike |
| X-10..12 | protocol assertions + constrained timing permutations |
| X-13..15 | directed CHERIoT + formal/spec comparison |
| X-16..19 | fault injection, X-prop, assertions, gate review |

## 9. Current gaps

- No single document/test matrix proves all invariants end-to-end.
- Formal trace equivalence has documented holes for bus errors, debug, NMI and
  some CSRs.
- Physical independence of lockstep is outside RTL proof.
- FX1 override combinations need dedicated regression rather than reuse only
  OpenTitan evidence.

