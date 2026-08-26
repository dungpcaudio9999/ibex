// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module core_ibex_fcov_bind;
  bind ibex_core core_ibex_fcov_if u_fcov_bind (
    .*
  );

  bind ibex_core core_ibex_pmp_fcov_if
  #(.PMPGranularity(PMPGranularity),
    .PMPNumRegions(PMPNumRegions),
    .PMPEnable(PMPEnable)
  ) u_pmp_fcov_bind (
    .*
  );

  // Stage S6 (doc/s6_coverage_plan.md). ibex_icache is only elaborated as
  // if_stage_i.gen_icache.icache_i when ICache=1; core_ibex_icache_fcov_if
  // gates every reference into it on the same parameter, so C0/C1 pick up
  // nothing new.
  bind ibex_core core_ibex_icache_fcov_if
  #(.ICache(ICache)
  ) u_icache_fcov_bind (
    .*
  );
endmodule
