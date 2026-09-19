# 16 — Deep dive PMP/ePMP

## 1. Contract

`ibex_pmp` là combinational access checker. CSR block sở hữu configuration;
core cung cấp per-channel address/type/privilege. Output error chặn IF/LSU.

## 2. Three channels

- I: current fetch PC, execute.
- I2: PC+2, execute for cross-word 32-bit instruction.
- D: LSU aligned/effective address, read/write, privilege including MPRV.

PMP addresses rộng hơn 32 để hỗ trợ bound arithmetic/physical representation.

## 3. Region matching

Modes:

- OFF: no match;
- TOR: previous entry address ≤ request < current address;
- NA4: exact 4-byte naturally aligned;
- NAPOT: mask derived from trailing ones encodes power-of-two range.

`PMPGranularity` masks low address bits and can disable NA4. Matching must cover
all bytes of access; request type selects R/W/X permission.

## 4. Priority

Entries scan in index order; lowest matching index wins. A high-priority partial
match can deny even if a later broad region allows. Correct region match and
permission are separate signals.

## 5. Privilege and MPRV

Instruction channel uses current privilege. Data channel uses MPP when
`mstatus.MPRV=1`. M-mode bypass behavior depends lock/ePMP policy; U-mode normally
requires matching allow entry.

Debug mode has allow handling for configured debug module address/mask so debug
ROM/data remains accessible under intended policy.

## 6. Smepmp controls

- MML reinterprets locked rules and restricts machine-mode policy changes.
- MMWP changes unmatched M-mode default to deny.
- RLB permits controlled lock bypass before permanent lockdown.

CSR logic prevents illegal R/W combination and creation of new M-executable
locked region after MML unless RLB permits.

## 7. TOR neighbour locking

In TOR, entry i uses `pmpaddr[i-1]` as lower bound. Locking entry i can therefore
make previous address register non-writable even if previous cfg itself unlocked.
CSR write-enable equations explicitly check next entry mode/lock.

## 8. CHERIoT gating

Runtime CHERIoT On gates comparator addresses to zero and output errors to zero.
Capability checks replace PMP enforcement. Gating addresses also reduces
unnecessary comparator switching/information leakage.

**Invariant I-PMP-01:** Exactly one policy domain enforces each runtime mode:
PMP in RV32; PCC/capabilities in CHERIoT.

## 9. Error integration

IF combines I/I2 with bus/PCC errors. LSU captures D PMP error at address phase;
external request may be suppressed, so FSM must complete locally. PMP error maps
to instruction/load/store access fault in RV32.

## 10. Assertions/coverage

- Region priority and first-match.
- Legal config modes/granularity.
- Address/config lock suppression.
- MML/MMWP/RLB combinations.
- Request error known.
- Cross-region/cross-word accesses.

## 11. Findings

- **Fact F-PMP-01:** I2 channel is necessary even with aligned bus because ISA
  instruction can begin at halfword offset.
- **Fact F-PMP-02:** PMP hardware remains elaborated but functionally gated in
  CHERIoT runtime mode.
- **Open O-PMP-01:** Produce exhaustive region-boundary tests per access size.
- **Open O-PMP-02:** Validate reset PMP arrays against FX1 boot security policy.

## 12. L4 handoff

OFF/TOR/NA4/NAPOT, overlap priority, boundary bytes, PC+2 denial, U/M/MPRV,
locked writes, MML/MMWP/RLB, debug range and CHERIoT runtime gating.

## 13. Source anchors

- [`rtl/ibex_pmp.sv`](../../../../rtl/ibex_pmp.sv)
- [`rtl/ibex_cs_registers.sv`](../../../../rtl/ibex_cs_registers.sv)
- [`rtl/ibex_core.sv`](../../../../rtl/ibex_core.sv)

