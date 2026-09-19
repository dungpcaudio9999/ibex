# 20 — FX1 findings và verification backlog

## 1. Executive conclusion

Static L3 review không thấy đủ bằng chứng để gọi FX1 configuration sai, nhưng
nó xác định các điểm phải được chứng minh trước sign-off. Rủi ro cao nhất là tổ
hợp `SecureIbex=1`, lockstep active, `ResetAll=0`, `MemECC=0`; tiếp theo là ISA/
firmware compatibility do `RV32BNone` và Zca-only.

## 2. Priority findings

### FX1-H1 — Lockstep với `ResetAll=0`

- **Fact:** Shadow reset/compare enable có sequencing riêng; payload flops có thể
  không reset.
- **Risk:** X/mismatch hoặc dependence on uninitialized payload trước first write.
- **Required evidence:** 4-state X-prop, randomized reset release, gate-level if
  available, compare DEV versus DEV-resetall.
- **Exit:** no spurious/missed compare across defined reset assumptions.

### FX1-H2 — Memory integrity disabled

- **Fact:** Main/shadow can receive same corrupted bus response; MemECC logic is
  generated out.
- **Risk:** Common-input data/instruction corruption not detected by lockstep.
- **Required decision:** External fabric ECC or accepted security reduction.
- **Exit:** documented threat coverage and integration test.

### FX1-H3 — Firmware ISA compatibility

- **Fact:** FX1 removes OTEarlGrey bitmanip and Zcb/Zcmp, changes M latency.
- **Risk:** Existing OpenTitan firmware binary traps or build libraries emit
  unsupported instructions.
- **Required evidence:** binary disassembly audit, toolchain `-march`, boot ROM/
  library regression.
- **Exit:** zero unsupported opcodes or explicit emulation/rebuild plan.

### FX1-H4 — Missing design record

- **Fact:** YAML references nonexistent `doc/fx1_secure_config_eval.md`.
- **Risk:** Requirements/rationale for countermeasure overrides cannot be audited.
- **Exit:** restore/create reviewed decision record and link tests to each choice.

## 3. Medium findings

### FX1-M1 — DEV/PROD debug delta

DEV enables two triggers; PROD disables triggers while keeping count field. Need
CSR read/write, trigger match and debug-module integration tests for both.

### FX1-M2 — HPM delta

DEV has four optional counters, PROD zero. Verify absent counters read zero,
writes ignored/illegal as designed, and software does not assume availability.

### FX1-M3 — CHERIoT/PMP mode boundary

PMP errors/address switching gate off in CHERIoT mode. Verify one-way enable
transition has no access-control gap and invalid MuBi encoding alerts/fails safe.

### FX1-M4 — TRVK integration assumptions

Interconnect must preserve two-beat capability ordering and maximum two
outstanding responses. Add integration assertions at SoC boundary.

### FX1-M5 — No I-cache

Functional risk low, but cache-control CSR/FENCE.I/software expectations and
performance targets require explicit verification.

## 4. Low/maintenance findings

- Config optional fields require TB/top defaults kept synchronized.
- Existing Vietnamese docs mostly describe OpenTitan; labels must not imply FX1.
- Large untracked output directories are not reproducible evidence.
- ShadowCSR is disabled despite SecureIbex; security matrix should say so.

## 5. FX1 feature matrix

| Mechanism | DEV | PROD | Evidence status |
|---|---:|---:|---|
| Lockstep | on | on | static traced; dynamic pending |
| Split RF ECC | on | on | static traced; injection pending |
| MemECC | off | off | config confirmed; threat decision pending |
| ResetAll | off | off | config confirmed; X-prop pending |
| Dummy instructions | off | off | config confirmed |
| DIT support | on | on | runtime timing tests pending |
| PC increment check | on | on | injection test pending |
| PMP RV32 | on | on | boundary regression pending |
| CHERIoT/TRVK | on | on | directed/integration pending |
| Debug triggers | 2 | off | delta tests pending |
| Optional HPM | 4 | 0 | CSR tests pending |

## 6. Recommended L4 order

1. Freeze tool/config manifest and smoke both DEV/PROD.
2. Reset/lockstep/X-prop comparison with DEV-resetall.
3. ISA binary audit and arithmetic/branch/MUL-DIV smoke.
4. LSU grant/response/misaligned matrix.
5. Exception/IRQ/debug precision.
6. PMP boundaries and mode switch.
7. CHERIoT authority/CLC/CSC.
8. TRVK/error/fault injection.
9. Differential regression and final accepted-risk record.

## 7. Sign-off artifacts required

- Versioned FX1 configuration rationale.
- Parameter/elaborated hierarchy report.
- Firmware ISA compatibility report.
- Reset/X-prop report.
- Security-countermeasure coverage matrix.
- Protocol assumption list signed by interconnect owner.
- Reproducible regression commands/seeds/results.
- Waivers for every open formal/coverage hole.

## 8. Scope statement

These are L3 findings, not confirmed silicon defects. Items labeled risk/open
become conclusions only after L4 simulation, formal proof, synthesis/netlist or
system-integration evidence as appropriate.

