// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Stage S6 functional coverage extension for the instruction cache.
// See doc/s6_coverage_plan.md for the coverpoint/cross table this
// implements and the RTL derivation for every bin. Structural coverage
// (100% line/branch on ibex_icache) does not demonstrate hit, miss, fill,
// replacement, invalidate-during-fill, or redirect-during-fill behavior --
// this interface adds the functional bins the official coverage plan
// (doc/03_reference/coverage_plan.rst) does not have (S4-IC-004).
//
// Bound to ibex_core (fcov/core_ibex_fcov_bind.sv), same as
// core_ibex_fcov_if and core_ibex_pmp_fcov_if. ibex_icache is only
// elaborated as if_stage_i.gen_icache.icache_i when ICache=1
// (rtl/ibex_if_stage.sv), so every reference into it is generate-gated on
// the ICache parameter, mirroring core_ibex_pmp_fcov_if's PMPEnable gating
// -- C0/C1 (ICache=0) elaborate nothing new from this file.

`include "prim_assert.sv"

interface core_ibex_icache_fcov_if import ibex_pkg::*; #(
    parameter bit ICache = 1'b0
) (
  input clk_i,
  input rst_ni
);
  `include "dv_fcov_macros.svh"
  import uvm_pkg::*;

  bit en_icache_fcov;

  initial begin
    if (ICache) begin
      void'($value$plusargs("enable_ibex_fcov=%d", en_icache_fcov));
    end else begin
      en_icache_fcov = 1'b0;
    end
  end

  if (ICache) begin : g_icache_cgs
    // Local aliases onto if_stage_i.gen_icache.icache_i, kept short so the
    // covergroup body below reads like the coverage plan table rather than
    // a wall of hierarchical paths.
    wire lookup_valid   = if_stage_i.gen_icache.icache_i.lookup_valid_ic1;
    wire tag_hit        = if_stage_i.gen_icache.icache_i.tag_hit_ic1;
    wire tag_invalid_any = |if_stage_i.gen_icache.icache_i.tag_invalid_ic1;
    wire [3:0] fill_busy = if_stage_i.gen_icache.icache_i.fill_busy_q;
    wire fill_stale_any  = |if_stage_i.gen_icache.icache_i.fill_stale_q;
    wire branch          = if_stage_i.gen_icache.icache_i.branch_i;
    wire skid_valid      = if_stage_i.gen_icache.icache_i.skid_valid_q;
    wire err_plus2       = if_stage_i.gen_icache.icache_i.err_plus2_o;
    wire icache_enable   = if_stage_i.gen_icache.icache_i.icache_enable_i;
    wire inval_active    = if_stage_i.gen_icache.icache_i.inval_active;

    wire lookup_miss = lookup_valid & ~tag_hit;

    `ASSERT_KNOWN(IcacheFcovFillBusyKnown, fill_busy)

    // skid_err_cross (doc/s6_coverage_plan.md) found the "no_skid x
    // err_plus2" bin unreachable across 30 iterations / 3 generators.
    // rtl/ibex_icache.sv:1196 shows why -- err_plus2_o is defined directly
    // as `skid_valid_q & ~skid_err_q`, so it can never be asserted while
    // skid_valid_q is low. This is architecturally impossible, not merely
    // rare (unlike "skid x no_err_plus2", the cross's other empty bin,
    // which requires skid_err_q=1 while skid-held and remains a genuine,
    // reachable, just-not-yet-observed stimulus gap).
    `ASSERT(IcacheFcovErrPlus2ImpliesSkid, err_plus2 |-> skid_valid)

    covergroup icache_cg @(posedge clk_i);
      option.per_instance = 1;
      option.name = "icache_cg";

      cp_lookup: coverpoint tag_hit iff (lookup_valid) {
        bins hit  = {1'b1};
        bins miss = {1'b0};
      }

      // fill_busy is NUM_FB=4 bits wide (rtl/ibex_icache.sv), so
      // $countones ranges 0-4; bound the top bin explicitly rather than
      // with an open [2:$] range, which VCS otherwise expands against a
      // mismatched signed 32-bit width (Warning-[CPBRM]).
      cp_fill_busy: coverpoint $countones(fill_busy) {
        bins idle            = {0};
        bins one_active      = {1};
        bins multiple_active = {[2:4]};
      }

      cp_fill_stale: coverpoint fill_stale_any {
        bins not_stale = {1'b0};
        bins stale      = {1'b1};
      }

      // Sampled at the point of a miss, when an allocation is actually
      // requested -- tag_invalid_ic1 is exactly the signal
      // lowest_invalid_way_ic1 is derived from (rtl/ibex_icache.sv), so
      // this distinguishes "an invalid way was available" from "all ways
      // valid, round-robin eviction required" without needing to also
      // track sel_way_ic1's own one-cycle-later timing.
      cp_way_alloc: coverpoint tag_invalid_any iff (lookup_miss) {
        bins first_invalid_way = {1'b1};
        bins round_robin_evict = {1'b0};
      }

      cp_skid: coverpoint skid_valid {
        bins no_skid = {1'b0};
        bins skid    = {1'b1};
      }

      cp_inval: coverpoint inval_active {
        bins idle         = {1'b0};
        bins invalidating = {1'b1};
      }

      cp_icache_enable: coverpoint icache_enable {
        bins disabled = {1'b0};
        bins enabled  = {1'b1};
      }

      cp_branch: coverpoint branch {
        bins no_branch    = {1'b0};
        bins taken_branch = {1'b1};
      }

      cp_err_plus2: coverpoint err_plus2 {
        bins no_err_plus2 = {1'b0};
        bins err_plus2    = {1'b1};
      }

      // Lookups seen in both enable states -- mirrors the enable/lookup
      // style crosses already in core_ibex_fcov_if.
      lookup_enable_cross: cross cp_lookup, cp_icache_enable;

      // Invalidate request arriving while a fill is outstanding.
      inval_fill_cross: cross cp_inval, cp_fill_busy;

      // Redirect while a fill is outstanding -- fill_stale_d's own RTL
      // condition (fill_busy_q[fb] & (branch_i | fill_stale_q[fb])) made
      // directly observable rather than inferred from fill_stale alone.
      branch_fill_cross: cross cp_branch, cp_fill_busy;

      // A line/beat-crossing compressed instruction combined with a fetch
      // error on the second half -- the two hardest-to-hit fetch-path
      // corners co-occurring.
      skid_err_cross: cross cp_skid, cp_err_plus2;
    endgroup

    `DV_FCOV_INSTANTIATE_CG(icache_cg, en_icache_fcov)
  end

endinterface
