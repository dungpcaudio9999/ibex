# Learning and Analysis Approaches for This Ibex Repository

## 1. Purpose and scope

This document presents practical approaches for learning and analysing the Ibex
implementation in this repository. The target is not a generic upstream Ibex
checkout. The current tree contains:

- the CHERIoT-capable Ibex RTL;
- the OpenTitan configuration;
- local FX1 configurations and RTL/configuration changes in the working tree;
- a VCS/UVM/Spike verification environment;
- local Vietnamese design notes and waveform support.

Consequently, a complete understanding requires separating three layers:

1. **Architectural behaviour**: RISC-V and CHERIoT-visible behaviour.
2. **Microarchitecture**: pipeline, datapaths, control, memories, protection and
   security mechanisms.
3. **Project-specific integration**: configuration selection, FX1 deltas,
   simulation, verification and implementation flows.

The word "complete" should cover at least ISA behaviour, parameter elaboration,
the pipeline, memory interfaces, exceptions and debug, CHERIoT, security, DV,
formal verification and synthesis considerations.

## 2. Common preparation for every approach

Before selecting a detailed approach, establish a reproducible baseline:

1. Record the Git commit, branch and all uncommitted changes.
2. Select one named configuration as the initial reference.
3. Generate a parameter truth table for that configuration.
4. Identify which RTL branches are elaborated in or out.
5. Run one known test and retain its log, disassembly, trace and waveform.
6. Keep upstream/CHERIoT behaviour separate from local FX1 changes.

This repository is currently on `feature/server-work`. The committed Vietnamese
analysis mainly targets `opentitan`, while the working tree adds
`fx1_secure_adj`, `fx1_secure_dev`, `fx1_secure_dev_resetall` and
`fx1_secure_prod`. Conclusions for one configuration must not be silently
applied to another.

## 3. Approach A: full-stack spiral learning

### Objective

Build a durable end-to-end model of the CPU by revisiting every topic at
increasing levels of detail.

### Method

For each topic:

1. Learn the architectural contract.
2. Locate the responsible RTL hierarchy.
3. Trace one representative instruction or event.
4. Inspect its waveform.
5. Find the assertions, tests and reference-model checks that verify it.

Suggested order:

```text
Configuration and hierarchy
        -> basic pipeline
        -> ALU, branch and memory operations
        -> hazards, stalls and forwarding
        -> exceptions, interrupts and debug
        -> CSR, PMP and cache
        -> CHERIoT and security mechanisms
        -> UVM, co-simulation, coverage and formal
        -> FX1 configuration assessment
```

### Best suited for

Engineers who want comprehensive knowledge and will work across design,
debugging and verification.

### Typical outcome

- a complete architecture map;
- a set of golden instruction/event traces;
- a configuration-impact matrix;
- a design-to-verification traceability matrix.

### Estimated effort

Approximately 25 to 35 focused study sessions.

## 4. Approach B: RTL top-down analysis

### Objective

Understand the implementation as a hardware designer, starting at integration
boundaries and progressively descending into control and datapath blocks.

### Method

Read the design in hierarchy order:

```text
ibex_top / ibex_top_tracing
  -> ibex_core
     -> IF stage
     -> ID stage: decoder and controller
     -> EX block: ALU and multiply/divide
     -> CHERIoT execution block
     -> load-store unit
     -> writeback stage
     -> CSR and PMP
  -> register file and I-cache RAMs
  -> lockstep shadow core
  -> tag-revocation block
```

For every module, document:

- responsibility and architectural boundary;
- parameters and generated variants;
- input/output contracts;
- state elements and state machines;
- datapath and control decisions;
- back-pressure, kill, flush and error paths;
- configuration-specific active/inactive logic;
- important assertions and waveform probes.

### Best suited for

RTL designers, reviewers and engineers who need to modify the CPU safely.

### Strengths and limitations

It gives the clearest ownership map and exposes parameter-dependent hardware.
Runtime intuition should be reinforced with a few instruction traces, because a
pure hierarchy walk does not by itself reveal all multi-cycle interactions.

### Estimated effort

Approximately 15 to 20 focused study sessions for the main pipeline, with extra
sessions for CHERIoT and security.

## 5. Approach C: waveform and instruction first

### Objective

Build an intuitive cycle-by-cycle model before reading every implementation
detail.

### Method

Create golden traces for representative scenarios:

- an ordinary ALU instruction;
- a taken branch;
- a load-use hazard;
- a misaligned access;
- multiplication and division;
- an exception and an interrupt;
- a PMP access fault;
- a CHERIoT capability operation or fault.

For each scenario, follow:

```text
PC -> fetch -> decode -> operands -> execute
   -> memory/redirect -> writeback -> retirement/RVFI
```

Then open the relevant RTL only after identifying the controlling waveform
signals.

### Best suited for

