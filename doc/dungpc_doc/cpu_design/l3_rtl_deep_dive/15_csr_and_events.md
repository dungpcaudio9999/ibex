# 15 — Deep dive CSR và architectural events

## 1. State inventory

Groups:

- IDs/ISA: vendor/arch/implementation/hart, dynamic MISA.
- Machine: mstatus, mie/mip, mtvec, mepc, mcause, mtval, mscratch.
- Debug: dcsr, depc, dscratch, triggers.
- Counters: mcycle, minstret, mhpmcounter/event, inhibit/counteren.
- PMP: cfg/address/mseccfg.
- Recovery/custom: mstack*, CPUCTRLSTS, secure seed, double-fault.
- CHERIoT: PCC and trap/debug/scratch capability registers, stack watermark.

## 2. CSR read/write pipeline

Read mux is combinational by CSR address. CSR op block computes write/set/clear.
`csr_op_en` pulses only when instruction executes. Illegal checks cover unimplemented
address, privilege, read-only/write restrictions and CHERIoT system-register
permission.

Hardware exception/debug updates have priority over software writes to same
state. `ibex_csr` optionally supports shadow-copy error reporting, but core sets
`ShadowCSR=0` in this tree.

## 3. Dynamic MISA

M/E/X bits change with CHERIoT runtime mode; M/B/C reflect parameters. `marchid`
also has CHERIoT-specific value behavior. Software reading ISA identity must not
assume immutable base I across mode switch.

## 4. Trap entry state update

On `csr_save_cause` outside debug:

- privilege becomes M;
- MIE saves to MPIE then clears;
- MPP saves old privilege;
- EPC selected from IF/ID/WB control;
- cause/value written;
- recoverable NMI state may save additional stack registers.

Exception hardware update outranks normal CSR write in same cycle.

## 5. Return

MRET restores privilege/MIE and clears MPRV when returning below M. If in NMI
mode, restore from mstack state. DRET restores debug state and PC via DEPCC/DPC.

## 6. Interrupt combinational wake path

`mip` mirrors external pins combinationally. `irqs_o = mip & mie`, pending is OR.
Global MIE and controller policy are applied elsewhere. This separation allows
pending IRQ to wake gated clock even when controller cannot yet take it.

## 7. Counters

Mcycle/minstret plus N configured HPM counters. Event inputs are pulses from IF,
ID, LSU and WB. Inhibit controls updates. Speculative retire correction exists so
CSR reads observe architecturally ordered values with WB stage.

Unimplemented counters must read zero/ignore writes; arrays are partially
elaborated according to count/width.

## 8. Debug/trigger

DCSR holds step and EBREAK policies. Trigger compare matches PC(s) when enabled;
DEV has 2, OpenTitan default 1, PROD disables trigger block. DPC source chosen by
controller IF/ID debug entry.

## 9. CPU control

Custom CSR controls DIT, dummy instruction, I-cache and seed/status. Parameter
gates feature availability. MuBi `mcounteren_writable_i` controls whether policy
is software writable; invalid encoding should fail safely/alert according to
secure logic.

## 10. CHERIoT SCR

Separate interface transports data+cap. PCC is decoded for IF/EX; MTCC/MEPCC/
MTDC and scratch/debug capability state replace/augment integer PC CSRs in
CHERIoT mode. MTVEC forced direct mode. `PCC.SR` governs system-register access;
ASR violation becomes capability fault.

## 11. PMP CSR locking

Per-entry cfg/address `ibex_csr` instances enforce lock and neighbouring TOR lock.
MSECCFG changes allowed encodings and suppresses writes that would weaken MML
policy. Reset arrays parameterize secure boot policy.

## 12. Double fault

Nested unrecoverable event sets sticky `double_fault_seen`. It contributes crash
state/control response rather than ordinary software-clear sequence. Exact SoC
reaction belongs integration policy.

## 13. Findings

- **Fact F-CSR-01:** Shadow CSR copies are disabled even in secure profiles.
- **Fact F-CSR-02:** IRQ pending is not identical to “IRQ will be taken”.
- **Fact F-CSR-03:** PROD HPM optional counters absent, not merely inhibited.
- **Open O-CSR-01:** Audit CSR reset/access map against FX1 requirements.
- **Open O-CSR-02:** Test all simultaneous hardware/software write priorities.

## 14. L4 handoff

CSR legality by privilege, CSR write coincident trap, all interrupt priorities,
MRET/NMI restore, WFI wake, trigger DEV/PROD, counter reads around retirement,
CHERIoT SCR/ASR and double-fault sequence.

## 15. Source anchors

- [`rtl/ibex_cs_registers.sv`](../../../../rtl/ibex_cs_registers.sv)
- [`rtl/ibex_csr.sv`](../../../../rtl/ibex_csr.sv)
- [`rtl/ibex_counter.sv`](../../../../rtl/ibex_counter.sv)

