// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// S4-only coverage confirmation.  The matching UVM test guarantees delayed
// D-side responses, so each following instruction overlaps the prior load.

  .section .text.init
  .org 0x80
  .globl _start
_start:

  la    t0, s4_data
  li    t2, 7
  li    t3, 3
  li    t4, 32

s4_loop:
  lw    x0, 0(t0)
  mul   t1, t2, t3
  lw    x0, 0(t0)
  div   t1, t2, t3
  la    t0, s4_jump_target_ptr
  lw    t1, 0(t0)
  jalr  x0, t1, 0

s4_jump_target:
  addi  t4, t4, -1
  bnez  t4, s4_loop
  j     pass

pass:
  fence
  // The current Ibex UVM flow watches signature_addr - 4.  TEST_PASS is
  // payload zero and TEST_RESULT is signature type one, hence data == 1.
  li    sp, 0x8ffffff8
  li    ra, 1
  sw    ra, 0(sp)
1:
  j     1b

  .data
  .align 2
s4_data:
  .word 0x12345678
s4_jump_target_ptr:
  .word s4_jump_target
