// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Stage S4/S5 functional-coverage and branch exclusion file for VCS
// (`urg -elfile`). Source of truth: doc/coverage_hole_register.csv and
// doc/s4_pipe_cross_families.csv in the top-level `intern` report
// repository. Every entry below is a class B (configuration-unreachable)
// or class C (architecturally unreachable) hole from that register;
// class A/D/E holes are never excluded here.
//
// VERIFIED 2026-08-24 (doc/s7_readiness_worklist.md item 5): this file was
// generated in the correct VCS syntax by cross-checking against real
// `urg -dump full_exclusions group` and `-dump full_exclusions branch`
// output from this project's own build (X-2025.06), then round-tripped
// through a real `urg -elfile` run against
// results/maxperf-icache/20260822_s5_extended's merged.vdb and confirmed
// to take effect exactly as expected: pipe_cross EXPECTED 516->304,
// UNCOVERED 241->29 (-212, matching the 212 excluded bins exactly);
// stall_cross EXPECTED 57->51, UNCOVERED 6->0 (-6, all 6 excluded bins);
// cp_icache_ecc_err EXPECTED 1->0; BRANCH 84.59%->84.64%; GROUP
// 94.85%->94.86%. This is a real, working exclusion file, not a draft.
//
// An earlier draft of this file used Xcelium/IMC-style `exclude -cross
// ... -du ...` TCL syntax copied from waivers/coverage_waivers_xlm.tcl --
// wrong tool (that file is for Xcelium, this project uses VCS) and it
// failed with Error-[UCAPI-EL-SE] Syntax error on the very first line when
// actually tested. This file replaces it entirely, in the format VCS
// itself dumps: `CHECKSUM`/`ANNOTATION`/`covergroup`/`coveritem`/`bins`
// blocks for functional-coverage (group) exclusions, and
// `CHECKSUM`/`ANNOTATION`/`INSTANCE`/`Branch N (vector)` blocks for branch
// exclusions -- both confirmed by decompiling this project's own
// `-dump full_exclusions` output rather than assumed.
//
// Regenerate the pipe_cross bins block below with (from this directory):
//   python3 scripts/gen_pipe_cross_exclusions.py \
//     ../../../../doc/s4_pipe_cross_families.csv \
//     --output <paste output back into the coveritem "pipe_cross" section>
// if doc/s4_pipe_cross_families.csv changes.
//
// Checksums below are tied to the current design (commit
// 7b5df75a041affe56e8c235260f98a09b3319008) and this project's own
// core_ibex_fcov_if.sv / ibex_icache.sv. If either changes, VCS's checksum
// check will reject stale entries at load time -- regenerate via
// `urg -dump full_exclusions group branch` against a fresh build rather
// than hand-editing checksums.

// ------------------------------------------------------------------
// Functional coverage (group): stall_cross (6 bins) + pipe_cross (212
// bins) + cp_icache_ecc_err (1 bin), all under core_ibex_fcov_if's
// uarch_cg covergroup.
// ------------------------------------------------------------------

CHECKSUM: "603581044 3862543758"
ANNOTATION: "/home/dungpc/projects/intern/ibex/dv/uvm/core_ibex/fcov/core_ibex_fcov_if.sv, 423"
covergroup core_ibex_tb_top.dut.u_ibex_top.u_ibex_core.u_fcov_bind::uarch_cg
	coveritem "stall_cross"
		// S4-WB-003 (class B): BranchTargetALU=1 & SecureIbex=0 on C1/C2 zero
		// both terms of stall_branch. Configuration-unreachable.
		bins {{"auto_InstrCategoryBranch"}, {"auto_IdStallTypeInstr"}}
		// S4-WB-004 (class B): stall_jump = ~BranchTargetALU is tied low on
		// C1/C2. Configuration-unreachable.
		bins {{"auto_InstrCategoryJump"}, {"auto_IdStallTypeInstr"}}
		// S4-WB-007 (class B): FENCE.I decodes as a jump; same stall_jump
		// tie-off as S4-WB-004 applies.
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IdStallTypeInstr"}}
		// S4-WB-008 (class C): InstrCategoryNone requires ~instr_valid_i; a
		// non-none stall type requires instr_valid_i. Architecturally
		// unreachable.
		bins {{"auto_InstrCategoryNone"}, {"auto_IdStallTypeMem"}}
		// S4-WB-001 (class C, reclassified from A): id_stall_type priority
		// (last-match-wins) masks stall_mem with stall_multdiv for MUL.
		// Confirmed unreachable by s4_stall_confirmation.2730 (154 Instr / 0
		// Mem samples).
		bins {{"auto_InstrCategoryMul"}, {"auto_IdStallTypeMem"}}
		// S4-WB-002 (class C, reclassified from A): DIV always asserts
		// stall_multdiv while occupying ID. Confirmed unreachable by
		// s4_stall_confirmation.2730 (1337 Instr / 0 Mem samples).
		bins {{"auto_InstrCategoryDiv"}, {"auto_IdStallTypeMem"}}
	coveritem "pipe_cross"
		// S4-WB-011 (special_req_forces_retain_id)
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		// S4-WB-010 (unstalled_ID_conflicts_with_backpressure)
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryALU"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryBranch"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRAccess"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCSRIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryCompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryDiv"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakDbg"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryEBreakExc"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryECall"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFence"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFenceI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryFetchError"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryJump"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryLoad"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMRet"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryMul"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryPrivIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryStore"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryUncompressedIllegal"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageEmptyAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndFetching"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageEmpty"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndStalled"}}
		bins {{"auto_InstrCategoryWFI"}, {"auto_IFStageFullAndIdle"}, {"auto_PipeStageFullAndUnstalled"}, {"auto_PipeStageFullAndUnstalled"}}
	coveritem "cp_icache_ecc_err"
		// S4-IC-003 (class B): C2 fixes ICacheECC=0, so the error indication
		// can never assert. Configuration-unreachable.
		bins "seen"

// ------------------------------------------------------------------
// Branch coverage: ibex_icache, inval_state_q AWAIT_SCRAMBLE_KEY false-key
// arm (S4-IC-002, class B). C2 has ICacheScramble=0 and ibex_top ties
// scramble_key_valid_q high, so this arm cannot occur in this
// configuration. VCS attributes the whole `unique case (inval_state_q)`
// (rtl/ibex_icache.sv:1219) to one Branch id (33) with per-state,
// per-sub-condition outcome vectors; outcome (3) is specifically
// `AWAIT_SCRAMBLE_KEY` with `ic_scr_key_valid_i` false (the branch at
// rtl/ibex_icache.sv:1234, `if (ic_scr_key_valid_i) begin`).
// ------------------------------------------------------------------

CHECKSUM: "4082493236 2371012685"
ANNOTATION: "ModuleName: ibex_icache"
INSTANCE: core_ibex_tb_top.dut.u_ibex_top.u_ibex_core.if_stage_i.gen_icache.icache_i
Branch 33 "2484666242" "inval_state_q" (3) "inval_state_q AWAIT_SCRAMBLE_KEY ,-,0,-,-,-"
