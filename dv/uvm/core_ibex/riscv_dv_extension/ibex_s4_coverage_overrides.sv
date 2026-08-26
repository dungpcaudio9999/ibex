// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// S4-only debug ROM variant: keep the normal save/restore and DRET behavior,
// but put a side-effect-free load directly before DRET.  A delayed D-side
// response then proves the DRet x IdStallTypeMem bin is reachable.
class ibex_s4_dret_mem_debug_rom_gen extends riscv_debug_rom_gen;

  `uvm_object_utils(ibex_s4_dret_mem_debug_rom_gen)
  `uvm_object_new

  virtual function void gen_program();
    // The parent restore sequence leaves cfg.tp one word past its initialized
    // stack slot; use that known-valid address after all architectural GPRs
    // have been restored.  cfg.tp is randomized, so format its actual index.
    dret = $sformatf("lw x0, -4(x%0d)\n  dret", cfg.tp);
    super.gen_program();
  endfunction

endclass