Engineers who need rapid debugging competence or learn best from concrete
execution examples.

### Strengths and limitations

This is the fastest way to acquire pipeline intuition. It can miss elaborated
but rarely activated logic, so it should later be supplemented by a hierarchy
and assertion review.

### Estimated effort

Approximately 10 to 15 focused study sessions.

## 6. Approach D: verification-first analysis

### Objective

Understand how architectural correctness is demonstrated and how failures are
diagnosed.

### Method

Trace the verification flow end to end:

```text
test list and riscv-dv configuration
  -> generated assembly
  -> compiler and linker
  -> VCS/UVM simulation
  -> RVFI/trace collection
  -> Spike co-simulation
  -> signature and timeout checks
  -> functional/code coverage
```

Map each feature to its stimulus, checker, assertions, coverage points and
known proof holes.

### Best suited for

DV engineers, regression owners and designers responsible for root-causing
failures.

### Typical outcome

A matrix answering: "Which test, assertion, scoreboard, co-simulation check or
formal property detects this class of bug?"

### Estimated effort

Approximately 15 to 20 focused study sessions.

## 7. Approach E: FX1 delta-first analysis

### Objective

Answer project decisions quickly by analysing only the differences between the
reference OpenTitan configuration and the intended FX1 configurations.

### Main comparisons

- `opentitan` versus `fx1_secure_adj`;
- `fx1_secure_adj` versus `fx1_secure_dev`;
- `fx1_secure_dev` versus `fx1_secure_prod`;
- `fx1_secure_dev` versus `fx1_secure_dev_resetall`.

### Key questions

- What are the consequences of `SecureIbex=1` with `MemECC=0`,
  `DummyInstructions=0` and `ResetAll=0`?
- How does `RV32MFast` change latency and area relative to
  `RV32MSingleCycle`?
- What firmware compatibility is lost by disabling the OpenTitan bitmanip and
  Zcmp features?
- How do DEV and PROD differ in debug and performance-monitoring behaviour?
- Is lockstep initialization safe when not all data flops are reset?
- Which tests prove each deliberate difference?

### Best suited for

Engineers who need immediate project-specific answers, configuration reviews or
sign-off evidence.

### Strengths and limitations

This approach has the shortest path to FX1 decisions. It assumes enough RISC-V
and pipeline knowledge to interpret the deltas correctly.

### Estimated effort

Approximately 10 to 20 focused sessions, depending on the required sign-off
depth.

## 8. Approach F: security and formal deep dive

### Objective

Understand and verify the mechanisms that protect control flow, register state,
memory data and capabilities.

### Scope

- main/shadow lockstep operation;
- split register-file ECC storage and checking;
- instruction/data memory integrity;
- I-cache ECC and scrambling;
- PC increment checking and dummy instructions;
- PMP/ePMP;
- CHERIoT bounds, permissions, tags and revocation;
- alerts and fault propagation;
- trace-equivalence proofs against the Sail model.

### Best suited for

Security reviewers, formal engineers and sign-off owners.

### Constraints

The formal flow may require large compute resources and some properties have
explicit environmental assumptions or proof holes. Results must therefore be
reported together with their assumptions.

### Estimated effort

Approximately 15 to 25 focused study sessions after learning the base pipeline.

## 9. Selection guide

| Primary goal | Recommended approach |
|---|---|
| Complete long-term understanding | A |
| RTL design or RTL modification | B |
| Fast cycle-level intuition | C |
| UVM/regression/debug ownership | D |
| Immediate FX1 decisions | E |
| Security or formal sign-off | F |
| Complete understanding with an FX1 destination | A followed by E |

Approaches are complementary. A practical sequence for a CPU design engineer
is **B -> C -> D -> E**, while the full curriculum in Approach A interleaves
those activities topic by topic.

## 10. Repository entry points

- `rtl/ibex_top.sv`: integration boundary and security wrappers.
- `rtl/ibex_core.sv`: central pipeline wiring.
- `rtl/ibex_if_stage.sv`: fetch, decompression and IF/ID state.
- `rtl/ibex_id_stage.sv`: decode, controller and issue/retirement control.
- `rtl/ibex_ex_block.sv`: ALU and multiply/divide execution.
- `rtl/ibex_load_store_unit.sv`: data-side bus protocol and alignment.
- `rtl/ibex_cs_registers.sv`: machine/debug CSRs and counters.
- `rtl/ibex_cheriot_ex.sv`: CHERIoT execution and capability checks.
- `rtl/ibex_lockstep.sv`: shadow core and comparison logic.
- `rtl/ibex_trvk.sv`: capability-tag revocation path.
- `ibex_configs.yaml`: named parameter sets, including local FX1 variants.
- `dv/uvm/core_ibex`: constrained-random and co-simulation environment.
- `dv/formal`: Sail trace-equivalence formal flow.

