.section .text
.globl _start
.option norvc
j debug_rom
.align 3
j debug_exception
.align 7
.option rvc
_start:
h0_start:
                  li x10, 0x40001106
                  csrw 0x301, x10
kernel_sp:        
                  la x12, kernel_stack_end

trap_vec_init:    
                  la x10, mtvec_handler
                  ori x10, x10, 1
                  csrw 0x305, x10 # MTVEC

pmp_setup:        
                  csrwi 0x747, 4
                  la x2, main
                  li x10, 0x0
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b0, x2
                  la x2, main
                  li x10, 0x11111111
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b1, x2
                  la x2, main
                  li x10, 0x22222222
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b2, x2
                  la x2, main
                  li x10, 0x33333333
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b3, x2
                  li x2, 0xf0f0f0f
                  csrw 0x3a0, x2
                  la x2, main
                  li x10, 0x44444444
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b4, x2
                  la x2, main
                  li x10, 0x55555555
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b5, x2
                  la x2, main
                  li x10, 0x66666666
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b6, x2
                  la x2, main
                  li x10, 0x77777777
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b7, x2
                  li x2, 0xf0f0f0f
                  csrw 0x3a1, x2
                  la x2, main
                  li x10, 0x88888888
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b8, x2
                  la x2, main
                  li x10, 0x99999999
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3b9, x2
                  la x2, main
                  li x10, 0xaaaaaaaa
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3ba, x2
                  la x2, main
                  li x10, 0xbbbbbbbb
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3bb, x2
                  li x2, 0xf0f0f0f
                  csrw 0x3a2, x2
                  la x2, main
                  li x10, 0xcccccccc
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3bc, x2
                  la x2, main
                  li x10, 0xdddddddd
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3bd, x2
                  la x2, main
                  li x10, 0xeeeeeeee
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3be, x2
                  la x2, main
                  li x10, 0xffffffff
                  add x2, x2, x10
                  srli x2, x2, 2
                  csrw 0x3bf, x2
                  li x2, 0xf0f0f0f
                  csrw 0x3a3, x2

mepc_setup:       
                  la x10, init
                  csrw 0x341, x10

custom_csr_setup: 
                  csrwi 0x7c0, 1

init_machine_mode:
                  li x10, 0x1800
                  csrw 0x300, x10 # MSTATUS
                  li x10, 0x0
                  csrw 0x304, x10 # MIE
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  mret
init:             
                  li x0, 0x80000000
                  li x1, 0xf2a29fc8
                  li x2, 0x0
                  li x3, 0x0
                  li x4, 0xf55ae986
                  li x5, 0x80000000
                  li x6, 0x6
                  li x7, 0x3
                  li x8, 0xf4f77d4b
                  li x9, 0xb
                  li x10, 0x2e3a97b
                  li x11, 0x2
                  li x13, 0xd3867231
                  li x14, 0x304a526d
                  li x15, 0xa4a7ca8
                  li x16, 0x0
                  li x17, 0x0
                  li x18, 0x80000000
                  li x19, 0x80000000
                  li x20, 0x73c42ca1
                  li x21, 0x0
                  li x22, 0x8cbc6cda
                  li x23, 0xc
                  li x24, 0x80000000
                  li x25, 0x0
                  li x27, 0x0
                  li x28, 0x0
                  li x29, 0x35fbfb61
                  li x30, 0xfcf45d11
                  li x31, 0x5
                  la x26, user_stack_end
                  li x29, 0x8ffffffc
                  li x10, 0x0
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  j main
test_done:        
                  li x29, 0x8ffffff8
                  li x10, 0x0
                  slli x10, x10, 8
                  addi x10, x10, 0x1
                  sw x10, 0(x29)
                  ecall

test_fail:        
                  li x29, 0x8ffffff8
                  li x10, 0x1
                  slli x10, x10, 8
                  addi x10, x10, 0x1
                  sw x10, 0(x29)
                  ecall

mmode_intr_vector_1:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_2:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_3:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_4:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_5:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_6:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_7:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_8:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_9:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_10:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_11:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_12:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_13:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_14:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_15:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_16:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_17:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_18:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_19:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_20:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_21:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_22:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_23:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_24:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_25:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_26:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_27:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_28:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_29:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_30:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

mmode_intr_vector_31:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x6
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x342 # MCAUSE
                  srli x10, x10, 0x1f
                  beqz x10, 1f
                  li x29, 0x8ffffffc
                  li x10, 0x300
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x300
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x304
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x304
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x344
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x344
                  sw x10, 0(x29)
                  j mmode_intr_handler
                  1: la x2, test_done
                  jalr x0, x2, 0

.align           8
mtvec_handler:    
                  .option norvc;
                  j mmode_exception_handler
                  j mmode_intr_vector_1
                  j mmode_intr_vector_2
                  j mmode_intr_vector_3
                  j mmode_intr_vector_4
                  j mmode_intr_vector_5
                  j mmode_intr_vector_6
                  j mmode_intr_vector_7
                  j mmode_intr_vector_8
                  j mmode_intr_vector_9
                  j mmode_intr_vector_10
                  j mmode_intr_vector_11
                  j mmode_intr_vector_12
                  j mmode_intr_vector_13
                  j mmode_intr_vector_14
                  j mmode_intr_vector_15
                  j mmode_intr_vector_16
                  j mmode_intr_vector_17
                  j mmode_intr_vector_18
                  j mmode_intr_vector_19
                  j mmode_intr_vector_20
                  j mmode_intr_vector_21
                  j mmode_intr_vector_22
                  j mmode_intr_vector_23
                  j mmode_intr_vector_24
                  j mmode_intr_vector_25
                  j mmode_intr_vector_26
                  j mmode_intr_vector_27
                  j mmode_intr_vector_28
                  j mmode_intr_vector_29
                  j mmode_intr_vector_30
                  j mmode_intr_vector_31
                  .option rvc;

mmode_exception_handler:
                  addi x12, x12, -4
                  sw  x26, (x12)
                  add x26, x12, zero
                  addi x26, x26, -128
                  sw  x1, 4(x26)
                  sw  x2, 8(x26)
                  sw  x3, 12(x26)
                  sw  x4, 16(x26)
                  sw  x5, 20(x26)
                  sw  x6, 24(x26)
                  sw  x7, 28(x26)
                  sw  x8, 32(x26)
                  sw  x9, 36(x26)
                  sw  x10, 40(x26)
                  sw  x11, 44(x26)
                  sw  x12, 48(x26)
                  sw  x13, 52(x26)
                  sw  x14, 56(x26)
                  sw  x15, 60(x26)
                  sw  x16, 64(x26)
                  sw  x17, 68(x26)
                  sw  x18, 72(x26)
                  sw  x19, 76(x26)
                  sw  x20, 80(x26)
                  sw  x21, 84(x26)
                  sw  x22, 88(x26)
                  sw  x23, 92(x26)
                  sw  x24, 96(x26)
                  sw  x25, 100(x26)
                  sw  x26, 104(x26)
                  sw  x27, 108(x26)
                  sw  x28, 112(x26)
                  sw  x29, 116(x26)
                  sw  x30, 120(x26)
                  sw  x31, 124(x26)
                  add x12, x26, zero
                  li x29, 0x8ffffffc
                  li x10, 0x8
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  csrr x10, 0x341 # MEPC
                  csrr x10, 0x342 # MCAUSE
                  li x29, 0x3 # BREAKPOINT
                  beq x10, x29, ebreak_handler
                  li x29, 0x8 # ECALL_UMODE
                  beq x10, x29, ecall_handler
                  li x29, 0x9 # ECALL_SMODE
                  beq x10, x29, ecall_handler
                  li x29, 0xb # ECALL_MMODE
                  beq x10, x29, ecall_handler
                  li x29, 0x1
                  beq x10, x29, instr_fault_handler
                  li x29, 0x5
                  beq x10, x29, load_fault_handler
                  li x29, 0x7
                  beq x10, x29, store_fault_handler
                  li x29, 0xc
                  beq x10, x29, pt_fault_handler
                  li x29, 0xd
                  beq x10, x29, pt_fault_handler
                  li x29, 0xf
                  beq x10, x29, pt_fault_handler
                  li x29, 0x2 # ILLEGAL_INSTRUCTION
                  beq x10, x29, illegal_instr_handler
                  csrr x29, 0x343 # MTVAL
                  1: la x2, test_done
                  jalr x1, x2, 0

ecall_handler:    
                  li x29, 0x8ffffffc
                  li x10, 0xb00
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb00
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb80
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb80
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb03
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb03
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb83
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb83
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb04
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb04
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb84
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb84
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb05
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb05
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb85
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb85
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb06
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb06
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0xb86
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0xb86
                  sw x10, 0(x29)
                  la x10, _start
                  sw x0, 0(x10)
                  sw x1, 4(x10)
                  sw x2, 8(x10)
                  sw x3, 12(x10)
                  sw x4, 16(x10)
                  sw x5, 20(x10)
                  sw x6, 24(x10)
                  sw x7, 28(x10)
                  sw x8, 32(x10)
                  sw x9, 36(x10)
                  sw x10, 40(x10)
                  sw x11, 44(x10)
                  sw x12, 48(x10)
                  sw x13, 52(x10)
                  sw x14, 56(x10)
                  sw x15, 60(x10)
                  sw x16, 64(x10)
                  sw x17, 68(x10)
                  sw x18, 72(x10)
                  sw x19, 76(x10)
                  sw x20, 80(x10)
                  sw x21, 84(x10)
                  sw x22, 88(x10)
                  sw x23, 92(x10)
                  sw x24, 96(x10)
                  sw x25, 100(x10)
                  sw x26, 104(x10)
                  sw x27, 108(x10)
                  sw x28, 112(x10)
                  sw x29, 116(x10)
                  sw x30, 120(x10)
                  sw x31, 124(x10)
                  csrr  x10, 0x341
                  addi  x10, x10, 4
                  csrw  0x341, x10
                  mret

instr_fault_handler:
                  li x29, 0x8ffffffc
                  li x10, 0x9
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x10, 0
                  mv x17, x10
                  li x7, 0
                  0: mv x10, x17
                  mv x2, x10
                  li x2, 0
                  beq x10, x2, 1f
                  li x2, 1
                  beq x10, x2, 2f
                  li x2, 2
                  beq x10, x2, 3f
                  li x2, 3
                  beq x10, x2, 4f
                  li x2, 4
                  beq x10, x2, 5f
                  li x2, 5
                  beq x10, x2, 6f
                  li x2, 6
                  beq x10, x2, 7f
                  li x2, 7
                  beq x10, x2, 8f
                  li x2, 8
                  beq x10, x2, 9f
                  li x2, 9
                  beq x10, x2, 10f
                  li x2, 10
                  beq x10, x2, 11f
                  li x2, 11
                  beq x10, x2, 12f
                  li x2, 12
                  beq x10, x2, 13f
                  li x2, 13
                  beq x10, x2, 14f
                  li x2, 14
                  beq x10, x2, 15f
                  li x2, 15
                  beq x10, x2, 16f
                  1: csrr x29, 0x3b0
                  csrr x22, 0x3a0
                  j 17f
                  2: csrr x29, 0x3b1
                  csrr x22, 0x3a0
                  j 17f
                  3: csrr x29, 0x3b2
                  csrr x22, 0x3a0
                  j 17f
                  4: csrr x29, 0x3b3
                  csrr x22, 0x3a0
                  j 17f
                  5: csrr x29, 0x3b4
                  csrr x22, 0x3a1
                  j 17f
                  6: csrr x29, 0x3b5
                  csrr x22, 0x3a1
                  j 17f
                  7: csrr x29, 0x3b6
                  csrr x22, 0x3a1
                  j 17f
                  8: csrr x29, 0x3b7
                  csrr x22, 0x3a1
                  j 17f
                  9: csrr x29, 0x3b8
                  csrr x22, 0x3a2
                  j 17f
                  10: csrr x29, 0x3b9
                  csrr x22, 0x3a2
                  j 17f
                  11: csrr x29, 0x3ba
                  csrr x22, 0x3a2
                  j 17f
                  12: csrr x29, 0x3bb
                  csrr x22, 0x3a2
                  j 17f
                  13: csrr x29, 0x3bc
                  csrr x22, 0x3a3
                  j 17f
                  14: csrr x29, 0x3bd
                  csrr x22, 0x3a3
                  j 17f
                  15: csrr x29, 0x3be
                  csrr x22, 0x3a3
                  j 17f
                  16: csrr x29, 0x3bf
                  csrr x22, 0x3a3
                  j 17f
                  17: li x25, 4
                  slli x10, x17, 30
                  srli x10, x10, 30
                  sub x2, x25, x10
                  addi x2, x2, -1
                  slli x2, x2, 3
                  sll x25, x22, x2
                  slli x10, x10, 3
                  add x2, x2, x10
                  srl x25, x25, x2
                  slli x2, x25, 27
                  srli x2, x2, 30
                  beqz x2, 20f
                  li x10, 1
                  beq x2, x10, 21f
                  li x10, 2
                  beq x2, x10, 24f
                  li x10, 3
                  beq x2, x10, 25f
                  la x10, test_done
                  jalr x0, x10, 0
                  18: mv x10, x17
                  mv x7, x29
                  addi x10, x10, 1
                  mv x17, x10
                  li x29, 16
                  ble x29, x10, 19f
                  j 0b
                  19: csrr x10, 0x747
                  andi x10, x10, 2
                  bnez x10, 27f
                  la x10, test_done
                  jalr x0, x10, 0
                  20: j 18b
                  21: mv x10, x17
                  csrr x2, 0x343
                  srli x2, x2, 2
                  bnez x10, 22f
                  bltz x2, 18b
                  j 23f
                  22: bgtu x7, x2, 18b
                  23: bleu x29, x2, 18b
                  j 26f
                  24: csrr x10, 0x343
                  srli x10, x10, 2
                  slli x2, x29, 2
                  srli x2, x2, 2
                  bne x10, x2, 18b
                  j 26f
                  25: csrr x10, 0x343
                  srli x10, x10, 2
                  srli x10, x10, 0
                  slli x10, x10, 0
                  slli x2, x29, 2
                  srli x2, x2, 2
                  srli x2, x2, 0
                  slli x2, x2, 0
                  bne x10, x2, 18b
                  j 26f
                  26: csrr x2, 0x747
                  andi x2, x2, 1
                  bnez x2, 27f
                  andi x2, x25, 128
                  bnez x2, 27f
                  j 29f
                  27: la x10, test_done
                  jalr x0, x10, 0
                  29: ori x25, x25, 4
                  li x2, 30
                  sll x10, x17, x2
                  srl x10, x10, x2
                  slli x2, x10, 3
                  sll x25, x25, x2
                  or x22, x22, x25
                  mv x10, x17
                  srli x10, x10, 2
                  beqz x10, 30f
                  li x2, 1
                  beq x10, x2, 31f
                  li x2, 2
                  beq x10, x2, 32f
                  li x2, 3
                  beq x10, x2, 33f
                  30: csrw 0x3a0, x22
                  j 34f
                  31: csrw 0x3a1, x22
                  j 34f
                  32: csrw 0x3a2, x22
                  j 34f
                  33: csrw 0x3a3, x22
                  34: nop
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret

load_fault_handler:
                  li x29, 0x8ffffffc
                  li x10, 0xb
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x10, 0
                  mv x17, x10
                  li x7, 0
                  0: mv x10, x17
                  mv x2, x10
                  li x2, 0
                  beq x10, x2, 1f
                  li x2, 1
                  beq x10, x2, 2f
                  li x2, 2
                  beq x10, x2, 3f
                  li x2, 3
                  beq x10, x2, 4f
                  li x2, 4
                  beq x10, x2, 5f
                  li x2, 5
                  beq x10, x2, 6f
                  li x2, 6
                  beq x10, x2, 7f
                  li x2, 7
                  beq x10, x2, 8f
                  li x2, 8
                  beq x10, x2, 9f
                  li x2, 9
                  beq x10, x2, 10f
                  li x2, 10
                  beq x10, x2, 11f
                  li x2, 11
                  beq x10, x2, 12f
                  li x2, 12
                  beq x10, x2, 13f
                  li x2, 13
                  beq x10, x2, 14f
                  li x2, 14
                  beq x10, x2, 15f
                  li x2, 15
                  beq x10, x2, 16f
                  1: csrr x29, 0x3b0
                  csrr x22, 0x3a0
                  j 17f
                  2: csrr x29, 0x3b1
                  csrr x22, 0x3a0
                  j 17f
                  3: csrr x29, 0x3b2
                  csrr x22, 0x3a0
                  j 17f
                  4: csrr x29, 0x3b3
                  csrr x22, 0x3a0
                  j 17f
                  5: csrr x29, 0x3b4
                  csrr x22, 0x3a1
                  j 17f
                  6: csrr x29, 0x3b5
                  csrr x22, 0x3a1
                  j 17f
                  7: csrr x29, 0x3b6
                  csrr x22, 0x3a1
                  j 17f
                  8: csrr x29, 0x3b7
                  csrr x22, 0x3a1
                  j 17f
                  9: csrr x29, 0x3b8
                  csrr x22, 0x3a2
                  j 17f
                  10: csrr x29, 0x3b9
                  csrr x22, 0x3a2
                  j 17f
                  11: csrr x29, 0x3ba
                  csrr x22, 0x3a2
                  j 17f
                  12: csrr x29, 0x3bb
                  csrr x22, 0x3a2
                  j 17f
                  13: csrr x29, 0x3bc
                  csrr x22, 0x3a3
                  j 17f
                  14: csrr x29, 0x3bd
                  csrr x22, 0x3a3
                  j 17f
                  15: csrr x29, 0x3be
                  csrr x22, 0x3a3
                  j 17f
                  16: csrr x29, 0x3bf
                  csrr x22, 0x3a3
                  j 17f
                  17: li x25, 4
                  slli x10, x17, 30
                  srli x10, x10, 30
                  sub x2, x25, x10
                  addi x2, x2, -1
                  slli x2, x2, 3
                  sll x25, x22, x2
                  slli x10, x10, 3
                  add x2, x2, x10
                  srl x25, x25, x2
                  slli x2, x25, 27
                  srli x2, x2, 30
                  beqz x2, 20f
                  li x10, 1
                  beq x2, x10, 21f
                  li x10, 2
                  beq x2, x10, 24f
                  li x10, 3
                  beq x2, x10, 25f
                  la x10, test_done
                  jalr x0, x10, 0
                  18: mv x10, x17
                  mv x7, x29
                  addi x10, x10, 1
                  mv x17, x10
                  li x29, 16
                  ble x29, x10, 19f
                  j 0b
                  19: csrr x10, 0x747
                  andi x10, x10, 2
                  bnez x10, 27f
                  la x10, test_done
                  jalr x0, x10, 0
                  20: j 18b
                  21: mv x10, x17
                  csrr x2, 0x343
                  srli x2, x2, 2
                  bnez x10, 22f
                  bltz x2, 18b
                  j 23f
                  22: bgtu x7, x2, 18b
                  23: bleu x29, x2, 18b
                  j 26f
                  24: csrr x10, 0x343
                  srli x10, x10, 2
                  slli x2, x29, 2
                  srli x2, x2, 2
                  bne x10, x2, 18b
                  j 26f
                  25: csrr x10, 0x343
                  srli x10, x10, 2
                  srli x10, x10, 0
                  slli x10, x10, 0
                  slli x2, x29, 2
                  srli x2, x2, 2
                  srli x2, x2, 0
                  slli x2, x2, 0
                  bne x10, x2, 18b
                  j 26f
                  26: csrr x2, 0x747
                  andi x2, x2, 1
                  bnez x2, 27f
                  andi x2, x25, 128
                  bnez x2, 27f
                  j 29f
                  27: csrr x10, 0x341
                  la x2, main
                  bge x10, x2, 40f
                  la x10, test_done
                  jalr x0, x10, 0
                  40: lw x10, 0(x10)
                  li x2, 3
                  and x10, x10, x2
                  beq x10, x2, 28f
                  csrr x10, 0x341
                  addi x10, x10, 2
                  csrw 0x341, x10
                  j 34f
                  28: csrr x10, 0x341
                  addi x10, x10, 4
                  csrw 0x341, x10
                  j 34f
                  29: ori x25, x25, 1
                  li x2, 30
                  sll x10, x17, x2
                  srl x10, x10, x2
                  slli x2, x10, 3
                  sll x25, x25, x2
                  or x22, x22, x25
                  mv x10, x17
                  srli x10, x10, 2
                  beqz x10, 30f
                  li x2, 1
                  beq x10, x2, 31f
                  li x2, 2
                  beq x10, x2, 32f
                  li x2, 3
                  beq x10, x2, 33f
                  30: csrw 0x3a0, x22
                  j 34f
                  31: csrw 0x3a1, x22
                  j 34f
                  32: csrw 0x3a2, x22
                  j 34f
                  33: csrw 0x3a3, x22
                  34: nop
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret

store_fault_handler:
                  li x29, 0x8ffffffc
                  li x10, 0xc
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  li x10, 0
                  mv x17, x10
                  li x7, 0
                  0: mv x10, x17
                  mv x2, x10
                  li x2, 0
                  beq x10, x2, 1f
                  li x2, 1
                  beq x10, x2, 2f
                  li x2, 2
                  beq x10, x2, 3f
                  li x2, 3
                  beq x10, x2, 4f
                  li x2, 4
                  beq x10, x2, 5f
                  li x2, 5
                  beq x10, x2, 6f
                  li x2, 6
                  beq x10, x2, 7f
                  li x2, 7
                  beq x10, x2, 8f
                  li x2, 8
                  beq x10, x2, 9f
                  li x2, 9
                  beq x10, x2, 10f
                  li x2, 10
                  beq x10, x2, 11f
                  li x2, 11
                  beq x10, x2, 12f
                  li x2, 12
                  beq x10, x2, 13f
                  li x2, 13
                  beq x10, x2, 14f
                  li x2, 14
                  beq x10, x2, 15f
                  li x2, 15
                  beq x10, x2, 16f
                  1: csrr x29, 0x3b0
                  csrr x22, 0x3a0
                  j 17f
                  2: csrr x29, 0x3b1
                  csrr x22, 0x3a0
                  j 17f
                  3: csrr x29, 0x3b2
                  csrr x22, 0x3a0
                  j 17f
                  4: csrr x29, 0x3b3
                  csrr x22, 0x3a0
                  j 17f
                  5: csrr x29, 0x3b4
                  csrr x22, 0x3a1
                  j 17f
                  6: csrr x29, 0x3b5
                  csrr x22, 0x3a1
                  j 17f
                  7: csrr x29, 0x3b6
                  csrr x22, 0x3a1
                  j 17f
                  8: csrr x29, 0x3b7
                  csrr x22, 0x3a1
                  j 17f
                  9: csrr x29, 0x3b8
                  csrr x22, 0x3a2
                  j 17f
                  10: csrr x29, 0x3b9
                  csrr x22, 0x3a2
                  j 17f
                  11: csrr x29, 0x3ba
                  csrr x22, 0x3a2
                  j 17f
                  12: csrr x29, 0x3bb
                  csrr x22, 0x3a2
                  j 17f
                  13: csrr x29, 0x3bc
                  csrr x22, 0x3a3
                  j 17f
                  14: csrr x29, 0x3bd
                  csrr x22, 0x3a3
                  j 17f
                  15: csrr x29, 0x3be
                  csrr x22, 0x3a3
                  j 17f
                  16: csrr x29, 0x3bf
                  csrr x22, 0x3a3
                  j 17f
                  17: li x25, 4
                  slli x10, x17, 30
                  srli x10, x10, 30
                  sub x2, x25, x10
                  addi x2, x2, -1
                  slli x2, x2, 3
                  sll x25, x22, x2
                  slli x10, x10, 3
                  add x2, x2, x10
                  srl x25, x25, x2
                  slli x2, x25, 27
                  srli x2, x2, 30
                  beqz x2, 20f
                  li x10, 1
                  beq x2, x10, 21f
                  li x10, 2
                  beq x2, x10, 24f
                  li x10, 3
                  beq x2, x10, 25f
                  la x10, test_done
                  jalr x0, x10, 0
                  18: mv x10, x17
                  mv x7, x29
                  addi x10, x10, 1
                  mv x17, x10
                  li x29, 16
                  ble x29, x10, 19f
                  j 0b
                  19: csrr x10, 0x747
                  andi x10, x10, 2
                  bnez x10, 27f
                  la x10, test_done
                  jalr x0, x10, 0
                  20: j 18b
                  21: mv x10, x17
                  csrr x2, 0x343
                  srli x2, x2, 2
                  bnez x10, 22f
                  bltz x2, 18b
                  j 23f
                  22: bgtu x7, x2, 18b
                  23: bleu x29, x2, 18b
                  j 26f
                  24: csrr x10, 0x343
                  srli x10, x10, 2
                  slli x2, x29, 2
                  srli x2, x2, 2
                  bne x10, x2, 18b
                  j 26f
                  25: csrr x10, 0x343
                  srli x10, x10, 2
                  srli x10, x10, 0
                  slli x10, x10, 0
                  slli x2, x29, 2
                  srli x2, x2, 2
                  srli x2, x2, 0
                  slli x2, x2, 0
                  bne x10, x2, 18b
                  j 26f
                  26: csrr x2, 0x747
                  andi x2, x2, 1
                  bnez x2, 27f
                  andi x2, x25, 128
                  bnez x2, 27f
                  j 29f
                  27: csrr x10, 0x341
                  lw x10, 0(x10)
                  li x2, 3
                  and x10, x10, x2
                  beq x10, x2, 28f
                  csrr x10, 0x341
                  addi x10, x10, 2
                  csrw 0x341, x10
                  j 34f
                  28: csrr x10, 0x341
                  addi x10, x10, 4
                  csrw 0x341, x10
                  j 34f
                  29: ori x25, x25, 3
                  li x2, 30
                  sll x10, x17, x2
                  srl x10, x10, x2
                  slli x2, x10, 3
                  sll x25, x25, x2
                  or x22, x22, x25
                  mv x10, x17
                  srli x10, x10, 2
                  beqz x10, 30f
                  li x2, 1
                  beq x10, x2, 31f
                  li x2, 2
                  beq x10, x2, 32f
                  li x2, 3
                  beq x10, x2, 33f
                  30: csrw 0x3a0, x22
                  j 34f
                  31: csrw 0x3a1, x22
                  j 34f
                  32: csrw 0x3a2, x22
                  j 34f
                  33: csrw 0x3a3, x22
                  34: nop
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret

.align 2
main:             csrrsi       s8, 0x340, 28
                  andi         a7, a4, -1760
                  add          gp, s10, s0
                  c.or         s0, a1
                  c.and        a5, a4
                  c.li         a6, 1
                  srl          a4, s10, t0
                  srai         a4, s6, 20
                  mulhsu       a7, a4, gp
                  csrrw        a0, 0x340, s11
                  c.sub        s1, s0
                  csrrw        a1, 0x340, a4
                  csrrs        a5, 0x340, zero
                  rem          s4, s5, t2
                  xor          a1, s8, t2
                  sll          t1, ra, a7
                  rem          ra, s4, t0
                  sltiu        gp, s9, 923
                  c.slli       s9, 27
                  or           s1, s8, t3
                  c.andi       a5, 5
                  slti         t2, a2, -399
                  csrrw        t3, 0x340, t3
                  mulhu        a1, t3, s10
                  c.xor        a1, s0
                  sub          a3, s4, t4
                  auipc        s7, 343442
                  sub          a0, a2, gp
                  xor          s5, t2, gp
                  and          t6, t3, s3
                  c.srai       a0, 19
                  csrrci       a7, 0x340, 0
                  csrrs        t5, 0x340, a6
                  rem          a3, s10, s5
                  xor          t2, s8, s5
                  c.add        a6, t1
                  csrrsi       s7, 0x340, 4
                  csrrs        a0, 0x340, zero
                  c.andi       a3, -1
                  c.srai       a4, 8
                  c.mv         a3, sp
                  sltu         t0, s4, t2
                  c.slli       gp, 27
                  slt          t6, a3, s4
                  csrrw        s2, 0x340, t0
                  sltu         s3, s6, t5
                  csrrs        s8, 0x340, a1
                  c.mv         a0, t0
                  c.slli       s8, 6
                  div          s11, t4, t1
                  c.andi       a3, 24
                  c.nop
                  c.xor        s0, a4
                  auipc        ra, 665002
                  c.addi       s0, -1
                  c.add        ra, s7
                  xor          s5, s0, s0
                  sltiu        s3, t2, -101
                  xor          zero, s7, a7
                  c.and        a0, s0
                  c.add        a1, s2
                  c.li         s3, -1
                  slti         s8, t1, -827
                  and          gp, s9, s9
                  c.and        a3, a5
                  xor          a4, s7, t3
                  c.li         t6, 4
                  c.slli       a4, 4
                  srli         gp, t1, 4
                  slt          s5, s8, s5
                  sll          t5, s6, t6
                  c.srli       a5, 4
                  sltu         t0, gp, s11
                  csrrw        gp, 0x340, s3
                  and          s7, t1, a4
                  ori          a6, s1, -723
                  csrrc        s4, 0x340, t2
                  c.srai       s0, 10
                  c.li         a0, 11
                  sltu         t5, t3, tp
                  ori          a5, s8, 1563
                  csrrs        s3, 0x340, s4
                  sub          a7, a7, a0
                  c.mv         s7, a0
                  add          s6, s7, s0
                  slli         s8, a7, 14
                  xori         s7, a1, -1616
                  div          a3, a0, s9
                  ori          t2, a1, 555
                  c.srai       a0, 22
                  csrrwi       t1, 0x340, 27
                  slli         s0, s3, 11
                  csrrw        t1, 0x340, a2
                  srai         s7, t1, 11
                  c.srai       s1, 14
                  divu         t6, s8, t4
                  sub          a4, zero, s11
                  or           s9, zero, a2
                  csrrc        s8, 0x340, zero
                  c.sub        a3, a2
                  nop
                  or           s11, a5, s3
                  slli         a3, s6, 30
                  c.or         a5, s1
                  xori         t2, a0, -1729
                  c.srai       a5, 7
                  auipc        a5, 1034172
                  lui          a0, 440830
                  srli         a1, zero, 6
                  c.or         s0, a2
                  csrrc        t3, 0x340, zero
                  slt          a3, t6, a4
                  c.or         a1, a1
                  c.li         s2, 19
                  slt          t1, zero, s2
                  add          a1, s3, t6
                  srl          a4, a3, a4
                  csrrw        s1, 0x340, s10
                  mul          s5, s8, t0
                  c.srai       a0, 3
                  sra          s11, s11, a1
                  c.srli       s1, 8
                  c.add        s9, t5
                  mulhsu       t3, a3, s6
                  csrrc        s0, 0x340, zero
                  and          s2, s2, t1
                  and          t5, s2, gp
                  sub          s5, s7, s10
                  slt          s11, s8, a4
                  c.and        a3, s1
                  c.andi       a1, 11
                  and          s9, s10, s3
                  slt          s1, t1, s2
                  srai         s3, a3, 22
                  c.add        tp, a6
                  sltu         s6, s4, t2
                  c.lui        s6, 2
                  slt          t2, s0, t3
                  sub          a4, s11, sp
                  csrrwi       tp, 0x340, 13
                  c.li         s1, 25
                  c.slli       s6, 27
                  and          s6, s0, zero
                  csrrc        t3, 0x340, zero
                  lui          t5, 303372
                  div          s1, a4, a3
                  mul          t0, sp, s6
                  c.sub        a0, a3
                  csrrci       zero, 0x340, 0
                  sltu         zero, a2, ra
                  c.and        a0, a0
                  mulhsu       a3, gp, s4
                  add          a3, t0, a6
                  c.addi       s8, -1
                  csrrsi       a0, 0x340, 0
                  srai         a1, gp, 29
                  sub          a5, sp, s0
                  add          ra, a6, tp
                  csrrsi       s6, 0x340, 23
                  srl          s9, a1, s2
                  c.mv         a5, a0
                  c.or         a4, a1
                  xor          s6, t1, s2
                  csrrc        s1, 0x340, s4
                  c.or         a4, s1
                  ori          t4, a0, 829
                  ori          tp, t1, 2016
                  c.nop
                  c.srli       a3, 1
                  srl          a5, s2, tp
                  slli         a3, t5, 16
                  mulh         s1, gp, a6
                  mulhu        t3, a0, t3
                  c.and        s0, a0
                  csrrwi       s7, 0x340, 29
                  addi         ra, a0, -1069
                  div          s2, s7, tp
                  sub          s9, tp, a4
                  srli         t0, s6, 0
                  andi         s2, t3, -897
                  csrrs        t3, 0x340, zero
                  mulhsu       a1, a5, s0
                  c.nop
                  mul          a0, s3, s3
                  addi         a0, s2, 2031
                  ori          s7, t6, -545
                  mulhu        s5, s9, t1
                  add          s4, s9, a2
                  sra          s6, a6, gp
                  c.srli       s1, 20
                  slli         a7, s8, 12
                  mulhu        a0, s4, gp
                  c.andi       a3, 26
                  andi         s1, s7, 467
                  csrrc        a6, 0x340, t0
                  csrrci       s2, 0x340, 0
                  c.addi       ra, 13
                  c.slli       a5, 23
                  csrrw        s8, 0x340, s1
                  c.or         s0, a1
                  rem          s4, s2, s3
                  mulh         t2, a6, a4
                  mulhu        tp, a6, s2
                  add          tp, t0, t2
                  c.addi       t1, 15
                  mulh         s9, s11, s2
                  slli         t4, s2, 15
                  srai         tp, a0, 17
                  andi         a6, a2, 1178
                  c.and        s0, a1
                  auipc        a1, 759617
                  rem          s5, s4, a5
                  c.srai       a5, 10
                  csrrwi       t3, 0x340, 14
                  rem          t1, t4, s11
                  mulh         a6, a0, s6
                  c.addi       s6, 31
                  add          ra, t0, sp
                  slt          t2, s6, s1
                  or           tp, a5, a6
                  srai         t5, gp, 18
                  csrrwi       a3, 0x340, 3
                  slti         t1, t1, 227
                  andi         s0, s10, 1110
                  c.mv         s3, s4
                  xori         t2, s6, 312
                  mulhsu       s2, s4, a0
                  srli         t5, s6, 24
                  sltu         a6, s10, a1
                  c.srli       a0, 20
                  c.srli       a0, 14
                  c.xor        a5, a1
                  slli         zero, t2, 0
                  csrrs        a3, 0x340, a0
                  csrrsi       gp, 0x340, 0
                  slli         a0, zero, 22
                  c.xor        a0, a5
                  c.srai       a4, 30
                  c.lui        t0, 18
                  mulhsu       s4, ra, s5
                  c.or         a4, a1
                  mulhu        a4, s6, t1
                  remu         s5, t3, a5
                  slti         s5, a1, -874
                  c.srai       a3, 12
                  srli         s7, gp, 0
                  c.xor        a5, a3
                  c.or         a3, a0
                  xor          s2, a2, t1
                  divu         s7, gp, gp
                  csrrwi       s1, 0x340, 27
                  xor          a0, a2, a5
                  srl          s0, a7, a4
                  c.li         a6, -1
                  csrrci       ra, 0x340, 1
                  add          tp, a5, s7
                  lui          ra, 781337
                  mulhsu       a1, t1, a7
                  c.or         a4, s0
                  addi         t3, s11, -937
                  sra          s0, s7, t3
                  mul          a5, t2, s9
                  add          s5, t3, t5
                  mulhu        t4, t4, s9
                  xor          ra, s6, s11
                  remu         t6, t3, s3
                  c.or         a3, a0
                  andi         s5, s6, -51
                  divu         s3, t4, t3
                  auipc        s4, 733291
                  slli         a0, s11, 0
                  sub          s11, s11, t5
                  srli         t4, a7, 25
                  rem          t5, t5, ra
                  auipc        s2, 891507
                  c.nop
                  nop
                  c.add        t1, a5
                  c.addi       s6, -1
                  c.or         a1, a0
                  csrrwi       a1, 0x340, 24
                  addi         gp, s9, -968
                  mulhu        s3, sp, a1
                  xori         ra, t1, 1257
                  csrrw        a0, 0x340, s2
                  c.lui        ra, 10
                  c.and        a0, a0
                  andi         s11, a4, 1145
                  xor          s2, s5, t0
                  c.or         a5, a5
                  csrrw        a0, 0x340, a4
                  c.and        s0, a3
                  mulh         t2, a2, s3
                  slti         s5, t2, 1000
                  divu         s9, s10, sp
                  sll          a6, a3, zero
                  srai         s8, a5, 22
                  mul          a1, gp, s1
                  div          t3, a7, zero
                  xor          a5, sp, s11
                  remu         s8, t4, s3
                  remu         t3, a6, tp
                  csrrw        s0, 0x340, ra
                  c.srai       a5, 2
                  c.add        t2, t1
                  srl          a4, s5, a3
                  c.andi       s1, -1
                  sll          s4, gp, s2
                  c.sub        s1, s1
                  c.xor        a1, a5
                  xor          s9, s2, sp
                  rem          s3, a2, gp
                  c.srai       a1, 22
                  slt          a4, t6, s11
                  sll          a1, gp, s2
                  c.xor        s1, a3
                  c.nop
                  c.srai       a5, 18
                  c.or         a1, a1
                  c.mv         t6, s11
                  div          s7, s4, s2
                  csrrwi       s1, 0x340, 7
                  srli         t4, ra, 30
                  sltiu        zero, t6, 158
                  slt          t0, a1, s2
                  divu         s5, ra, s0
                  sub          a5, s4, t3
                  addi         s11, a1, -1592
                  c.nop
                  xori         gp, s11, 1613
                  c.nop
                  srai         s7, s11, 0
                  c.andi       s0, 1
                  sub          a0, t2, t1
                  c.slli       tp, 18
                  auipc        gp, 644898
                  xori         s7, s5, -1183
                  csrrwi       zero, 0x340, 25
                  c.lui        s6, 15
                  srl          t4, a2, tp
                  divu         tp, a2, t1
                  addi         t4, a5, -2030
                  csrrc        s3, 0x340, s4
                  c.add        a1, t4
                  or           s6, s6, t5
                  c.li         t4, -1
                  auipc        a6, 379711
                  and          a1, s11, a5
                  mulhsu       a5, t5, t0
                  mul          t3, s8, a5
                  slli         t3, s0, 1
                  c.srai       a0, 3
                  csrrci       s11, 0x340, 0
                  c.and        a0, a2
                  sll          a6, t1, a6
                  srli         zero, s9, 14
                  sub          gp, zero, s8
                  andi         a3, a5, 1630
                  mulhu        t0, s0, ra
                  mulh         gp, a6, ra
                  rem          s1, gp, sp
                  csrrw        s6, 0x340, a4
                  slti         tp, s9, 1787
                  slt          s6, s10, s3
                  xor          a0, ra, s7
                  rem          tp, t4, s6
                  sltu         s6, a6, a6
                  c.or         a3, a5
                  csrrci       zero, 0x340, 4
                  c.add        s3, t0
                  csrrwi       s0, 0x340, 6
                  csrrc        s11, 0x340, zero
                  srai         t0, s11, 9
                  csrrs        ra, 0x340, zero
                  csrrwi       t1, 0x340, 8
                  mul          t3, t1, t5
                  srl          tp, t3, t1
                  csrrci       zero, 0x340, 0
                  slli         s8, s9, 11
                  c.sub        s0, a1
                  or           s3, sp, s10
                  c.or         a4, a3
                  c.add        ra, s8
                  nop
                  and          t1, a5, a2
                  add          t1, a0, a4
                  csrrw        a5, 0x340, s4
                  csrrwi       t3, 0x340, 23
                  mulhsu       t6, s1, s4
                  c.andi       s0, -1
                  slli         s3, s0, 19
                  mulh         s0, s11, s6
                  c.srai       a4, 26
                  c.xor        a5, a0
                  c.srai       a5, 13
                  c.srli       a3, 1
                  auipc        t6, 527120
                  lui          t0, 433705
                  c.slli       a7, 24
                  c.or         a5, a3
                  csrrsi       s5, 0x340, 10
                  c.or         s0, a0
                  sub          s11, s2, s6
                  c.li         s11, 19
                  mul          a7, sp, a3
                  sltiu        t4, s10, -936
                  and          s7, a3, s3
                  csrrw        s11, 0x340, zero
                  c.srai       a0, 1
                  and          s1, s1, s5
                  c.srai       a0, 4
                  mul          s4, t4, s8
                  add          a0, t6, t6
                  lui          t6, 463996
                  slli         s5, a4, 22
                  c.slli       s2, 29
                  sltiu        t6, s9, -1389
                  nop
                  c.andi       s1, 2
                  or           t3, gp, s7
                  mulhsu       s8, s3, a0
                  c.li         s3, -1
                  addi         t1, s7, 1884
                  c.li         a1, 11
                  rem          t0, s11, s5
                  addi         t2, tp, -664
                  c.sub        a4, a1
                  csrrwi       a4, 0x340, 17
                  c.sub        a4, a5
                  c.or         a3, a0
                  xor          s11, a5, t1
                  mulhsu       s0, s0, t6
                  c.lui        a7, 16
                  c.andi       s1, -1
                  add          s6, t1, t0
                  csrrs        s1, 0x340, zero
                  c.slli       a3, 14
                  csrrwi       a7, 0x340, 22
                  sltiu        s6, a1, 709
                  c.lui        t1, 13
                  mulhu        ra, a1, t0
                  mulhsu       s5, s0, gp
                  slli         s1, t3, 15
                  nop
                  andi         s2, ra, -2016
                  mulhsu       zero, s7, s2
                  csrrwi       t0, 0x340, 9
                  rem          a7, s2, sp
                  remu         s3, t2, gp
                  slli         t3, s4, 11
                  xori         s6, s6, -805
                  div          s6, t4, s5
                  slt          t3, a7, a0
                  csrrc        a6, 0x340, zero
                  mulhu        a1, s11, s6
                  lui          a1, 17287
                  csrrs        gp, 0x340, a2
                  add          s1, a5, ra
                  c.addi       a3, 3
                  mul          s0, a1, t6
                  c.add        s8, t6
                  sra          s5, s3, tp
                  mulhu        s7, a1, t5
                  srai         s5, s2, 28
                  sltiu        s7, zero, -1427
                  c.andi       a5, -1
                  c.mv         t0, s4
                  add          s2, t2, t5
                  xori         a7, gp, -1611
                  csrrc        t6, 0x340, s4
                  or           t5, a2, s9
                  c.mv         s7, s4
                  c.mv         s7, t5
                  csrrci       s6, 0x340, 19
                  c.or         a5, s1
                  c.addi       s3, -1
                  csrrsi       tp, 0x340, 12
                  srai         zero, a7, 24
                  addi         t1, t0, -1463
                  c.or         a4, a1
                  c.andi       a5, -1
                  c.li         t6, -1
                  divu         t4, s11, s4
                  sltiu        t2, a6, 1663
                  sltu         t4, ra, a7
                  addi         a6, s5, 1445
                  csrrw        a3, 0x340, s7
                  srl          zero, a2, a4
                  xor          t4, zero, a4
                  c.sub        a0, a0
                  nop
                  add          a1, ra, t6
                  srai         s9, sp, 5
                  c.add        a0, s8
                  c.add        a5, gp
                  slt          s2, tp, gp
                  c.slli       s11, 18
                  divu         s1, s6, sp
                  csrrc        s5, 0x340, zero
                  mulhu        t5, s7, a1
                  csrrw        a0, 0x340, a3
                  or           a4, s10, s6
                  c.add        a6, ra
                  c.or         a5, a4
                  slt          s0, s9, a2
                  xori         s2, tp, 1554
                  c.or         a5, s1
                  c.li         t6, -1
                  sltiu        a6, s6, -235
                  csrrs        s4, 0x340, zero
                  add          s11, s2, s5
                  csrrwi       s5, 0x340, 29
                  csrrc        s11, 0x340, zero
                  mulhsu       s2, t3, a5
                  rem          t3, s11, a7
                  xori         s7, a4, -1111
                  srai         s3, t2, 8
                  c.nop
                  sltu         s8, a3, tp
                  and          t1, s7, t1
                  csrrsi       s8, 0x340, 6
                  addi         t4, t3, 868
                  c.mv         s11, ra
                  slt          a3, ra, s6
                  csrrs        s4, 0x340, zero
                  andi         s1, a3, 131
                  slti         s4, t2, 1692
                  auipc        ra, 199766
                  mulh         s11, zero, a1
                  srai         t4, a4, 17
                  csrrs        t5, 0x340, zero
                  csrrc        s0, 0x340, a4
                  c.xor        a5, a0
                  slli         s9, s11, 5
                  mulh         ra, s8, a4
                  c.srli       a5, 11
                  div          s2, s10, a3
                  c.li         a4, -1
                  c.or         a4, a2
                  addi         a5, s7, -1244
                  c.or         s0, s1
                  slti         s0, s6, -2035
                  mulhu        s7, t6, a3
                  sub          zero, ra, t4
                  srai         s0, s7, 19
                  ori          s11, sp, 1548
                  and          a4, s2, a1
                  ori          t4, s10, 2033
                  c.nop
                  c.srli       a0, 31
                  srai         tp, s1, 15
                  sltiu        zero, s2, 1327
                  andi         a4, t0, 1884
                  csrrw        s5, 0x340, s6
                  sra          t2, t2, t4
                  c.sub        a0, a1
                  sra          s9, t4, s4
                  c.li         a4, 29
                  sltiu        zero, sp, 1335
                  c.lui        s1, 21
                  sltiu        tp, s11, -1025
                  csrrci       t2, 0x340, 0
                  c.srli       s1, 29
                  ori          zero, s0, -1035
                  sll          a7, s2, a1
                  c.addi       t4, 16
                  c.add        t4, s4
                  remu         s4, s2, t3
                  mulhu        a7, t3, s1
                  mulh         s9, s8, s10
                  c.slli       a1, 5
                  c.add        s11, s7
                  and          s4, s10, s7
                  c.mv         s6, t3
                  c.srai       a1, 29
                  c.slli       s11, 28
                  xor          t0, a4, s10
                  sub          tp, t0, zero
                  slti         s6, ra, 281
                  srai         gp, a0, 3
                  c.xor        a4, s0
                  csrrs        s1, 0x340, zero
                  c.mv         t4, s9
                  c.addi       s1, -1
                  xor          a5, s8, a4
                  slt          a3, a3, tp
                  xori         s9, s5, 562
                  csrrci       t2, 0x340, 16
                  slt          t5, a3, s5
                  mulhsu       s9, s9, s10
                  or           a0, a0, s2
                  csrrs        a4, 0x340, zero
                  slt          t5, s3, s11
                  csrrs        t1, 0x340, zero
                  mulhsu       a6, a1, a0
                  add          s6, s11, a3
                  srl          s9, a1, t4
                  mulhu        a0, s9, s9
                  srli         zero, a6, 19
                  mulhsu       t6, a0, s2
                  srli         s11, s10, 31
                  xor          a1, s10, ra
                  csrrci       s6, 0x340, 0
                  c.li         t1, -1
                  sltu         a6, s5, s7
                  and          a4, s5, s9
                  and          t5, t3, a2
                  add          t5, zero, a2
                  sltu         s8, a3, a3
                  div          s1, s9, s7
                  slti         t6, a5, -1892
                  c.addi       s0, -1
                  rem          tp, t3, t5
                  c.srli       a4, 19
                  c.and        a3, a3
                  csrrci       s3, 0x340, 28
                  or           a5, a6, t0
                  c.srli       a0, 24
                  and          t1, s3, zero
                  xori         s5, s6, 1660
                  sll          a6, a4, s2
                  csrrc        s3, 0x340, gp
                  mulhu        a3, s2, t5
                  csrrci       s7, 0x340, 0
                  csrrci       a6, 0x340, 0
                  c.srli       a3, 3
                  c.srai       a1, 17
                  c.andi       a4, 10
                  srli         s3, t4, 29
                  mul          s7, s9, a5
                  csrrsi       t2, 0x340, 30
                  mulhu        gp, ra, t6
                  slli         tp, s1, 0
                  c.or         a4, a2
                  c.lui        s5, 13
                  c.mv         a4, s11
                  srl          a6, tp, sp
                  slt          ra, s0, sp
                  slt          t2, s9, t0
                  xori         tp, t3, 359
                  remu         s11, t0, a4
                  xor          a6, s9, t0
                  c.and        a4, a4
                  c.lui        tp, 28
                  c.srai       s1, 21
                  c.li         t2, -1
                  or           a0, s9, s2
                  c.andi       a4, 27
                  sll          t5, zero, s8
                  c.li         s5, 18
                  remu         s6, t6, t1
                  csrrci       a3, 0x340, 4
                  srai         s6, t6, 12
                  c.mv         s6, a7
                  lui          ra, 641356
                  mulh         s4, zero, s3
                  xor          s6, s8, a5
                  c.add        ra, s8
                  rem          a3, s3, t0
                  xori         t5, a3, 727
                  or           s9, t5, s2
                  slti         t4, a3, -413
                  csrrs        a0, 0x340, zero
                  c.add        t2, s3
                  sltu         a0, tp, t5
                  c.sub        a4, a5
                  srl          tp, ra, s1
                  remu         t0, sp, t3
                  add          a4, a6, sp
                  remu         a1, gp, a6
                  c.andi       s1, -1
                  div          s8, a3, s5
                  c.sub        s0, a1
                  addi         a4, s6, -1229
                  mul          t2, t6, a7
                  slli         t4, a4, 2
                  c.slli       s11, 3
                  csrrsi       t6, 0x340, 24
                  srl          s2, a1, a0
                  c.or         a4, a3
                  or           a7, s1, sp
                  slli         s7, tp, 5
                  c.mv         t6, t0
                  c.lui        t3, 1
                  sll          s7, tp, s4
                  divu         a1, a3, t0
                  c.nop
                  or           t0, t5, a5
                  sltu         t2, tp, s3
                  addi         t5, s4, 118
                  div          s7, s3, t0
                  slt          zero, s0, gp
                  slli         zero, s11, 21
                  addi         t4, t5, 172
                  sub          t0, s4, a7
                  c.and        a3, a2
                  remu         s2, a7, t0
                  sltiu        t5, a4, -367
                  mulhsu       s4, s8, t5
                  csrrsi       a4, 0x340, 18
                  sltiu        a1, t2, 579
                  rem          a4, s7, t1
                  srli         t5, s8, 15
                  xori         t5, s2, 1997
                  xori         a0, s5, -546
                  sltiu        tp, t3, -1358
                  sub          s1, a7, s6
                  srl          s0, sp, s6
                  c.nop
                  c.addi       s8, 10
                  srai         s7, s11, 28
                  csrrs        s8, 0x340, zero
                  c.andi       s1, 18
                  csrrci       s2, 0x340, 10
                  andi         a3, t1, -264
                  ori          zero, s10, 432
                  c.srai       a0, 27
                  nop
                  c.slli       a4, 2
                  c.li         a3, -1
                  csrrs        s8, 0x340, zero
                  and          a3, a3, a2
                  c.add        t2, s3
                  or           s3, a2, a5
                  c.and        a5, a0
                  ori          t1, s8, 865
                  c.lui        a4, 30
                  or           t0, a4, s8
                  div          a5, s10, ra
                  c.slli       s4, 3
                  c.add        a4, s10
                  c.srli       a3, 16
                  ori          t3, gp, -1188
                  csrrwi       a3, 0x340, 25
                  auipc        s3, 13381
                  mulh         s2, s4, s8
                  c.sub        a0, s1
                  slli         zero, s3, 22
                  addi         t4, gp, 1547
                  c.xor        a1, a0
                  mulhsu       t6, s4, a5
                  and          a0, s7, a5
                  c.mv         a4, t0
                  sltiu        t6, gp, 1809
                  c.li         t1, 1
                  srai         t2, s3, 4
                  nop
                  c.li         t1, -1
                  c.nop
                  c.xor        a1, s1
                  xori         a3, zero, 365
                  slti         a6, s10, 1394
                  c.lui        t6, 20
                  srai         s2, s10, 25
                  or           t1, t1, s8
                  c.srli       a4, 10
                  sll          ra, s5, a3
                  csrrc        s8, 0x340, a1
                  c.mv         s11, s6
                  csrrs        t2, 0x340, zero
                  srl          s2, t3, t4
                  csrrsi       s1, 0x340, 0
                  c.lui        a4, 16
                  mulh         gp, ra, a1
                  sra          ra, s0, a7
                  srl          s6, t6, tp
                  srl          t0, t5, s0
                  c.addi       t3, 19
                  slti         t2, s1, 153
                  c.xor        a1, a5
                  srl          s8, t4, a6
                  slti         t1, s6, 1869
                  sll          gp, ra, s0
                  csrrci       s0, 0x340, 0
                  mulh         t1, tp, t0
                  c.or         s0, s0
                  c.srai       s1, 29
                  c.srli       a0, 19
                  c.andi       a5, -1
                  slt          t6, s11, a2
                  csrrw        t4, 0x340, a6
                  xor          s9, s7, a2
                  c.addi       t4, 4
                  srai         t6, s9, 16
                  lui          s1, 1030174
                  mulh         s6, zero, s3
                  csrrsi       s4, 0x340, 19
                  or           a6, t2, a6
                  slt          s7, tp, t4
                  sra          zero, gp, s10
                  c.sub        a1, a4
                  and          s5, t0, s4
                  csrrsi       a5, 0x340, 31
                  and          a4, s3, tp
                  csrrsi       a3, 0x340, 0
                  nop
                  or           ra, a3, s1
                  c.addi       s4, 22
                  sra          s11, t0, t3
                  sll          zero, a4, ra
                  csrrsi       a0, 0x340, 27
                  sub          a0, t0, t0
                  rem          ra, t5, s8
                  add          t0, s3, s8
                  sltu         s0, ra, s9
                  csrrci       s4, 0x340, 5
                  c.add        s2, t4
                  c.slli       s0, 3
                  mulhsu       s4, s8, a7
                  c.or         a3, a1
                  xori         a1, a4, -1606
                  csrrsi       t6, 0x340, 0
                  mulhsu       s8, s7, t3
                  csrrwi       t5, 0x340, 1
                  add          t5, ra, a6
                  c.addi       t4, 8
                  div          s8, s5, s9
                  xor          a0, s5, s10
                  div          s9, a1, s8
                  c.andi       a1, 26
                  c.addi       s4, 26
                  slli         a3, a7, 9
                  srl          tp, a2, s8
                  c.or         a1, a4
                  c.andi       a0, 10
                  c.addi       gp, 3
                  c.xor        a5, s1
                  csrrs        a5, 0x340, a2
                  remu         a1, s4, ra
                  c.addi       a3, 22
                  mulhsu       a0, s10, t0
                  remu         a0, t4, t0
                  csrrs        s5, 0x340, zero
                  or           s11, s3, s7
                  c.mv         a7, s3
                  div          a6, tp, s9
                  slti         t5, s8, -1534
                  c.lui        a1, 26
                  c.nop
                  slli         s0, a6, 22
                  c.andi       a3, 14
                  slli         s7, s8, 17
                  csrrc        t1, 0x340, t0
                  lui          gp, 709571
                  and          a0, a4, a2
                  c.slli       s5, 25
                  c.sub        a3, a3
                  srli         t1, s11, 18
                  csrrsi       a4, 0x340, 25
                  sub          t4, sp, t3
                  slli         s9, s3, 4
                  csrrsi       s6, 0x340, 0
                  mul          s11, a2, s10
                  c.nop
                  c.mv         t0, t5
                  srai         t5, s7, 21
                  ori          tp, t5, 989
                  c.sub        a4, a2
                  csrrc        a5, 0x340, zero
                  ori          s11, s0, -1772
                  div          s7, s9, a4
                  xor          a5, s4, s10
                  c.addi       a0, 18
                  csrrwi       s8, 0x340, 15
                  c.or         a1, s0
                  remu         zero, a7, t2
                  sub          t0, a2, a2
                  or           tp, t0, s2
                  mulhsu       t5, zero, sp
                  and          gp, a7, s11
                  srl          s2, s11, a2
                  auipc        s1, 249990
                  slti         s2, s11, 640
                  c.and        s1, s0
                  c.nop
                  c.andi       a3, 5
                  c.andi       a4, 0
                  ori          a7, s7, -892
                  slti         t4, t5, -1032
                  slli         a4, s10, 24
                  c.nop
                  c.and        a4, a2
                  or           s4, s11, s8
                  c.lui        a7, 26
                  c.andi       a5, 15
                  csrrc        s5, 0x340, s0
                  add          a5, gp, s10
                  lui          a1, 660461
                  slli         gp, s2, 12
                  divu         s5, t1, t4
                  or           s8, s5, t0
                  ori          s4, t6, -1616
                  c.add        t0, t4
                  lui          s5, 328220
                  c.nop
                  c.andi       a5, 7
                  sub          a0, s10, a2
                  c.xor        s1, s0
                  andi         gp, tp, -1197
                  auipc        s0, 1040432
                  nop
                  c.sub        a4, a1
                  slli         zero, s5, 8
                  c.li         t0, -1
                  srai         s5, s2, 15
                  div          ra, s4, s7
                  slti         a6, ra, 1567
                  slli         t0, s7, 21
                  lui          t5, 347599
                  xor          zero, a0, t6
                  csrrwi       s5, 0x340, 13
                  slli         s7, t3, 3
                  sltu         t5, a3, a2
                  c.sub        s0, a1
                  c.add        a3, s3
                  c.srai       s0, 29
                  xor          zero, t0, s7
                  slti         s1, s1, 263
                  slli         t2, s10, 7
                  andi         s0, s9, 1641
                  csrrwi       s3, 0x340, 17
                  c.srli       s1, 8
                  c.nop
                  c.add        s7, t0
                  mulhu        t1, s3, s5
                  c.or         s1, s1
                  c.add        t0, t1
                  srli         a3, zero, 24
                  remu         a3, t6, a2
                  sra          a7, s8, s4
                  slti         s2, s1, 1715
                  sub          s1, a4, zero
                  csrrs        a1, 0x340, t3
                  c.nop
                  c.and        a4, a2
                  sltiu        gp, s7, 575
                  srl          t2, s8, a7
                  andi         s4, s7, -521
                  slli         s0, tp, 31
                  lui          a1, 380990
                  ori          a6, a6, 728
                  andi         tp, s11, -816
                  remu         s7, s7, ra
                  slt          s6, s2, a7
                  or           s5, s1, zero
                  c.and        a4, a4
                  c.or         a1, s1
                  ori          ra, s11, -614
                  c.lui        a4, 21
                  mulhsu       t1, a1, s0
                  ori          t4, t1, 1209
                  c.srai       a3, 28
                  c.nop
                  auipc        s4, 1037634
                  c.xor        a5, s0
                  csrrc        t6, 0x340, tp
                  and          s1, s0, ra
                  c.srli       s0, 15
                  c.andi       a3, -1
                  c.addi       s1, 8
                  and          a6, a0, a7
                  ori          s0, a7, 1679
                  srl          t2, sp, t5
                  and          s6, t5, a1
                  sra          t3, s6, a3
                  xor          t4, a6, t6
                  add          s7, s9, t6
                  csrrs        a6, 0x340, t3
                  slli         t4, t4, 2
                  csrrc        t4, 0x340, tp
                  sltu         s5, s1, s1
                  or           a7, a4, a0
                  c.li         t3, -1
                  slli         gp, t1, 29
                  csrrsi       t5, 0x340, 0
                  andi         a0, s6, -824
                  slt          s6, a1, s7
                  c.slli       t1, 24
                  c.sub        a1, a1
                  rem          s0, a5, t2
                  sltu         s1, s4, t0
                  rem          a4, s8, t0
                  sltiu        a3, s1, -1413
                  sub          t1, s6, s6
                  sub          gp, s11, t1
                  srli         s11, s5, 18
                  c.addi       s3, -1
                  c.sub        a1, a1
                  mulhu        s6, s6, a3
                  c.mv         s0, s1
                  c.mv         t4, t5
                  c.addi       s9, 16
                  div          a7, s4, ra
                  andi         t0, gp, 212
                  c.mv         a1, ra
                  csrrwi       a1, 0x340, 31
                  csrrc        s3, 0x340, zero
                  and          t1, s1, s1
                  addi         s8, gp, 1135
                  c.nop
                  slli         s8, a6, 25
                  auipc        s0, 535470
                  mulhu        t0, s8, s1
                  c.xor        a3, a5
                  c.srli       a5, 11
                  xori         s9, zero, 904
                  add          gp, s10, s6
                  csrrci       t3, 0x340, 13
                  csrrci       s4, 0x340, 13
                  add          t3, t6, tp
                  remu         s5, zero, s10
                  c.nop
                  sub          s6, t3, t0
                  addi         s7, t0, 1402
                  c.slli       a1, 3
                  and          s2, sp, s4
                  c.and        s0, a0
                  srl          gp, s8, t3
                  add          a7, tp, a4
                  auipc        t3, 135686
                  add          t6, s0, t3
                  csrrci       s5, 0x340, 0
                  mulhsu       a6, s9, s2
                  div          a0, a7, t6
                  remu         t6, a2, s4
                  csrrw        s6, 0x340, s1
                  mulh         a7, s1, t2
                  csrrc        zero, 0x340, s7
                  andi         s1, ra, -2028
                  c.srli       a0, 8
                  srli         t0, a5, 4
                  addi         a5, s5, 1374
                  ori          s1, t3, 1972
                  c.slli       gp, 3
                  c.srai       a1, 25
                  csrrc        s11, 0x340, zero
                  srli         t6, t4, 17
                  c.xor        s0, a5
                  srai         t2, a4, 8
                  sub          s6, tp, s10
                  mulhu        s4, s4, a0
                  divu         t6, t2, a1
                  c.addi       t0, 7
                  sra          s2, a7, gp
                  c.nop
                  xori         a7, s0, -922
                  remu         s7, t0, a7
                  c.nop
                  c.add        ra, a7
                  c.or         a3, s1
                  c.add        t1, t2
                  c.srai       a0, 13
                  or           t5, s9, t1
                  c.xor        s1, s0
                  nop
                  c.srai       a4, 17
                  c.srai       s1, 25
                  c.xor        a0, a3
                  csrrs        a1, 0x340, zero
                  csrrw        s9, 0x340, t2
                  c.xor        a4, a2
                  divu         s9, t1, a3
                  sra          t4, s10, s5
                  slti         a3, s2, -96
                  mulhsu       a1, s5, t3
                  sltiu        s6, t5, 552
                  c.add        s4, t2
                  c.xor        a5, s0
                  addi         s3, a6, 1065
                  xor          s9, a7, gp
                  andi         t2, s9, 860
                  csrrci       t6, 0x340, 0
                  rem          t6, t1, ra
                  remu         t3, a7, t0
                  nop
                  andi         s6, s0, 1147
                  csrrs        a1, 0x340, t6
                  sub          a3, gp, s1
                  csrrwi       ra, 0x340, 26
                  c.lui        s9, 23
                  c.andi       a1, 24
                  sub          a1, t3, t4
                  slti         s7, t6, -1008
                  srli         t0, s10, 19
                  srai         s6, t3, 13
                  mulhsu       gp, s8, sp
                  c.nop
                  c.srai       s0, 18
                  div          a3, s9, s4
                  srai         s6, s2, 8
                  c.add        a1, s9
                  c.andi       a5, -1
                  rem          a3, t1, a0
                  mulh         s7, t0, sp
                  c.or         a3, a1
                  sltiu        t3, t5, -1732
                  xor          a4, s7, t5
                  csrrci       a0, 0x340, 26
                  nop
                  auipc        s1, 757931
                  mulhsu       s0, s4, a7
                  c.xor        s0, s0
                  and          t6, ra, s4
                  sltu         a4, t4, s5
                  slti         s4, sp, -221
                  div          s11, zero, t4
                  srai         s1, a6, 16
                  or           a3, ra, a4
                  sltu         a5, s4, a5
                  sub          a6, t6, zero
                  c.slli       a1, 29
                  c.and        s0, a3
                  mul          t2, ra, s11
                  divu         a0, s3, t0
                  csrrsi       tp, 0x340, 8
                  sub          a1, s1, s11
                  remu         s11, s1, s7
                  c.nop
                  c.sub        s1, a5
                  srai         gp, a3, 17
                  c.addi       t4, -1
                  xori         a5, s1, -970
                  c.lui        a5, 12
                  srli         a6, a7, 29
                  xor          ra, a1, t5
                  srl          s6, a7, s4
                  c.and        a5, a1
                  mulh         ra, s11, a4
                  ori          t2, s6, 989
                  c.or         a1, a4
                  nop
                  nop
                  or           t4, a0, t5
                  rem          a6, t2, s7
                  or           t3, s2, s7
                  ori          a7, t2, -1071
                  slt          t0, t3, a1
                  c.li         t0, 22
                  sltiu        ra, t5, -1831
                  xori         a7, s1, -288
                  xori         t1, t0, 1469
                  xori         a1, t0, -1199
                  c.nop
                  slt          a7, s0, a7
                  c.srai       a5, 17
                  and          s0, s1, t5
                  mul          ra, s11, t2
                  mul          s9, s0, s4
                  csrrw        s0, 0x340, s1
                  csrrsi       s3, 0x340, 11
                  c.lui        s7, 30
                  c.and        a1, a2
                  remu         s9, ra, s10
                  lui          s2, 166614
                  csrrwi       a4, 0x340, 16
                  andi         t0, t3, -400
                  slt          t0, s11, t2
                  slti         s4, zero, 1769
                  csrrc        a5, 0x340, s6
                  c.lui        a1, 17
                  sra          zero, a7, s3
                  csrrs        s2, 0x340, zero
                  csrrwi       tp, 0x340, 0
                  div          t2, s10, a3
                  mulh         s8, s5, t1
                  mulhsu       s2, zero, a4
                  auipc        a0, 650498
                  mul          s6, s8, a3
                  mulhu        s1, s8, s11
                  slt          t2, s9, a3
                  and          s6, s10, zero
                  xor          a4, s8, zero
                  c.nop
                  ori          a5, s10, 1220
                  c.and        a4, a1
                  and          a5, gp, s7
                  sub          t5, t4, a7
                  csrrw        s4, 0x340, a0
                  c.lui        a1, 16
                  mulh         s7, t6, s4
                  add          ra, a5, s4
                  andi         s7, t0, 1488
                  c.sub        a1, a2
                  sltiu        ra, t5, 783
                  c.mv         gp, s8
                  srli         zero, s9, 26
                  and          t1, s10, a6
                  nop
                  sltu         t4, s0, s10
                  sltu         a3, s4, s11
                  mulh         s9, t1, s6
                  xori         s8, s4, 436
                  remu         s4, a7, a1
                  xori         t6, s10, 1380
                  srai         t1, t2, 4
                  srai         tp, s10, 17
                  slli         a3, s3, 16
                  srai         s11, sp, 27
                  sub          s8, s5, s1
                  mulhsu       s7, s3, s10
                  c.andi       s0, 20
                  csrrw        s2, 0x340, t0
                  mulhsu       t1, a6, a3
                  c.xor        a4, a2
                  sra          a4, t5, s7
                  c.slli       a4, 15
                  sub          s0, t0, s6
                  mulh         gp, s3, a2
                  andi         t4, s9, -1062
                  csrrc        s5, 0x340, a2
                  mulh         t4, s5, s2
                  slti         a7, s0, 290
                  csrrwi       gp, 0x340, 13
                  mulhu        s8, s7, t1
                  csrrwi       t0, 0x340, 6
                  srli         t3, s6, 25
                  srai         s8, a1, 8
                  c.xor        a4, a3
                  and          t0, a0, t3
                  addi         s5, a4, 88
                  sll          s3, s5, ra
                  csrrc        s5, 0x340, a7
                  sll          t4, s4, zero
                  andi         t1, s3, -993
                  csrrci       s11, 0x340, 0
                  c.li         t4, 18
                  div          s11, s10, s8
                  c.addi       s2, -1
                  divu         s5, s11, a6
                  div          s9, tp, s6
                  auipc        s7, 1013536
                  sltiu        s0, a7, -881
                  c.add        s2, t5
                  c.srli       a0, 24
                  remu         a6, s6, s2
                  or           s9, t5, t1
                  c.or         s1, a0
                  c.sub        a3, a1
                  rem          gp, ra, t2
                  mulh         a4, s0, t3
                  xori         a3, s8, 1498
                  sltiu        s0, t5, 1940
                  rem          tp, s10, s0
                  c.li         a7, 20
                  c.mv         s6, a2
                  csrrs        s3, 0x340, t6
                  andi         a4, t6, -626
                  srli         a0, a4, 26
                  sub          s4, a7, a2
                  auipc        t0, 493267
                  xor          tp, gp, s3
                  xori         t6, t0, -1366
                  remu         s9, s7, a2
                  mulh         a6, a6, a7
                  ori          s5, zero, 48
                  c.xor        s0, s1
                  mulhu        s6, s10, gp
                  auipc        a7, 876491
                  mul          s4, s7, tp
                  sra          s8, a2, sp
                  sltiu        a4, s6, -1760
                  c.xor        s0, s0
                  remu         a3, s2, a2
                  c.srai       a3, 14
                  c.srli       a0, 12
                  c.andi       s1, 21
                  sltu         t4, s5, a3
                  sltiu        s5, s4, 1001
                  c.sub        a0, s0
                  c.xor        a1, a1
                  c.and        a1, s1
                  c.lui        a5, 31
                  slli         t6, a2, 1
                  rem          s4, s0, t0
                  csrrc        t3, 0x340, t1
                  div          t0, tp, s7
                  xori         a0, a0, -83
                  csrrci       t6, 0x340, 3
                  div          s0, a6, s11
                  c.xor        a4, a1
                  slt          s2, sp, sp
                  slti         s0, s1, 481
                  divu         t6, a2, a2
                  lui          a0, 64813
                  lui          a1, 139676
                  auipc        s1, 156039
                  csrrsi       t2, 0x340, 23
                  c.srai       a1, 21
                  c.mv         a4, s3
                  c.srai       s0, 8
                  c.add        ra, tp
                  mulhsu       t5, a7, s1
                  c.mv         a7, s4
                  csrrc        zero, 0x340, t2
                  csrrci       a3, 0x340, 22
                  c.or         a4, a5
                  c.or         a1, s1
                  c.and        a1, s1
                  slli         a3, s3, 4
                  slti         s4, t1, 368
                  mulhsu       a1, s4, a3
                  sub          t5, s6, a3
                  mulh         s7, a3, s3
                  addi         s11, a0, -311
                  c.srli       a4, 13
                  c.andi       a1, 19
                  c.li         s0, -1
                  auipc        t5, 790677
                  srli         a5, a3, 7
                  c.lui        s6, 1
                  csrrsi       s2, 0x340, 0
                  rem          t1, a4, ra
                  and          t5, t3, a4
                  c.lui        ra, 26
                  addi         t5, a1, -18
                  mul          s7, s1, t2
                  c.mv         a4, t3
                  lui          gp, 1039905
                  csrrci       s9, 0x340, 21
                  c.li         a6, -1
                  sltiu        t0, zero, -613
                  slli         a1, a5, 12
                  nop
                  mulh         zero, a7, s6
                  mulhsu       s7, t1, a3
                  c.lui        s6, 7
                  c.slli       t3, 3
                  slti         s9, s7, -1249
                  addi         s2, t3, 102
                  csrrc        s9, 0x340, zero
                  sub          s1, s1, a7
                  mulhsu       s1, s9, a1
                  c.nop
                  auipc        t2, 118463
                  srli         t5, s4, 25
                  c.xor        a1, a1
                  lui          s11, 258043
                  c.lui        t2, 11
                  csrrci       t1, 0x340, 25
                  srl          s1, s8, s7
                  csrrwi       t3, 0x340, 2
                  sub          tp, s1, gp
                  csrrc        s1, 0x340, zero
                  c.andi       a1, -1
                  c.sub        a1, s0
                  c.lui        t6, 14
                  slt          t4, gp, s8
                  sra          t2, a4, s4
                  rem          t4, s5, a1
                  xori         a0, s8, -1701
                  c.and        a5, a4
                  mul          a4, tp, s8
                  csrrwi       t0, 0x340, 1
                  div          s9, s5, a4
                  remu         s3, a7, zero
                  c.srai       s1, 2
                  csrrc        a7, 0x340, s6
                  srl          t0, s10, s8
                  c.andi       a0, -1
                  csrrsi       t1, 0x340, 0
                  div          a0, s6, s2
                  c.srli       a5, 28
                  addi         s2, a6, 69
                  xori         s4, t1, -1383
                  srl          t0, t6, gp
                  csrrw        gp, 0x340, s5
                  sll          s4, s8, a0
                  csrrsi       gp, 0x340, 2
                  c.xor        a4, s0
                  sltiu        a7, a7, 1532
                  csrrsi       t5, 0x340, 31
                  xori         zero, t1, 1752
                  addi         t4, s1, 1832
                  mulhu        s7, s5, t4
                  nop
                  srai         t2, zero, 10
                  or           s2, s1, a0
                  c.li         a7, -1
                  lui          zero, 505618
                  c.addi       s3, -1
                  csrrwi       t5, 0x340, 30
                  divu         s3, t2, s9
                  csrrsi       s7, 0x340, 0
                  c.and        a1, a4
                  mul          tp, t4, s10
                  c.nop
                  csrrsi       s4, 0x340, 5
                  sll          t0, s3, zero
                  or           a7, a6, a3
                  csrrwi       tp, 0x340, 30
                  c.add        t3, s11
                  andi         s2, zero, 1314
                  div          zero, tp, t1
                  c.li         t2, 13
                  addi         s8, s1, -1932
                  csrrs        ra, 0x340, a4
                  ori          tp, zero, -729
                  slti         s11, s1, 1508
                  rem          a3, t5, s11
                  andi         a7, zero, -1231
                  csrrci       zero, 0x340, 0
                  mulhsu       a1, a2, ra
                  mulhu        t1, s9, s6
                  c.xor        s1, a5
                  c.add        t3, t2
                  xor          s0, a3, s11
                  rem          s11, zero, s1
                  sltu         s6, s5, tp
                  mul          s9, t6, s3
                  c.slli       a1, 25
                  ori          t5, a0, -1309
                  mulh         s1, s6, t2
                  lui          t5, 876186
                  csrrwi       s8, 0x340, 8
                  c.nop
                  slt          s1, s8, a5
                  auipc        s9, 41291
                  xor          s0, ra, t1
                  slt          t6, t2, a7
                  ori          zero, a4, -1175
                  srai         s0, s6, 14
                  c.andi       a5, 1
                  slti         a5, gp, -520
                  c.srai       a4, 4
                  mulhu        zero, t0, s3
                  or           s3, t2, s1
                  remu         s4, s10, t3
                  c.or         a5, a5
                  sltiu        a5, s11, 534
                  csrrwi       s0, 0x340, 11
                  c.li         s8, 8
                  slli         s2, t3, 11
                  sltiu        t4, a0, -2013
                  c.xor        s0, a5
                  csrrc        a0, 0x340, a7
                  mulhsu       a3, t3, t4
                  csrrw        zero, 0x340, s7
                  auipc        s3, 198301
                  csrrs        t1, 0x340, s9
                  c.slli       t6, 6
                  mulh         a1, a2, t4
                  csrrc        tp, 0x340, zero
                  xor          gp, s3, a6
                  c.mv         a6, a1
                  slt          s2, s11, sp
                  csrrwi       t2, 0x340, 28
                  xor          gp, s9, ra
                  sra          gp, s1, t3
                  srl          t5, t4, s6
                  c.andi       a1, -1
                  c.srai       s1, 4
                  sub          a5, t2, s2
                  slli         a3, a0, 27
                  lui          a0, 221279
                  mulhsu       s3, sp, a7
                  c.sub        a0, a4
                  slti         t5, t4, -97
                  sub          s3, a4, a1
                  rem          t1, t6, s10
                  mulhsu       tp, gp, sp
                  c.xor        a1, a0
                  sub          t6, s5, t5
                  srl          t4, s3, a3
                  c.srli       a4, 21
                  or           t4, s2, t1
                  xor          a4, s8, t1
                  csrrw        a7, 0x340, s6
                  c.slli       gp, 15
                  divu         a4, s7, s5
                  c.and        a3, a4
                  rem          s2, t0, tp
                  c.srli       s0, 28
                  slti         s3, t2, -157
                  rem          a3, t2, s1
                  csrrs        a3, 0x340, zero
                  mul          gp, s4, gp
                  mulh         s11, s3, t1
                  ori          t3, s9, -1632
                  c.srli       a0, 18
                  csrrc        a1, 0x340, zero
                  csrrwi       a0, 0x340, 18
                  c.slli       a3, 22
                  sub          zero, s2, a4
                  c.nop
                  lui          s8, 812839
                  xor          s7, a2, a2
                  sltiu        s2, s9, 204
                  c.srai       a4, 5
                  and          s5, s7, s8
                  slt          ra, a3, a3
                  or           s11, s6, s1
                  c.lui        s9, 21
                  nop
                  c.srli       a4, 10
                  slli         t5, s6, 21
                  srli         s5, t6, 22
                  divu         s11, t2, a1
                  addi         t3, a1, 363
                  srli         s2, s11, 15
                  c.mv         t1, s2
                  srli         a4, s7, 24
                  nop
                  sltiu        s2, s5, 290
                  srli         s4, s10, 15
                  c.sub        a1, a0
                  c.mv         s11, s4
                  mulh         ra, t0, a6
                  mulhu        s11, zero, a4
                  xor          s8, a6, s4
                  c.and        a3, a4
                  c.srai       a1, 26
                  c.and        a5, a3
                  c.nop
                  c.srli       s1, 29
                  csrrsi       t6, 0x340, 4
                  slt          t4, t2, s8
                  slti         gp, s2, -856
                  sltiu        a0, t6, 1940
                  slli         s0, a3, 13
                  xor          a1, a7, a0
                  csrrsi       t6, 0x340, 18
                  c.slli       s6, 12
                  slt          a3, a6, tp
                  sll          s2, a3, s4
                  c.li         tp, 7
                  c.mv         s9, t5
                  xori         t6, s11, -1383
                  c.andi       s0, -1
                  csrrci       s8, 0x340, 22
                  slti         s8, s4, 1425
                  remu         t5, s4, s8
                  mulh         s6, s1, a5
                  c.slli       t3, 23
                  c.or         a0, a3
                  sltu         t0, s9, s7
                  and          a3, a4, tp
                  c.addi       s0, 6
                  srli         t2, s7, 19
                  slli         t2, s2, 20
                  csrrsi       t2, 0x340, 28
                  mulhu        t5, t3, a5
                  srli         a3, a7, 16
                  rem          s2, s5, t4
                  srli         a4, ra, 30
                  sltu         s2, s3, a1
                  auipc        a3, 695992
                  auipc        s5, 246452
                  sltu         a7, s1, s7
                  csrrc        t1, 0x340, s0
                  slli         s7, a2, 16
                  srl          gp, s5, t1
                  and          a4, s11, a0
                  c.mv         a7, s6
                  c.slli       a5, 13
                  and          s9, t0, t1
                  or           a3, sp, gp
                  c.slli       s11, 12
                  c.li         s3, 14
                  c.nop
                  mulhsu       a1, a3, t5
                  c.nop
                  div          s0, gp, s6
                  mul          t2, s1, s2
                  c.lui        s4, 25
                  xor          s6, s4, t6
                  sltu         s0, t2, gp
                  remu         t6, s11, s2
                  ori          s0, t3, -1642
                  div          s1, a7, ra
                  csrrs        a7, 0x340, zero
                  sltiu        t2, s7, -519
                  slti         ra, t6, 429
                  and          t4, s11, zero
                  c.andi       s1, 8
                  csrrci       s9, 0x340, 3
                  slt          a1, a1, t1
                  c.mv         a4, t4
                  c.andi       a1, -1
                  c.add        t4, s10
                  c.nop
                  csrrw        zero, 0x340, a7
                  xori         s1, a6, 1522
                  sub          s9, tp, a5
                  nop
                  c.li         ra, 13
                  auipc        a6, 935477
                  csrrsi       s3, 0x340, 0
                  lui          zero, 710245
                  slli         gp, a0, 29
                  c.mv         s9, t1
                  csrrci       gp, 0x340, 0
                  mulh         s7, gp, a3
                  srli         s3, ra, 21
                  c.sub        a5, a5
                  sub          s6, a2, tp
                  mul          a6, a5, a6
                  xor          tp, s8, a4
                  or           a3, t3, s8
                  slli         a7, t1, 2
                  addi         t3, s3, -889
                  c.lui        s8, 30
                  rem          a1, s2, a5
                  csrrwi       s9, 0x340, 18
                  csrrs        s1, 0x340, zero
                  auipc        s11, 428478
                  c.slli       t1, 2
                  c.srli       a1, 18
                  or           a3, s6, s5
                  mulh         s9, gp, gp
                  divu         s3, a2, a2
                  sub          gp, s8, t0
                  srli         s9, s3, 1
                  xori         s7, a3, -1879
                  addi         t2, a0, 667
                  c.xor        a5, a4
                  sltiu        zero, t6, -614
                  csrrwi       s7, 0x340, 11
                  ori          s8, s7, -1038
                  csrrc        s11, 0x340, s6
                  addi         gp, a6, 73
                  csrrci       t0, 0x340, 14
                  divu         s9, gp, a6
                  andi         a1, t6, -1438
                  mulh         t6, t2, t1
                  csrrc        s0, 0x340, zero
                  and          a5, tp, tp
                  slli         a5, tp, 14
                  mul          t1, s8, s1
                  mul          t0, sp, s7
                  mul          gp, s2, t5
                  c.sub        a5, a5
                  add          t6, a6, ra
                  sltu         s11, zero, a3
                  slti         s3, t0, -1763
                  srli         t4, s8, 8
                  mulh         zero, s9, ra
                  slti         zero, t4, 1575
                  auipc        ra, 322159
                  mulhsu       s5, t5, a0
                  c.andi       s0, 28
                  c.xor        s0, a2
                  srli         t5, t4, 1
                  srl          s2, t0, gp
                  or           s6, a6, tp
                  c.and        a4, a3
                  csrrc        s1, 0x340, t2
                  sra          a0, tp, t3
                  c.andi       a5, -1
                  srli         a1, ra, 2
                  c.andi       s0, -1
                  and          s11, s6, t5
                  c.sub        a0, a5
                  mulhsu       t5, a5, a2
                  sltu         s7, t2, s11
                  c.srai       a4, 9
                  c.sub        a3, a3
                  xori         a5, t1, -306
                  slti         a6, t3, 952
                  c.or         a0, a3
                  ori          s2, a7, 568
                  srl          gp, s4, a0
                  srl          a4, s1, t4
                  or           t4, zero, t4
                  c.add        tp, t0
                  csrrsi       a1, 0x340, 24
                  slti         s6, a4, 1756
                  divu         t1, a4, s5
                  c.slli       s4, 30
                  remu         a5, s6, a0
                  andi         a6, a3, -1925
                  or           a4, a3, t1
                  csrrsi       t4, 0x340, 0
                  c.nop
                  mulhu        s5, tp, s6
                  sub          s5, s5, t6
                  srli         zero, s7, 20
                  add          a0, a5, t3
                  c.li         s4, 26
                  slt          t2, s8, s8
                  sub          a7, s5, s8
                  ori          s1, gp, -352
                  c.li         a5, -1
                  sltiu        zero, zero, -1979
                  or           t2, s0, s2
                  srl          s11, s5, t4
                  c.xor        a3, a2
                  c.or         a1, s1
                  c.andi       a3, -1
                  slti         tp, a0, -214
                  or           t1, s4, t5
                  slli         s1, t2, 26
                  c.andi       s1, 28
                  c.srai       a1, 8
                  rem          t3, s3, t2
                  xori         t2, s10, 1261
                  addi         zero, t1, -1679
                  xori         a6, a0, 875
                  or           t4, a5, s6
                  c.or         a0, s0
                  add          a5, s1, sp
                  c.slli       tp, 21
                  div          a3, ra, a4
                  c.addi       s7, -1
                  csrrsi       s0, 0x340, 0
                  mulh         s2, s6, s0
                  csrrc        t0, 0x340, t3
                  srli         t5, s9, 0
                  auipc        s0, 720620
                  srl          t1, s9, s6
                  csrrc        t3, 0x340, s8
                  mul          s3, s4, s4
                  slt          t5, sp, a1
                  c.srai       a4, 21
                  or           s6, s5, s0
                  c.addi       a3, -1
                  mulh         t4, a7, s9
                  sltu         s3, t0, s2
                  mulhu        t2, s7, s5
                  srli         a1, zero, 16
                  or           s3, a4, t3
                  c.srai       a1, 7
                  csrrw        s3, 0x340, s5
                  c.nop
                  csrrsi       tp, 0x340, 0
                  div          a0, t3, t6
                  csrrci       a1, 0x340, 0
                  addi         s5, a0, 1024
                  mulhu        t3, tp, s3
                  slti         t3, s7, 1020
                  sltu         t4, t3, t2
                  mulh         t1, s8, t3
                  c.andi       s1, -1
                  slli         t0, a4, 23
                  xor          a1, t5, t2
                  c.srli       a0, 22
                  srl          tp, s7, t3
                  andi         a7, a7, -538
                  sltu         a0, s3, gp
                  ori          t5, a5, 444
                  c.and        a1, a1
                  c.and        a0, a4
                  mulh         s6, s2, s8
                  csrrs        s6, 0x340, t4
                  divu         t6, t4, s7
                  srai         gp, s1, 14
                  c.addi       t2, -1
                  div          s5, t6, a2
                  rem          s3, sp, a6
                  andi         a3, a2, 1971
                  slli         ra, t2, 4
                  or           a0, s11, t1
                  c.li         s4, -1
                  xor          t6, s11, s10
                  addi         t4, a1, -178
                  divu         a7, s6, a5
                  srai         a5, s2, 4
                  mulhsu       t4, t1, gp
                  sltiu        gp, t0, 2009
                  c.slli       s1, 22
                  mulhu        s11, s0, s4
                  sll          a0, s0, s2
                  sll          a5, a3, t0
                  c.andi       a4, -1
                  srli         gp, s9, 30
                  remu         s4, s4, a3
                  mulhsu       a3, sp, a7
                  csrrs        gp, 0x340, zero
                  remu         s1, t5, s9
                  csrrwi       s8, 0x340, 19
                  c.xor        a0, a3
                  c.xor        a1, a3
                  csrrc        s8, 0x340, zero
                  addi         s6, zero, -215
                  c.xor        s1, a3
                  xori         a1, a6, -744
                  c.slli       t0, 17
                  c.and        a3, a5
                  srai         a1, t6, 5
                  c.srli       a4, 3
                  c.sub        a1, s0
                  slti         t0, a3, -1167
                  and          a6, s2, s0
                  div          a1, a5, t4
                  mulhsu       s4, t2, a6
                  c.lui        s7, 22
                  slli         gp, t6, 27
                  addi         s9, t0, -1571
                  xor          t5, a4, s10
                  slt          t2, zero, a1
                  sll          t5, s11, s8
                  divu         ra, a0, s6
                  csrrwi       zero, 0x340, 2
                  mulh         s8, t4, s6
                  c.and        s1, s0
                  mulh         a7, s5, s7
                  csrrwi       t2, 0x340, 8
                  addi         a7, a0, 561
                  csrrw        s9, 0x340, s1
                  addi         zero, s3, 897
                  c.srli       a0, 9
                  sll          t4, s0, s9
                  divu         a4, s9, t2
                  c.srai       a3, 28
                  mul          zero, s11, zero
                  sltiu        ra, tp, 1958
                  slli         tp, t5, 16
                  csrrw        s9, 0x340, a3
                  remu         a0, tp, t1
                  csrrw        t3, 0x340, sp
                  sra          s5, s1, t3
                  ori          t2, s11, -149
                  csrrsi       t3, 0x340, 4
                  c.srli       a3, 22
                  auipc        zero, 112569
                  divu         a5, s9, s3
                  or           a6, s1, s6
                  remu         s2, s2, a6
                  or           s6, t5, s8
                  c.li         gp, 15
                  rem          gp, tp, t5
                  xor          t1, a5, s3
                  mulhsu       s3, s8, s1
                  div          t4, a5, tp
                  c.sub        s1, a5
                  slti         t5, t3, -1257
                  divu         s6, ra, t1
                  xor          t2, t4, t4
                  csrrs        s2, 0x340, zero
                  mul          s11, a4, s5
                  div          s2, s8, a2
                  divu         t3, a4, sp
                  c.slli       tp, 23
                  andi         s4, sp, -1433
                  andi         a1, s3, 920
                  csrrci       gp, 0x340, 14
                  and          a4, s4, ra
                  srl          s11, s11, s0
                  csrrw        zero, 0x340, s11
                  csrrw        gp, 0x340, s10
                  slti         tp, s3, -901
                  sll          a1, a1, s7
                  mul          gp, s7, t6
                  and          t4, s9, a0
                  c.srli       a1, 19
                  sll          a0, s3, t1
                  c.srli       a0, 25
                  mulhu        a4, s5, s9
                  nop
                  slti         tp, s1, 2042
                  sra          t5, s0, s3
                  or           s7, s11, t2
                  srli         s8, s10, 20
                  c.and        s0, s0
                  and          a3, s2, s7
                  c.slli       a4, 31
                  c.xor        s0, a4
                  mul          a7, a6, a0
                  andi         t2, a1, -1679
                  sll          a4, s3, t5
                  mulh         s7, s3, a7
                  slti         t5, a7, -146
                  addi         a1, t4, 922
                  sra          zero, ra, a1
                  sltiu        s11, s2, 657
                  mulhu        a7, t4, s8
                  sub          t2, tp, s8
                  lui          tp, 976885
                  csrrc        a6, 0x340, zero
                  mulhu        a1, t1, a0
                  remu         t0, t0, s9
                  srl          gp, s5, s0
                  c.li         ra, 18
                  div          zero, s9, ra
                  c.sub        a0, s1
                  c.nop
                  sll          a1, t0, a7
                  div          a3, a0, s1
                  add          s8, a7, a4
                  c.sub        a4, a5
                  andi         t5, a0, 1637
                  c.srli       a5, 12
                  add          s0, s3, zero
                  c.slli       s2, 27
                  divu         t4, zero, a5
                  csrrsi       s9, 0x340, 28
                  srai         a4, a2, 2
                  sra          s8, s9, t5
                  c.or         a3, a3
                  mulhsu       a5, gp, a4
                  addi         s1, t6, -2
                  lui          a3, 597148
                  xori         a0, s7, -1889
                  add          a3, a4, sp
                  sltiu        s9, a4, 1713
                  mul          s8, s7, s3
                  rem          gp, s7, a6
                  csrrw        s8, 0x340, t5
                  xor          a4, t1, s0
                  c.mv         t0, s8
                  mulhu        t2, s6, s5
                  mul          tp, s11, s10
                  c.lui        s7, 1
                  c.xor        a1, a3
                  mul          s3, t2, s2
                  xor          t5, t5, a4
                  csrrci       t3, 0x340, 0
                  sra          s1, a6, t2
                  sub          s4, s5, s10
                  csrrs        a6, 0x340, zero
                  c.li         s7, -1
                  auipc        s5, 823088
                  c.mv         s7, a2
                  nop
                  addi         t1, s10, 1083
                  srl          s4, s7, a7
                  sra          t6, s11, s1
                  c.or         s0, s1
                  csrrs        s7, 0x340, zero
                  c.srli       a4, 14
                  csrrc        t3, 0x340, zero
                  nop
                  ori          s6, s0, -703
                  srl          a7, t2, s11
                  csrrci       a6, 0x340, 11
                  srai         a6, t6, 23
                  srli         ra, a4, 7
                  mulhu        s2, t2, s4
                  csrrsi       s6, 0x340, 0
                  csrrw        s7, 0x340, s2
                  divu         s3, a2, s0
                  andi         s8, s2, 672
                  c.lui        s5, 16
                  andi         s7, a5, 1582
                  slli         s1, s3, 4
                  c.li         a7, -1
                  csrrc        a6, 0x340, s6
                  mulhu        s6, s7, a3
                  c.or         a5, a0
                  csrrs        t0, 0x340, zero
                  div          t1, s5, a5
                  c.add        s11, a6
                  xor          t6, t3, t3
                  c.srli       s0, 16
                  mulhu        a3, s8, s4
                  lui          t3, 754448
                  slt          t3, t2, s1
                  slli         a1, a4, 7
                  csrrw        t6, 0x340, s5
                  csrrc        s0, 0x340, zero
                  csrrsi       s0, 0x340, 0
                  xor          s7, sp, a2
                  c.andi       a0, -1
                  c.addi       s3, -1
                  c.srli       a4, 5
                  c.andi       a0, 19
                  and          s4, s9, s11
                  c.and        a3, a5
                  c.sub        a4, s1
                  xor          ra, t2, s8
                  xor          s0, s6, s9
                  divu         s11, a5, a4
                  sll          t0, t5, t3
                  sra          a3, t6, a4
                  or           t3, t0, s10
                  lui          a7, 12158
                  c.lui        a1, 15
                  c.lui        s0, 10
                  c.slli       s7, 15
                  sltu         s6, t3, s11
                  c.and        a5, s1
                  add          s11, s10, s8
                  or           t5, t3, s10
                  slli         t6, s11, 27
                  sltu         a5, t2, t2
                  and          a4, a1, s4
                  mulhsu       t3, s1, s7
                  slt          a1, a6, a0
                  srai         s11, s10, 29
                  sltu         s1, s8, s8
                  lui          t6, 519641
                  csrrwi       t3, 0x340, 26
                  c.slli       a4, 10
                  add          s2, s5, a1
                  andi         s4, a4, 1248
                  c.srai       a4, 9
                  csrrs        a4, 0x340, s11
                  c.xor        a3, a0
                  sll          s1, sp, s6
                  addi         tp, a4, 1596
                  div          a3, a2, a2
                  lui          s9, 50297
                  add          t5, a6, t4
                  addi         s6, s5, -1678
                  sub          a4, t3, s10
                  divu         s8, t5, a5
                  csrrw        t1, 0x340, s0
                  sll          a6, t0, s4
                  sub          t3, s6, a5
                  slli         a4, s11, 24
                  mul          s1, s11, a1
                  csrrwi       t6, 0x340, 13
                  c.srli       s0, 18
                  andi         s7, a6, -1450
                  srl          a7, s10, t5
                  csrrwi       a5, 0x340, 3
                  sub          s8, t0, a3
                  xor          s8, ra, t6
                  sltiu        a4, t6, 1490
                  c.xor        a1, a4
                  remu         ra, a0, s8
                  csrrsi       tp, 0x340, 0
                  and          t5, t5, s0
                  sltiu        t1, a5, 1666
                  sltiu        a3, s11, -1136
                  c.nop
                  xor          a4, ra, s5
                  c.add        ra, a2
                  srli         t0, sp, 9
                  c.and        s1, a1
                  c.mv         s6, a6
                  c.mv         gp, s3
                  sltu         a7, a6, sp
                  sltiu        t6, t2, -247
                  c.and        s1, a3
                  slti         t1, t5, 603
                  remu         a3, s10, a7
                  csrrci       a3, 0x340, 16
                  slt          t0, s10, s5
                  div          s5, s4, s5
                  slli         t1, t2, 19
                  and          a0, a4, s7
                  mulhsu       t6, a5, t4
                  c.nop
                  c.li         s0, -1
                  sltiu        s7, a4, 517
                  c.xor        a3, a0
                  andi         t4, s0, 647
                  xor          tp, s8, t1
                  add          t2, t6, s9
                  c.srai       a1, 17
                  divu         s4, a0, s2
                  mulhsu       s9, s11, a1
                  c.srai       s1, 31
                  c.lui        a3, 19
                  c.slli       a0, 24
                  c.add        s3, s10
                  sll          t2, a6, a7
                  rem          ra, t3, ra
                  c.and        a4, s0
                  xori         t5, t0, -142
                  csrrsi       s5, 0x340, 27
                  sra          s0, s5, t3
                  mulhsu       a6, s5, a0
                  srli         a0, s9, 11
                  c.and        s1, a5
                  c.xor        s0, a0
                  auipc        a4, 412813
                  auipc        t3, 905591
                  auipc        s3, 857877
                  c.add        s4, s4
                  csrrwi       a6, 0x340, 26
                  or           s3, zero, s3
                  mulh         t1, a0, a2
                  add          t3, s2, s9
                  c.or         a0, a0
                  sll          t4, s6, a5
                  csrrwi       s8, 0x340, 23
                  c.slli       a5, 7
                  sltu         t0, t1, a7
                  nop
                  andi         t5, s7, 785
                  nop
                  c.andi       s0, 0
                  ori          a7, s7, 309
                  csrrs        gp, 0x340, zero
                  sltu         s6, s3, t2
                  lui          t1, 638261
                  slti         s9, t0, -1868
                  c.slli       t2, 15
                  slti         a6, s10, -358
                  c.mv         s4, ra
                  c.andi       a1, 22
                  sll          s0, s1, a3
                  sub          s8, a3, t4
                  mulhu        s11, t0, s2
                  srl          t0, s11, s6
                  slli         tp, s3, 0
                  sltiu        s9, s6, 433
                  xori         s1, s4, -1314
                  c.srai       s0, 28
                  xori         t6, s11, -1518
                  mul          t0, sp, a7
                  csrrwi       a0, 0x340, 8
                  c.addi       s11, -1
                  c.mv         tp, s11
                  or           a6, s2, s5
                  c.srli       a4, 24
                  div          zero, s11, a6
                  slti         t5, t5, -2019
                  rem          t2, a3, s11
                  csrrci       s8, 0x340, 0
                  slti         a6, a6, 1304
                  sub          s1, a7, s9
                  csrrsi       a4, 0x340, 0
                  c.srli       a5, 14
                  xor          a1, s9, s3
                  add          ra, s2, a6
                  c.li         s11, 22
                  c.andi       a1, 8
                  addi         zero, t1, -1112
                  ori          a3, t2, 1550
                  sltiu        s7, a3, -1819
                  csrrs        s9, 0x340, s2
                  srl          s7, s4, s8
                  slli         a6, s8, 22
                  remu         t6, t5, a4
                  srl          s0, s5, a6
                  mulhu        s4, a3, a5
                  srli         t6, a3, 18
                  add          t3, t5, a2
                  c.mv         s0, s2
                  srl          tp, tp, s2
                  c.addi       s9, 22
                  add          t5, a4, s5
                  sll          ra, s5, s9
                  csrrc        s2, 0x340, zero
                  mul          zero, s10, sp
                  csrrc        a1, 0x340, s3
                  slti         t4, tp, -1032
                  xor          s9, a7, s10
                  mulh         t6, s0, a1
                  sub          a3, s7, s1
                  csrrs        a0, 0x340, zero
                  or           s5, a1, ra
                  nop
                  or           s11, s2, a1
                  mul          t5, a5, s4
                  sra          a0, s10, a4
                  srli         t5, t3, 6
                  xor          t6, tp, zero
                  rem          gp, sp, s7
                  mulhsu       s2, t0, s4
                  c.xor        a4, a1
                  c.slli       s11, 21
                  rem          t1, a1, t0
                  c.srai       a3, 16
                  c.srai       a0, 31
                  remu         s3, a6, gp
                  div          a4, s6, a7
                  mul          s8, a4, s4
                  c.lui        a5, 7
                  mulhsu       t0, t5, t2
                  c.mv         s2, ra
                  c.slli       a7, 16
                  auipc        gp, 765288
                  c.addi       a1, 5
                  rem          t6, a6, s9
                  c.sub        a3, a0
                  slt          t5, t5, s5
                  ori          t2, s4, -1483
                  sll          s8, sp, s6
                  mulh         s4, t6, a3
                  or           s9, t4, a0
                  mulh         s4, tp, s1
                  csrrs        a6, 0x340, zero
                  add          gp, s10, a5
                  rem          a0, s1, s6
                  or           s4, s6, zero
                  c.sub        a0, a1
                  or           t1, t1, a7
                  sltiu        s11, s11, 1009
                  srl          a6, s6, s8
                  srl          t1, t1, sp
                  slli         t1, a4, 4
                  c.slli       ra, 19
                  nop
                  c.and        a3, s0
                  srli         tp, t5, 10
                  srli         a1, sp, 0
                  andi         s11, t5, -1340
                  c.or         a5, a4
                  andi         gp, a6, 666
                  c.lui        gp, 1
                  sra          gp, a3, a3
                  remu         a4, s1, s4
                  sra          s3, a0, s1
                  srli         s8, s1, 20
                  csrrw        t0, 0x340, s1
                  div          t2, s0, a5
                  xor          a6, t1, s2
                  c.and        a5, a1
                  mul          s6, t2, zero
                  slti         t4, gp, -423
                  slti         a1, a3, -903
                  c.mv         s6, tp
                  csrrwi       s8, 0x340, 21
                  c.xor        a0, a3
                  nop
                  srli         a5, s7, 2
                  rem          s7, a3, a1
                  divu         t4, a7, tp
                  c.sub        a1, a4
                  slti         t2, a5, -207
                  add          s5, s1, zero
                  srai         t1, s7, 13
                  div          s1, s0, t3
                  or           s3, t4, a0
                  slt          s2, t0, a4
                  c.add        s4, a5
                  andi         a6, s2, 104
                  xor          t0, s4, s2
                  auipc        s9, 185215
                  srli         s2, s2, 10
                  csrrsi       s0, 0x340, 22
                  mulh         a1, t6, a5
                  c.srli       a3, 21
                  remu         a1, s3, s8
                  sltiu        ra, ra, 414
                  csrrwi       a4, 0x340, 5
                  c.srai       a0, 5
                  c.sub        a1, a5
                  c.andi       s0, 6
                  c.nop
                  c.xor        a4, a5
                  mulh         a7, s6, s9
                  divu         s11, a4, s8
                  divu         gp, s4, t4
                  xor          a0, sp, a4
                  c.lui        s7, 20
                  slt          tp, gp, s2
                  c.sub        s1, a0
                  csrrw        t5, 0x340, a4
                  csrrci       a4, 0x340, 0
                  c.srai       a4, 9
                  c.and        a0, a2
                  divu         t3, t2, t4
                  srl          s0, sp, sp
                  mulhu        gp, a2, s3
                  sub          t4, t1, zero
                  c.lui        t6, 21
                  add          a4, t6, s7
                  c.sub        a1, a2
                  mulhu        s6, s0, s11
                  rem          s5, tp, a2
                  c.sub        a5, a3
                  csrrs        gp, 0x340, gp
                  mulhu        s8, a3, a4
                  or           s7, a1, s8
                  csrrc        a3, 0x340, s3
                  mulhsu       t5, s2, t4
                  or           a0, sp, s10
                  srl          s4, a0, s8
                  c.mv         s1, s11
                  and          s9, sp, s10
                  csrrc        gp, 0x340, a1
                  divu         a1, zero, a3
                  slli         s3, tp, 28
                  c.srli       a4, 6
                  csrrsi       ra, 0x340, 0
                  srai         s2, a0, 15
                  mulhsu       a0, t2, t2
                  slti         s3, s8, -551
                  mulh         s5, a2, tp
                  c.lui        gp, 14
                  div          s7, ra, a4
                  c.nop
                  slli         t1, a1, 14
                  c.andi       a0, -1
                  slti         s11, gp, 1954
                  auipc        tp, 341566
                  csrrc        t4, 0x340, a7
                  c.add        t0, a0
                  csrrsi       t6, 0x340, 0
                  mulh         a4, tp, t1
                  nop
                  c.andi       a0, 6
                  andi         a1, a3, 1309
                  mul          s5, t4, s4
                  c.or         a1, a1
                  slti         zero, s4, -712
                  slti         t2, t0, 1019
                  sltu         s8, t4, t0
                  addi         gp, s0, 434
                  mulh         s6, ra, a1
                  c.addi       ra, -1
                  add          a4, t4, t5
                  or           s1, s6, a0
                  xori         ra, a3, 819
                  c.mv         a4, t0
                  sub          tp, a4, ra
                  mul          gp, a1, s4
                  c.or         a1, s1
                  sltiu        zero, s4, -943
                  c.slli       ra, 17
                  csrrci       t5, 0x340, 0
                  sll          ra, t6, a1
                  slli         t5, zero, 6
                  c.slli       a6, 24
                  srl          a6, s11, a6
                  rem          s7, a0, s2
                  slti         s3, t1, -1338
                  auipc        t2, 455647
                  and          t6, a3, s3
                  c.addi       s7, 1
                  c.addi       gp, -1
                  mulhu        s5, t0, t4
                  lui          a1, 408184
                  rem          s0, a1, s6
                  c.xor        a0, a3
                  xori         a6, s2, -1337
                  sltiu        t0, zero, -2028
                  slt          a3, zero, ra
                  c.and        s1, a3
                  c.srai       a0, 12
                  c.lui        s6, 23
                  divu         t3, s8, tp
                  xori         s3, tp, 1865
                  mulh         s9, s9, a2
                  csrrsi       a7, 0x340, 0
                  nop
                  slti         t4, s9, 714
                  slli         t6, s4, 18
                  csrrw        a3, 0x340, t0
                  slti         a6, s7, 849
                  c.nop
                  csrrs        tp, 0x340, zero
                  mulh         s3, s2, a0
                  sltu         t5, t2, t6
                  mulhsu       gp, s3, s8
                  c.andi       a5, 6
                  c.andi       a0, 20
                  c.slli       a0, 2
                  divu         s9, a3, a1
                  c.srai       a0, 4
                  c.nop
                  c.xor        a0, a0
                  nop
                  auipc        s5, 604958
                  sll          a6, a5, a6
                  c.xor        a5, a1
                  c.nop
                  srli         zero, a0, 24
                  c.srai       a1, 6
                  c.or         a1, a1
                  xor          s3, sp, s1
                  mulh         t2, s10, zero
                  c.or         a5, a4
                  c.lui        a4, 29
                  xori         s9, a7, -28
                  srli         s4, t5, 16
                  csrrsi       a7, 0x340, 15
                  mulh         a7, a5, s5
                  addi         t3, zero, 1840
                  or           s9, t5, a7
                  c.sub        s1, a3
                  mulhsu       zero, s3, s1
                  div          t5, gp, t6
                  srl          a7, s7, a4
                  csrrs        gp, 0x340, a1
                  c.addi       ra, 8
                  c.lui        s11, 4
                  csrrci       s3, 0x340, 0
                  slti         ra, s5, 1217
                  and          s4, s1, tp
                  c.add        a4, s9
                  srai         s7, a3, 10
                  c.srai       s1, 15
                  mulh         a3, t6, a3
                  srli         a4, s3, 21
                  ori          a3, s9, 1337
                  slti         a5, s7, -1756
                  c.srai       s1, 10
                  remu         t1, s11, s5
                  nop
                  csrrsi       a6, 0x340, 26
                  ori          s9, s10, 79
                  c.li         a0, 12
                  c.or         a5, s0
                  sltiu        tp, s1, -1341
                  csrrc        s11, 0x340, t1
                  srai         s4, a3, 13
                  csrrc        a7, 0x340, zero
                  div          t1, s6, a0
                  csrrc        t6, 0x340, zero
                  sll          s11, sp, s6
                  add          t3, s9, sp
                  or           gp, s0, ra
                  rem          t6, s6, t1
                  csrrci       a7, 0x340, 0
                  sll          t4, a6, s5
                  remu         a7, a3, a5
                  c.lui        gp, 18
                  lui          s0, 170300
                  c.sub        a5, a2
                  nop
                  sltiu        s8, a0, -415
                  ori          s8, s10, 1872
                  sll          s6, s7, a1
                  sra          a3, a1, s2
                  slt          t0, t2, t3
                  sltu         gp, a5, s11
                  c.srai       a0, 30
                  ori          a3, s8, 413
                  c.add        t5, a2
                  mulhu        t5, t3, s2
                  mulhsu       t5, a2, t5
                  slli         t6, s4, 26
                  c.srai       a4, 10
                  remu         s11, s0, t3
                  c.slli       s8, 9
                  csrrc        ra, 0x340, zero
                  slt          tp, a5, t0
                  srli         s11, t0, 0
                  csrrs        s1, 0x340, zero
                  rem          a6, a4, gp
                  nop
                  lui          t2, 800638
                  sra          s7, a5, a1
                  csrrsi       s9, 0x340, 0
                  c.slli       t6, 25
                  sub          a6, a2, s11
                  slli         a5, sp, 18
                  csrrc        t1, 0x340, t5
                  div          a1, a5, a2
                  csrrsi       s8, 0x340, 0
                  div          s5, t3, a3
                  xor          s0, ra, t6
                  csrrwi       gp, 0x340, 28
                  srli         t5, tp, 20
                  lui          a7, 281277
                  csrrs        a7, 0x340, t4
                  sub          gp, ra, t5
                  auipc        a6, 467754
                  div          a5, a0, s3
                  c.sub        a5, a1
                  c.srli       a4, 23
                  or           t4, s7, s2
                  c.srli       s1, 15
                  c.mv         t3, s3
                  sltiu        t6, zero, 334
                  c.andi       s0, -1
                  c.slli       t2, 6
                  c.nop
                  srai         s8, a7, 0
                  c.andi       a0, 20
                  auipc        zero, 97068
                  c.xor        s1, a2
                  c.sub        s0, a1
                  div          s0, t4, s1
                  c.li         a4, -1
                  c.srai       a4, 29
                  ori          a7, t3, -677
                  slti         a1, s11, -755
                  rem          t3, s5, s0
                  remu         s7, t1, t4
                  srl          ra, s1, s5
                  mulh         t3, a2, a2
                  divu         t0, s10, a0
                  csrrw        s5, 0x340, s0
                  sltiu        t1, zero, 1699
                  c.addi       gp, -1
                  mulhu        s0, a4, t1
                  add          a7, s8, t0
                  c.lui        t4, 2
                  c.srli       a4, 21
                  ori          ra, s10, -1093
                  c.srai       a0, 17
                  c.srli       s0, 12
                  auipc        a0, 776147
                  mulhu        t0, s8, t5
                  mulhsu       a6, s8, a2
                  rem          t1, t3, s11
                  slti         s2, t1, -560
                  sltiu        s8, s8, 1697
                  c.or         s0, a0
                  mulh         gp, a5, s9
                  mulhu        t4, s7, s3
                  srl          t3, a1, s7
                  c.nop
                  c.nop
                  rem          gp, tp, s2
                  srl          s2, t6, a2
                  div          t4, s0, s11
                  mulhsu       ra, t5, t0
                  auipc        a1, 64355
                  andi         t3, zero, -1582
                  sltu         gp, s4, t3
                  c.nop
                  c.nop
                  c.add        s0, t2
                  slli         s0, t5, 14
                  csrrc        t1, 0x340, zero
                  auipc        a4, 155591
                  and          tp, s11, tp
                  c.and        a1, s1
                  slt          t5, s5, gp
                  sra          s0, zero, t5
                  csrrci       t3, 0x340, 0
                  c.srli       a4, 12
                  auipc        s5, 949791
                  c.add        t5, s8
                  slli         tp, s1, 14
                  slli         t3, t1, 12
                  addi         s6, s3, 1312
                  auipc        zero, 331739
                  sub          s11, t1, s11
                  lui          t5, 532542
                  sltu         a7, t2, t3
                  c.lui        t3, 17
                  slt          s6, a6, t5
                  csrrs        t3, 0x340, s6
                  mulhu        s4, tp, tp
                  xor          s1, t0, a6
                  slt          a3, a6, s7
                  div          a7, t2, t0
                  and          t0, t3, a2
                  and          a3, a2, ra
                  c.srai       a4, 22
                  c.mv         s2, a7
                  addi         zero, s7, 276
                  and          t0, s9, ra
                  lui          zero, 830759
                  csrrs        s3, 0x340, zero
                  csrrw        gp, 0x340, s11
                  c.xor        s0, a2
                  c.mv         s4, s0
                  auipc        t2, 530995
                  lui          zero, 34921
                  xori         s1, t5, -15
                  c.mv         t5, t2
                  sub          t5, s0, a5
                  c.sub        a0, s0
                  div          t3, s6, a3
                  csrrwi       s11, 0x340, 24
                  srl          s8, t4, tp
                  csrrw        gp, 0x340, t1
                  sll          t0, t2, a5
                  remu         a1, a1, t6
                  divu         s5, s7, sp
                  srl          zero, a2, zero
                  c.addi       s7, -1
                  c.andi       s1, 30
                  lui          s8, 661844
                  c.srli       a5, 5
                  andi         zero, s11, -845
                  div          tp, t2, t4
                  andi         s1, a1, 1895
                  xori         a4, a6, -1960
                  c.or         s0, a2
                  csrrsi       a6, 0x340, 28
                  c.xor        a4, a1
                  c.srai       a3, 11
                  andi         t2, a7, 866
                  mulh         a4, tp, tp
                  c.and        a3, a0
                  c.or         a5, a3
                  lui          gp, 993784
                  ori          t4, s8, 1906
                  sltu         t1, t2, s5
                  c.srli       a3, 12
                  c.add        s0, a0
                  csrrw        a5, 0x340, a6
                  c.and        s0, s0
                  csrrs        t1, 0x340, zero
                  addi         a3, s9, 1751
                  mulhu        gp, s0, t3
                  csrrwi       s8, 0x340, 1
                  c.xor        a0, a3
                  sltiu        tp, s7, 840
                  csrrw        gp, 0x340, s9
                  c.andi       a1, 13
                  csrrw        s3, 0x340, a5
                  sltu         s2, zero, ra
                  remu         s1, t0, s2
                  sll          t3, a6, gp
                  andi         a0, a1, 1185
                  slti         a3, ra, -317
                  remu         a4, t4, sp
                  and          a5, zero, t6
                  c.srli       a4, 25
                  c.or         a0, s0
                  mulh         t5, t2, a4
                  srl          t6, sp, s5
                  c.or         a0, s1
                  srl          zero, s9, t5
                  auipc        a1, 36713
                  slt          s7, s6, s2
                  sltu         a7, a4, t5
                  c.li         s9, -1
                  and          s1, a5, a0
                  slt          s1, s3, a6
                  mulhsu       s1, s8, s1
                  mulhsu       a3, s2, s8
                  mulhsu       a0, a6, s6
                  divu         s3, s2, sp
                  csrrc        a7, 0x340, s8
                  csrrsi       a3, 0x340, 11
                  andi         ra, a3, -82
                  mul          t3, a4, t6
                  ori          ra, tp, 1415
                  c.and        a1, a1
                  sub          s3, ra, a7
                  addi         a6, s10, 222
                  csrrci       s3, 0x340, 1
                  srai         s4, ra, 27
                  rem          s7, a0, ra
                  sra          a6, t1, sp
                  mulhsu       a7, s8, t5
                  xor          t1, t2, s1
                  csrrwi       zero, 0x340, 27
                  slli         s2, s6, 9
                  c.lui        s4, 31
                  remu         a1, ra, t6
                  c.srli       s1, 13
                  c.sub        a3, a2
                  srli         s5, a5, 26
                  sub          t2, gp, s1
                  csrrci       a0, 0x340, 11
                  sltiu        a6, t3, 1268
                  c.slli       a1, 21
                  divu         t5, t1, sp
                  auipc        a1, 937609
                  c.mv         s3, t5
                  csrrw        a4, 0x340, t0
                  sltiu        t4, tp, 1957
                  srai         a7, s4, 21
                  c.li         s6, 30
                  auipc        s4, 755326
                  c.srli       a5, 19
                  c.or         a0, a0
                  csrrs        s9, 0x340, zero
                  mulhsu       t1, sp, s5
                  mulh         s2, gp, t6
                  lui          zero, 932698
                  c.and        a3, s0
                  mulhu        a1, t4, sp
                  mulhu        t4, a0, a3
                  srai         s3, t0, 13
                  addi         s1, s11, 814
                  sra          s1, s9, s1
                  xori         a0, t5, -148
                  add          a6, s4, t4
                  c.add        t0, a4
                  slli         gp, gp, 13
                  rem          t1, sp, a5
                  mulhu        s3, t3, sp
                  c.sub        s0, s0
                  or           s4, t0, t0
                  c.srli       a0, 4
                  or           t6, s8, a5
                  c.andi       a4, 2
                  srl          a0, t3, s10
                  divu         t5, s1, tp
                  c.mv         s8, s8
                  csrrc        s9, 0x340, t2
                  c.and        a1, a4
                  sltiu        a1, t5, 1943
                  srli         s5, ra, 27
                  slt          zero, t2, t2
                  c.slli       a7, 15
                  or           t1, a1, a6
                  c.nop
                  mulh         s4, a4, s0
                  c.and        s0, a0
                  c.lui        a4, 24
                  div          t4, a2, a6
                  mulhsu       s5, t3, s11
                  csrrc        ra, 0x340, zero
                  c.xor        a3, a2
                  add          t6, s8, t6
                  c.addi       a3, 31
                  c.or         a4, s0
                  addi         a5, a5, -1966
                  c.lui        a7, 20
                  andi         s2, a2, 44
                  c.addi       t6, 10
                  c.andi       s1, 30
                  lui          zero, 649987
                  divu         t1, s4, s4
                  c.or         a4, a3
                  c.mv         s3, s9
                  sra          a0, s8, a7
                  mul          t2, a3, s5
                  sltiu        s11, t5, -295
                  slti         a4, t2, -437
                  c.slli       a3, 1
                  add          s3, a7, s11
                  mulhu        s8, s5, s4
                  sltu         s7, t1, s5
                  c.lui        s9, 14
                  c.or         s0, a0
                  csrrc        s4, 0x340, zero
                  mulhu        t5, s4, s6
                  csrrs        s6, 0x340, zero
                  csrrwi       s1, 0x340, 29
                  c.srli       a4, 26
                  c.li         s3, -1
                  csrrci       s5, 0x340, 14
                  c.xor        a0, s0
                  c.or         s0, s0
                  c.mv         a4, a2
                  andi         s3, t1, 1921
                  c.add        s6, s9
                  c.andi       s1, -1
                  c.lui        t4, 9
                  c.sub        s1, s1
                  c.xor        a5, a3
                  auipc        t3, 252844
                  c.addi       a5, 7
                  csrrc        t5, 0x340, s6
                  add          zero, t6, s11
                  c.slli       a7, 31
                  mulhsu       a1, s8, ra
                  and          t6, a6, t3
                  div          a5, s11, s9
                  c.lui        a6, 22
                  divu         s1, s6, s7
                  c.and        a4, a5
                  csrrc        a5, 0x340, zero
                  c.xor        a3, s0
                  c.xor        s0, a2
                  c.lui        t0, 31
                  mulhsu       s5, s3, a4
                  c.lui        tp, 1
                  sra          s8, t5, t5
                  sltu         t3, a0, gp
                  andi         s0, a4, -1236
                  srli         s11, a2, 5
                  c.or         s1, a1
                  rem          s9, t3, s5
                  c.sub        a4, a4
                  rem          t2, t3, sp
                  mulhsu       a3, s9, s6
                  c.addi       tp, -1
                  c.add        s5, sp
                  srl          zero, zero, t4
                  mulhu        zero, s6, a5
                  c.and        a4, a3
                  slli         s9, s3, 11
                  mul          t5, s4, s9
                  csrrci       s7, 0x340, 0
                  sra          s8, a5, s10
                  ori          a0, sp, 954
                  or           t4, a7, a0
                  c.sub        s1, a3
                  c.xor        a1, a2
                  c.add        s4, s9
                  auipc        t3, 942203
                  auipc        s7, 785535
                  c.mv         a1, s8
                  slt          s11, s8, t6
                  remu         s9, s1, a3
                  slt          a3, a7, t2
                  sltiu        s7, a0, 2032
                  csrrc        t0, 0x340, zero
                  mulhsu       ra, s8, s2
                  sra          a5, a3, sp
                  slt          t1, s4, a1
                  nop
                  andi         t0, s5, 915
                  c.slli       gp, 24
                  csrrwi       s8, 0x340, 8
                  c.and        s0, s1
                  div          s5, t4, sp
                  sra          a6, a3, a3
                  csrrc        t2, 0x340, zero
                  c.and        s1, a2
                  c.and        a0, a5
                  sltiu        a7, t6, 1559
                  remu         s7, t5, t1
                  c.li         t6, 17
                  sll          a3, s2, t2
                  slli         s7, s8, 15
                  lui          s8, 878917
                  srl          a4, a2, s9
                  mulhsu       t0, s3, s6
                  rem          t0, t2, tp
                  and          s11, t0, t6
                  andi         tp, s7, -1120
                  c.add        a0, s8
                  rem          s9, gp, tp
                  c.sub        a0, a4
                  c.mv         t6, t2
                  srl          t4, gp, t0
                  remu         t2, s3, s10
                  addi         a3, a6, -1006
                  mulhsu       t3, sp, a4
                  nop
                  slti         t1, t0, -174
                  slli         s3, s2, 26
                  c.sub        a3, a5
                  slti         t1, a5, 1425
                  slli         a3, gp, 20
                  c.lui        s11, 22
                  csrrwi       s1, 0x340, 6
                  sltiu        a4, s3, -586
                  csrrc        s2, 0x340, s9
                  xor          t3, t6, s3
                  c.sub        a0, a1
                  rem          tp, tp, sp
                  c.xor        a4, a1
                  c.add        s8, gp
                  c.andi       a3, -1
                  sub          s1, s3, a0
                  csrrw        s0, 0x340, a0
                  c.lui        a6, 27
                  c.xor        a4, a1
                  nop
                  c.srli       s1, 23
                  mul          a0, s2, tp
                  or           s2, a2, t6
                  c.add        gp, a1
                  mulh         s8, ra, s6
                  mulhu        a5, a6, s0
                  csrrsi       s9, 0x340, 6
                  slti         a1, sp, -1471
                  c.xor        a4, a4
                  csrrsi       t2, 0x340, 0
                  xor          t2, t5, t4
                  c.addi       s0, 6
                  srli         t6, sp, 18
                  c.or         a4, s0
                  c.or         a3, a4
                  sub          ra, a7, a1
                  sll          t4, a0, t3
                  sltu         s2, s2, s7
                  sltu         a3, t2, s3
                  rem          s2, zero, ra
                  c.andi       a5, 8
                  sltu         s4, ra, t4
                  or           a6, sp, a5
                  mulhsu       a1, a5, s3
                  csrrw        ra, 0x340, tp
                  srli         a3, t5, 12
                  csrrc        a3, 0x340, s7
                  lui          s1, 174658
                  rem          t1, a0, a2
                  slt          s11, s6, zero
                  c.slli       a7, 2
                  csrrs        a6, 0x340, a4
                  c.andi       a4, 11
                  addi         s4, t5, -605
                  c.nop
                  add          t6, s8, s3
                  addi         t3, s4, -1925
                  c.lui        gp, 13
                  c.li         t0, -1
                  addi         a1, a3, -1833
                  addi         gp, s4, -635
                  or           s1, s2, gp
                  csrrw        s9, 0x340, s2
                  csrrc        t5, 0x340, a1
                  slt          s9, s11, s8
                  xori         s0, t6, 562
                  c.mv         s3, s9
                  mulhsu       t4, s0, a5
                  ori          tp, s1, -132
                  c.mv         s0, t1
                  add          gp, t5, s9
                  sra          t3, s11, t0
                  or           t3, t0, t5
                  srl          a4, s10, a4
                  auipc        s5, 1013382
                  lui          t1, 593768
                  slli         t0, s10, 2
                  and          tp, sp, s2
                  csrrw        s1, 0x340, zero
                  csrrw        t3, 0x340, s4
                  csrrci       zero, 0x340, 18
                  slt          s6, a0, tp
                  andi         a4, t0, -1668
                  c.or         a0, s0
                  add          a1, s5, a1
                  csrrci       s4, 0x340, 0
                  mulhu        a6, t3, t2
                  c.srai       a5, 24
                  addi         s8, t2, -24
                  mulh         tp, s2, s9
                  slt          s11, a3, t3
                  divu         t6, t3, t3
                  sra          s2, s4, s6
                  c.li         s9, -1
                  mul          t4, a2, t0
                  xor          a1, s3, s8
                  csrrci       s4, 0x340, 0
                  and          s9, s3, s7
                  mul          a4, a0, sp
                  remu         a7, s6, tp
                  csrrs        t6, 0x340, zero
                  add          a7, a7, t1
                  or           t6, s4, t0
                  c.addi       s11, -1
                  sll          s1, a0, t4
                  c.srai       s0, 5
                  mul          zero, t5, s11
                  sra          t0, ra, s10
                  csrrw        t5, 0x340, sp
                  c.add        a7, a4
                  mul          s8, t1, a2
                  sltiu        a6, a0, -1906
                  c.mv         a3, t0
                  csrrwi       a0, 0x340, 21
                  csrrw        a3, 0x340, s3
                  c.mv         t4, t4
                  mulhsu       a0, s7, t6
                  c.and        s0, a1
                  mulhu        s6, a0, t3
                  or           t2, t4, a4
                  nop
                  slli         t2, a5, 15
                  c.srai       a1, 27
                  c.srai       s0, 26
                  csrrsi       t6, 0x340, 0
                  div          s6, t0, t6
                  csrrs        t3, 0x340, a3
                  csrrw        s4, 0x340, s11
                  c.andi       a1, 30
                  andi         s1, t2, -543
                  xor          t1, t5, ra
                  c.xor        s0, s1
                  sll          a1, s9, t3
                  srl          t3, a6, s10
                  c.li         a4, -1
                  c.xor        s1, a3
                  c.or         s1, s1
                  c.li         s3, 3
                  c.add        ra, t1
                  auipc        a0, 812198
                  andi         s3, a7, 525
                  addi         s11, a5, 589
                  c.srli       a1, 2
                  sll          ra, gp, t1
                  c.nop
                  c.slli       a7, 3
                  c.add        s3, t1
                  sltiu        t1, t6, -1694
                  mul          tp, s1, t4
                  sub          s8, zero, t0
                  remu         t2, a5, zero
                  sll          a3, zero, a3
                  slt          s11, a3, s10
                  c.addi       ra, 12
                  slt          zero, tp, s7
                  csrrsi       s7, 0x340, 0
                  csrrw        s3, 0x340, s7
                  auipc        a6, 1046042
                  mulhsu       t4, s8, s1
                  sltiu        s11, s2, -1879
                  c.sub        a5, a0
                  c.sub        a3, a0
                  c.addi       s4, 18
                  add          a6, s6, s4
                  xori         ra, s1, -1315
                  c.li         t0, -1
                  lui          t3, 170467
                  c.nop
                  auipc        t4, 733133
                  csrrw        s3, 0x340, a7
                  nop
                  c.addi       t5, 31
                  c.nop
                  csrrsi       s3, 0x340, 0
                  rem          t0, a6, a6
                  csrrw        tp, 0x340, zero
                  ori          gp, gp, -1388
                  sltiu        s8, s3, -448
                  divu         a5, a3, sp
                  xori         t2, a2, 752
                  c.xor        s1, a4
                  addi         t2, a1, 1634
                  sra          s4, s7, s1
                  mulhsu       t5, t6, t5
                  mulh         s8, s11, a5
                  and          gp, a5, s5
                  csrrci       t5, 0x340, 5
                  xori         t2, t3, 1069
                  c.slli       s3, 2
                  c.nop
                  remu         t6, s0, s3
                  ori          t0, s1, -641
                  rem          s1, s1, t0
                  auipc        a6, 675903
                  slt          t0, gp, ra
                  or           s3, s8, t4
                  slli         s3, s1, 25
                  srli         tp, s7, 11
                  mulhsu       t1, t6, t2
                  c.or         a4, s1
                  sltiu        t5, s9, 210
                  c.add        s0, a5
                  csrrsi       t1, 0x340, 1
                  csrrs        s1, 0x340, t4
                  c.xor        a4, a2
                  c.mv         gp, s0
                  c.li         a3, 20
                  csrrw        s3, 0x340, a4
                  c.sub        a3, a1
                  mulh         s11, s0, s6
                  srl          a1, a5, a7
                  csrrc        ra, 0x340, t4
                  c.lui        s7, 8
                  andi         a1, t0, 1316
                  remu         a7, s5, s0
                  c.andi       s0, 27
                  nop
                  c.or         a1, a1
                  divu         t6, tp, s8
                  andi         s2, tp, 1897
                  c.li         t6, -1
                  slli         a5, a5, 27
                  c.li         s9, -1
                  auipc        s8, 357764
                  mulhu        s8, t2, s4
                  mul          s4, t5, a3
                  andi         t4, t3, 1382
                  sra          t0, ra, t4
                  c.slli       s5, 12
                  csrrci       a6, 0x340, 0
                  xori         t1, t3, 1043
                  rem          t1, s3, a7
                  mulh         t4, s1, t6
                  mulh         t2, s1, zero
                  sll          tp, tp, s2
                  andi         s6, s10, 501
                  c.addi       a7, -1
                  sltu         t5, t1, a6
                  slt          t3, a0, t0
                  sra          s11, a6, s6
                  c.li         s7, 1
                  sltu         a4, s6, a0
                  mulh         s0, sp, s10
                  or           a0, s10, a4
                  ori          ra, t0, -1105
                  c.sub        s0, s1
                  sll          a4, a4, s11
                  auipc        a0, 86666
                  c.srli       a5, 15
                  c.slli       t2, 28
                  csrrsi       a4, 0x340, 2
                  c.nop
                  csrrw        a6, 0x340, s6
                  csrrs        a7, 0x340, zero
                  slti         s1, a0, 115
                  c.add        t4, s4
                  csrrs        zero, 0x340, a7
                  c.andi       a3, 9
                  srli         s4, s9, 20
                  xor          s5, s6, tp
                  sra          s0, a7, tp
                  add          t1, a3, gp
                  mulhu        s8, gp, tp
                  srai         s4, tp, 17
                  remu         s0, s1, t6
                  c.li         a5, 7
                  c.andi       a5, 23
                  slli         a3, t4, 11
                  csrrsi       tp, 0x340, 0
                  csrrci       s5, 0x340, 2
                  c.lui        a5, 15
                  srl          ra, tp, s5
                  addi         a7, ra, 183
                  c.add        s0, a1
                  c.add        t3, s8
                  csrrw        s6, 0x340, t5
                  ori          t0, gp, 1108
                  csrrs        t5, 0x340, zero
                  div          s0, t1, a1
                  c.lui        s3, 30
                  nop
                  c.mv         t6, gp
                  csrrw        t4, 0x340, zero
                  c.add        t6, a3
                  c.addi       t5, 11
                  c.srai       s1, 3
                  csrrsi       t1, 0x340, 26
                  mulhsu       tp, s10, a7
                  c.xor        s1, s0
                  addi         s7, s4, 1639
                  c.xor        s0, s0
                  c.srli       a5, 6
                  srl          a5, a1, s7
                  nop
                  c.srli       a0, 6
                  c.add        t5, s3
                  divu         s8, t5, zero
                  c.or         s1, s1
                  csrrwi       s1, 0x340, 14
                  c.or         s0, a5
                  csrrc        a0, 0x340, zero
                  c.xor        a3, s0
                  xori         t4, t0, -1422
                  srai         t6, a4, 31
                  slt          t2, tp, s2
                  c.and        a3, a3
                  c.and        a3, a5
                  slli         a3, t3, 19
                  slli         t4, ra, 19
                  sll          t2, a0, s10
                  slli         a5, a6, 13
                  c.add        a6, s10
                  ori          a4, a1, 85
                  remu         a4, a7, ra
                  xori         a1, t5, 1704
                  csrrsi       a6, 0x340, 0
                  c.srli       a4, 3
                  div          t0, s5, s4
                  sra          a0, s5, s4
                  and          t5, a3, s0
                  c.lui        ra, 21
                  auipc        tp, 758526
                  c.addi       s1, 19
                  c.or         a4, a1
                  c.li         t2, 11
                  srai         s6, s0, 16
                  sub          t4, s7, t6
                  c.srai       a4, 11
                  c.srai       s1, 22
                  remu         a3, a7, a2
                  c.lui        a1, 15
                  c.lui        a5, 18
                  srli         a1, t1, 6
                  div          t5, t5, t5
                  csrrs        s11, 0x340, s7
                  divu         a5, a1, a6
                  c.add        a6, s10
                  mul          gp, a2, sp
                  slti         s8, gp, 1298
                  srl          s1, t0, s2
                  csrrc        t2, 0x340, zero
                  srai         s9, s11, 1
                  csrrc        s11, 0x340, zero
                  c.xor        a1, a5
                  or           tp, s0, t3
                  c.srli       a1, 15
                  remu         zero, a1, gp
                  srli         ra, t0, 11
                  sll          a6, ra, t2
                  c.srai       a5, 12
                  ori          a6, sp, 1015
                  c.addi       s9, 24
                  sltiu        s4, t6, -1486
                  csrrci       s6, 0x340, 18
                  srl          t6, t1, a0
                  sltu         t2, t2, s11
                  c.srli       a1, 3
                  add          s3, s1, s10
                  csrrsi       a5, 0x340, 0
                  c.li         s7, 9
                  srl          s6, a0, a2
                  sub          s1, a1, tp
                  srli         tp, s6, 14
                  mulhsu       a5, s10, a0
                  mul          zero, ra, s6
                  c.mv         tp, t5
                  c.lui        t5, 10
                  ori          ra, s2, -44
                  csrrci       t1, 0x340, 0
                  c.xor        s1, a2
                  lui          s8, 81635
                  mulhsu       t5, s1, gp
                  srli         s3, t4, 17
                  csrrc        ra, 0x340, s3
                  sltiu        t1, s7, -393
                  rem          t0, s7, gp
                  c.mv         a6, tp
                  c.or         s0, a3
                  c.slli       t1, 10
                  c.andi       a0, 11
                  c.li         t4, 22
                  sltiu        a0, t5, -1902
                  csrrwi       t6, 0x340, 17
                  and          s4, a1, s0
                  lui          t2, 149438
                  c.andi       a0, -1
                  auipc        s5, 759819
                  addi         s0, a6, -791
                  add          a0, tp, a3
                  div          a7, a0, t3
                  c.and        a1, a3
                  or           zero, a7, s4
                  c.xor        a4, s1
                  or           t4, t0, t2
                  srl          ra, s3, t3
                  add          t6, s2, t2
                  sltiu        s5, s9, 1785
                  nop
                  c.lui        t2, 23
                  divu         s9, a0, s1
                  slli         t5, t1, 0
                  mulh         s9, t3, s11
                  xori         gp, gp, -536
                  c.mv         t6, s8
                  slt          gp, t5, t1
                  addi         t4, s6, 1280
                  c.xor        a0, a5
                  xori         gp, s10, 1895
                  lui          s7, 140145
                  add          t0, ra, s6
                  c.li         tp, 5
                  nop
                  and          gp, a1, a1
                  c.lui        t2, 11
                  srli         a4, gp, 16
                  mul          s8, a5, t5
                  ori          a3, a0, 328
                  sub          s5, zero, a1
                  lui          t2, 857456
                  mulhu        a4, s0, s6
                  addi         s8, t2, 817
                  csrrsi       s2, 0x340, 0
                  c.sub        s1, a2
                  sub          a3, s3, a3
                  divu         t1, a7, a0
                  mulh         a1, a5, s10
                  srli         s4, s7, 14
                  rem          s7, a6, s0
                  add          t5, s5, t3
                  mul          a5, a1, s10
                  div          a6, a0, zero
                  auipc        t2, 779837
                  c.slli       t6, 31
                  and          zero, t0, s2
                  c.xor        a0, a1
                  remu         a1, s4, t1
                  c.srli       a4, 15
                  sra          s6, s10, t2
                  lui          s2, 269685
                  ori          s7, a5, 1578
                  andi         s11, t5, 1228
                  c.add        t3, tp
                  c.add        s1, s0
                  sltiu        a4, a2, -1697
                  csrrs        zero, 0x340, a3
                  or           s8, s0, a3
                  sltu         s5, s6, a0
                  c.sub        a1, a3
                  c.addi       gp, -1
                  csrrw        s8, 0x340, a7
                  andi         a4, s11, 1449
                  c.xor        a5, a1
                  c.sub        a1, s0
                  c.mv         a3, s4
                  slli         s11, t3, 13
                  c.xor        a3, a0
                  c.li         t5, 17
                  sub          a6, zero, s5
                  nop
                  xori         s7, t0, -8
                  c.addi       s1, -1
                  srli         s8, gp, 4
                  sra          a7, s2, s1
                  c.addi       a0, 30
                  c.mv         t5, t3
                  csrrci       s6, 0x340, 0
                  mul          a6, s4, gp
                  nop
                  sll          a0, s2, a1
                  sll          t1, t5, a4
                  srai         t3, s5, 1
                  mul          s4, tp, s7
                  sub          s4, s4, a1
                  csrrc        tp, 0x340, zero
                  csrrs        t0, 0x340, s2
                  sltiu        s6, a0, -50
                  mulhsu       a1, t0, ra
                  add          s11, t6, zero
                  div          t4, a7, ra
                  xori         gp, a6, -915
                  addi         a0, s2, -831
                  auipc        a7, 750584
                  c.nop
                  divu         s1, a7, s8
                  c.and        a4, a3
                  csrrc        t2, 0x340, a0
                  rem          a3, a6, s2
                  xori         s2, ra, 1519
                  slt          tp, t0, a6
                  c.addi       a0, -1
                  addi         t2, t3, -1393
                  srai         gp, tp, 12
                  c.srli       a3, 1
                  rem          ra, s5, zero
                  rem          a4, sp, a3
                  or           a7, t3, a5
                  and          s3, s7, s9
                  c.nop
                  remu         zero, t5, s4
                  xori         a0, s9, 1552
                  div          t4, a0, s3
                  csrrw        s0, 0x340, sp
                  sltu         tp, a6, a4
                  c.srli       a4, 5
                  xor          s11, s9, t5
                  csrrwi       s1, 0x340, 3
                  srai         a5, s1, 11
                  c.nop
                  srai         t5, s7, 31
                  c.srai       s0, 17
                  mulh         s2, s2, t3
                  c.slli       a4, 2
                  xori         s11, s9, -322
                  nop
                  csrrc        a0, 0x340, zero
                  xori         s0, t1, 46
                  c.andi       a4, 19
                  c.lui        t5, 30
                  auipc        zero, 916678
                  c.sub        a1, s1
                  div          a3, s11, sp
                  c.andi       a4, 4
                  srli         s8, a6, 27
                  csrrc        t3, 0x340, zero
                  c.srli       s0, 29
                  c.addi       t1, -1
                  c.or         s0, a0
                  mulhu        a0, t3, s2
                  remu         ra, t6, s10
                  c.add        s8, a7
                  sub          a4, a3, t5
                  slli         s0, s10, 15
                  mul          a6, s2, s4
                  c.or         a1, a1
                  lui          t2, 678914
                  add          a4, s4, sp
                  lui          t1, 341492
                  addi         s7, t5, -732
                  c.srai       a0, 2
                  nop
                  nop
                  c.lui        s0, 23
                  sub          t6, s11, a2
                  xori         ra, ra, -1953
                  c.slli       t4, 28
                  ori          zero, tp, 1232
                  c.mv         t3, a6
                  csrrs        a6, 0x340, zero
                  xori         s7, t6, -1164
                  csrrw        t5, 0x340, a3
                  c.andi       a3, 13
                  addi         s9, t0, 229
                  andi         s9, a6, 1175
                  sub          a7, t2, a1
                  div          tp, t4, tp
                  sltiu        a0, a2, -1814
                  srai         s5, tp, 22
                  slti         s7, s5, 889
                  div          s7, a3, gp
                  csrrwi       t3, 0x340, 30
                  srai         t6, a6, 28
                  c.sub        a1, s0
                  c.srli       s0, 7
                  c.lui        ra, 15
                  ori          s7, s3, -1275
                  xori         s3, ra, 1890
                  c.li         s9, 20
                  csrrci       s2, 0x340, 0
                  slti         s3, s6, 1342
                  csrrsi       s0, 0x340, 31
                  srli         t5, a0, 7
                  add          zero, a0, tp
                  csrrwi       s5, 0x340, 27
                  csrrwi       a0, 0x340, 7
                  c.lui        s3, 16
                  mulh         a0, a1, s0
                  c.addi       t3, -1
                  mul          t5, s5, t6
                  c.mv         ra, t0
                  ori          a0, t3, 1797
                  csrrs        s1, 0x340, zero
                  c.srli       s1, 5
                  c.or         a1, a3
                  slt          s8, a7, a5
                  sltu         a5, s7, a5
                  c.mv         a6, t5
                  c.sub        a1, a3
                  xor          a1, t5, a2
                  rem          s9, t2, t2
                  csrrsi       t1, 0x340, 0
                  csrrc        ra, 0x340, zero
                  sll          a4, gp, s8
                  csrrci       gp, 0x340, 8
                  add          s5, s1, t1
                  remu         t2, t3, t5
                  c.srli       s1, 28
                  sltu         a7, s6, t5
                  csrrs        s0, 0x340, zero
                  c.srai       a5, 9
                  auipc        a4, 121104
                  c.or         s0, a5
                  c.and        a4, a2
                  c.and        s0, s1
                  or           s0, a4, t1
                  csrrc        a7, 0x340, t5
                  remu         s1, t6, ra
                  c.slli       t6, 12
                  add          t6, s5, a3
                  sub          s6, t4, a3
                  remu         gp, a0, a0
                  sltiu        s9, s2, -1147
                  mulhsu       a3, s8, t3
                  srl          s2, s8, s4
                  csrrwi       a7, 0x340, 4
                  c.mv         a3, s11
                  slt          t2, t4, a0
                  divu         s0, s0, tp
                  c.add        s8, s5
                  c.nop
                  sltu         a3, s0, t6
                  c.srai       a4, 7
                  csrrc        a4, 0x340, s2
                  mul          t2, s3, ra
                  c.andi       s0, 24
                  andi         s7, s3, 1920
                  mulhu        a5, t5, ra
                  c.andi       a1, 31
                  mulhsu       s4, s6, s5
                  c.srli       s0, 9
                  csrrci       t0, 0x340, 0
                  addi         s3, s3, 1068
                  slti         s5, s9, -216
                  mulhsu       s8, s1, ra
                  divu         a3, t5, s11
                  add          s8, s5, a2
                  mulh         s3, s2, s2
                  c.li         a1, -1
                  divu         s1, a0, s9
                  c.mv         t2, a6
                  mulhsu       s6, t1, s3
                  addi         a5, t0, -1264
                  sra          gp, t6, a1
                  and          s5, a7, gp
                  remu         a6, a7, s1
                  rem          t4, s7, t1
                  srai         a6, gp, 31
                  and          a7, a5, zero
                  lui          t6, 298126
                  c.lui        a0, 1
                  mulh         a5, s3, s0
                  c.lui        s0, 9
                  andi         s4, a6, -476
                  slli         gp, s11, 16
                  sltu         t0, t3, t5
                  mul          s3, t2, t2
                  mulh         a7, s8, gp
                  sll          a3, a6, t2
                  auipc        s11, 271983
                  addi         s6, t1, -1299
                  c.slli       t4, 6
                  csrrc        a0, 0x340, s10
                  c.and        a4, a0
                  csrrsi       s1, 0x340, 0
                  c.srli       a1, 18
                  c.lui        t5, 4
                  c.lui        t3, 7
                  csrrs        s3, 0x340, zero
                  mulh         s6, t4, s0
                  addi         t5, a2, 1009
                  xori         a4, a1, -1113
                  div          t0, t3, s7
                  srl          a3, t6, s5
                  c.mv         a3, s10
                  srai         s11, t4, 24
                  mulhsu       a6, ra, s10
                  sll          t6, a2, t6
                  xori         s1, s9, 692
                  c.lui        ra, 7
                  sub          a5, ra, s5
                  add          a1, t2, s11
                  c.andi       a5, -1
                  csrrwi       a0, 0x340, 27
                  nop
                  c.srai       a1, 16
                  mulhu        gp, a1, s2
                  divu         t3, sp, t3
                  c.sub        a5, a5
                  xor          a0, t2, s10
                  slt          s1, t0, a0
                  sltu         s9, s5, s11
                  c.add        a0, a7
                  srli         ra, t2, 13
                  xor          t6, a6, s0
                  csrrci       s1, 0x340, 27
                  sltiu        a1, a3, 1911
                  andi         zero, s6, 432
                  divu         t1, a2, s9
                  nop
                  sltu         s8, a4, sp
                  mulhsu       s5, s0, t5
                  ori          a0, s2, -1510
                  srli         s1, sp, 15
                  divu         s7, a3, t0
                  slli         s11, s3, 4
                  rem          t5, t1, a3
                  andi         t1, gp, -1736
                  c.nop
                  divu         s5, s8, sp
                  div          s11, s2, s2
                  c.slli       a5, 7
                  auipc        s7, 183862
                  rem          s2, s7, a7
                  c.andi       a0, 31
                  csrrci       s9, 0x340, 0
                  slti         t4, s9, 742
                  c.addi       t4, -1
                  divu         s5, t1, tp
                  c.sub        s0, a0
                  sub          a5, s0, s7
                  divu         a0, s7, s6
                  csrrc        a3, 0x340, s11
                  divu         s1, a7, t5
                  sltiu        a4, s3, -1188
                  csrrc        s5, 0x340, s5
                  sltiu        s5, a1, 1796
                  mulhu        t5, s8, a4
                  mulhu        a6, s6, sp
                  csrrw        s3, 0x340, s11
                  addi         t6, s7, 1408
                  csrrw        s7, 0x340, s1
                  c.or         a1, a5
                  rem          a4, gp, a5
                  lui          a3, 917380
                  c.add        t4, a1
                  sltiu        a6, t6, -1565
                  xori         t3, s5, -617
                  rem          t2, a0, gp
                  mul          a3, s11, t5
                  slli         s6, a0, 8
                  or           a6, a1, s6
                  srl          a7, a6, gp
                  mulhsu       t6, a0, a3
                  slli         a7, s4, 2
                  ori          a6, s5, -1974
                  csrrc        a6, 0x340, s11
                  c.and        a4, a0
                  slli         s5, gp, 14
                  slli         t0, sp, 28
                  csrrw        a4, 0x340, t1
                  c.lui        s4, 30
                  c.or         a3, s1
                  c.addi       s1, 10
                  csrrc        a6, 0x340, a3
                  add          a1, s0, s7
                  remu         t6, a1, s0
                  c.sub        a4, a0
                  c.or         a1, a3
                  nop
                  sub          s4, s2, s2
                  c.sub        s0, a3
                  srli         a4, a7, 1
                  sltiu        s8, tp, -975
                  srai         zero, s10, 25
                  c.sub        a3, a1
                  lui          a3, 222290
                  and          t2, s0, a7
                  c.addi       t3, 27
                  c.mv         t3, s5
                  csrrc        a0, 0x340, zero
                  srai         t4, s7, 5
                  slt          s5, t4, a5
                  mulh         s7, s11, a0
                  csrrci       t6, 0x340, 16
                  mul          s8, sp, sp
                  xori         gp, a4, -1676
                  slt          a1, t0, a1
                  c.or         a3, a3
                  c.slli       gp, 24
                  andi         s0, a2, 1619
                  mulhu        t4, s8, s4
                  xor          s2, t4, s3
                  div          t3, t6, t4
                  c.srai       a4, 16
                  sltu         a5, a5, t0
                  mulhsu       t3, s0, t3
                  andi         a7, s9, -1270
                  c.addi       t0, -1
                  sra          t0, zero, a1
                  c.and        s0, a5
                  rem          ra, sp, s6
                  c.li         gp, 17
                  addi         s6, zero, -268
                  divu         a6, s6, a4
                  slli         tp, a0, 31
                  sra          tp, a6, s6
                  andi         s11, zero, 1627
                  xori         s8, t1, -1352
                  or           s3, t0, s7
                  lui          tp, 212620
                  and          a1, tp, s10
                  c.srli       a4, 4
                  srai         t0, gp, 30
                  c.slli       a7, 21
                  csrrs        a4, 0x340, zero
                  c.add        s1, a4
                  sltiu        s7, ra, 1990
                  mulh         s1, s0, t2
                  c.srli       a4, 29
                  c.and        a3, a2
                  rem          t3, s0, s7
                  csrrw        s1, 0x340, sp
                  and          a5, a1, s0
                  c.srli       s1, 11
                  c.srli       a1, 29
                  c.addi       s3, -1
                  addi         t6, gp, -1773
                  auipc        t4, 517228
                  csrrs        a6, 0x340, s5
                  sltiu        t4, s11, 1788
                  mulh         s2, sp, s9
                  csrrw        s5, 0x340, s7
                  srl          s9, a7, s3
                  mul          t5, s4, t2
                  csrrci       tp, 0x340, 0
                  rem          s3, a6, t1
                  csrrs        a3, 0x340, zero
                  sltu         s4, s3, a4
                  c.nop
                  c.addi       s2, -1
                  andi         a3, t3, 1827
                  nop
                  srli         s1, s11, 22
                  c.xor        a0, a3
                  csrrc        s0, 0x340, s2
                  sltiu        t5, a1, -1185
                  mulhu        t3, s7, zero
                  xori         s1, t0, -2042
                  c.slli       t0, 13
                  csrrw        t5, 0x340, s11
                  csrrwi       a1, 0x340, 29
                  xor          ra, a3, a4
                  srl          tp, a5, a6
                  c.and        a4, a0
                  ori          s9, s8, 150
                  c.or         a4, a2
                  c.or         a0, s1
                  auipc        tp, 136636
                  c.mv         gp, a3
                  c.li         t4, 16
                  csrrc        t3, 0x340, t4
                  lui          s11, 518204
                  c.nop
                  c.or         s0, s0
                  csrrsi       s0, 0x340, 17
                  c.lui        gp, 20
                  remu         s2, gp, s3
                  srai         t4, a5, 30
                  c.add        t4, t1
                  c.or         s0, a1
                  mulhu        a3, t2, a7
                  c.add        a6, t3
                  c.addi       s3, -1
                  c.sub        a4, a5
                  c.nop
                  csrrw        s8, 0x340, s4
                  xori         s5, s11, 1672
                  c.add        s7, a2
                  csrrsi       t5, 0x340, 17
                  c.srli       a5, 9
                  xori         s9, ra, 2039
                  mul          s0, gp, a5
                  add          a1, s8, s10
                  div          a3, t3, t1
                  sll          s1, s5, ra
                  c.sub        a1, a4
                  sra          s7, a3, s4
                  c.and        a4, a0
                  csrrc        tp, 0x340, s6
                  remu         s7, tp, a3
                  csrrsi       s6, 0x340, 0
                  mulhu        s1, t5, s5
                  c.nop
                  slli         t1, s10, 30
                  addi         s2, s11, -1218
                  add          a0, a1, t1
                  nop
                  slti         zero, s9, -972
                  srl          s5, s6, a3
                  csrrwi       a3, 0x340, 16
                  c.nop
                  c.sub        a4, a4
                  srai         a1, s7, 3
                  mulhsu       tp, gp, a3
                  c.srai       a5, 7
                  c.add        t2, a5
                  sltu         tp, a0, a1
                  slti         a5, s7, 11
                  ori          s1, a6, 1422
                  addi         s5, s8, -145
                  c.or         a4, s1
                  ori          tp, a4, -1237
                  c.addi       tp, -1
                  csrrci       a5, 0x340, 0
                  c.li         s9, 16
                  c.srli       a5, 10
                  xor          s4, a1, s7
                  c.nop
                  c.li         a7, -1
                  xor          t6, t6, s0
                  c.and        s1, a2
                  c.sub        a1, a4
                  mulhsu       s3, a4, a5
                  srai         s9, t3, 23
                  auipc        t3, 205760
                  divu         s8, a6, a1
                  and          t1, s5, a7
                  sra          a7, a6, t3
                  sltu         a7, tp, s6
                  slti         s2, t4, -1351
                  csrrci       gp, 0x340, 2
                  c.slli       s1, 24
                  xori         s8, sp, -574
                  sltiu        t0, a5, 999
                  nop
                  csrrci       a6, 0x340, 0
                  or           t5, t6, a7
                  csrrs        a3, 0x340, zero
                  srai         a7, s3, 15
                  srai         t5, ra, 17
                  csrrc        t0, 0x340, zero
                  c.srli       a3, 6
                  xori         a0, s3, -1191
                  add          a0, a2, sp
                  slli         a0, t0, 13
                  c.and        a3, a4
                  auipc        t2, 178165
                  c.srai       a5, 1
                  slli         s6, t5, 8
                  divu         s3, t0, s3
                  rem          t1, s0, s6
                  c.addi       t3, 22
                  c.mv         s0, s6
                  c.andi       a1, -1
                  mulh         a7, s11, t2
                  mul          gp, t6, a1
                  sra          t3, sp, s5
                  ori          a3, s5, -836
                  srli         s3, tp, 15
                  c.xor        s1, s0
                  c.li         gp, -1
                  sltu         s11, zero, a7
                  and          a0, s3, s3
                  c.andi       a1, 31
                  c.mv         s3, gp
                  c.andi       s1, -1
                  c.srai       a1, 25
                  csrrci       s7, 0x340, 20
                  mulhsu       ra, s8, t1
                  rem          a3, a6, a2
                  srai         s5, t0, 15
                  lui          a4, 905081
                  slli         s1, a2, 29
                  sll          s3, s3, s8
                  xor          s7, a6, s4
                  csrrs        gp, 0x340, a6
                  c.srli       a1, 5
                  srli         s9, gp, 24
                  csrrsi       zero, 0x340, 13
                  mul          tp, s8, s1
                  csrrc        t1, 0x340, s3
                  sub          s1, t5, a4
                  sltiu        s5, a4, 933
                  add          s8, t6, t3
                  c.sub        a5, a2
                  auipc        s5, 975264
                  mulhsu       tp, t6, zero
                  slli         s9, sp, 18
                  c.and        s0, s0
                  c.sub        a0, a0
                  andi         a4, a6, 1025
                  c.or         a1, a4
                  srl          s2, s7, t5
                  csrrw        a0, 0x340, s9
                  csrrci       s1, 0x340, 0
                  c.andi       a4, 18
                  c.srai       a1, 5
                  csrrwi       s5, 0x340, 14
                  csrrci       s2, 0x340, 25
                  nop
                  auipc        a1, 34417
                  xori         s3, a0, -1283
                  sll          s7, gp, a2
                  ori          s0, a2, -1436
                  csrrwi       zero, 0x340, 29
                  add          t3, gp, a7
                  c.or         a5, s0
                  csrrc        s6, 0x340, gp
                  c.li         s3, 20
                  remu         t5, s2, s5
                  csrrsi       a3, 0x340, 11
                  xori         gp, a2, 1257
                  csrrsi       t5, 0x340, 22
                  andi         t0, s7, 1142
                  srl          gp, s3, a5
                  or           a0, s10, s9
                  slli         a5, s6, 5
                  remu         s7, tp, a3
                  rem          s1, a5, t4
                  sra          gp, s10, zero
                  csrrwi       a5, 0x340, 26
                  slli         s0, s3, 12
                  sub          s4, t5, tp
                  c.or         a0, s0
                  andi         s5, s9, 2000
                  addi         s3, a6, 1587
                  csrrci       s9, 0x340, 12
                  remu         a3, s11, s5
                  slti         s0, a7, -713
                  divu         s0, a4, zero
                  srai         t0, a1, 16
                  c.addi       t4, -1
                  divu         a4, t4, s10
                  rem          s5, a6, zero
                  csrrci       s2, 0x340, 8
                  csrrwi       a0, 0x340, 25
                  sll          t5, ra, a6
                  csrrs        s8, 0x340, a6
                  c.lui        s11, 18
                  csrrw        s6, 0x340, a5
                  andi         s5, s1, 1153
                  c.andi       a1, -1
                  c.srli       s1, 9
                  sra          t6, s9, s1
                  c.mv         s3, t6
                  srli         zero, a1, 21
                  sltu         s2, a0, t5
                  addi         t4, ra, 1133
                  andi         s0, a1, 208
                  c.mv         s11, s0
                  slli         a5, a2, 10
                  c.lui        s6, 24
                  xori         zero, s10, -1051
                  mulhsu       s8, ra, s8
                  slt          a5, a6, s2
                  c.addi       t6, 20
                  csrrw        tp, 0x340, gp
                  c.srai       a4, 15
                  c.and        a0, a1
                  c.andi       a5, -1
                  slti         t6, s3, 1208
                  csrrc        t0, 0x340, zero
                  csrrsi       t4, 0x340, 0
                  and          t1, a3, s8
                  srl          t5, sp, t0
                  mulhsu       t4, tp, a4
                  csrrs        s1, 0x340, zero
                  sltu         t4, a4, ra
                  c.andi       a5, -1
                  andi         t5, s7, -1754
                  sltiu        s2, sp, -190
                  sub          t1, t1, s10
                  sra          s1, a3, t4
                  mulh         s0, s10, a2
                  c.addi       a5, -1
                  divu         t2, t4, s9
                  sltiu        a0, s3, -1896
                  divu         gp, s5, a7
                  slli         s11, sp, 27
                  ori          s0, s9, 1458
                  sra          a0, ra, s11
                  remu         tp, gp, s10
                  xori         t6, ra, -1853
                  mulh         t2, s6, s9
                  srai         t5, a1, 11
                  xori         gp, a4, -1609
                  mulhsu       s6, s8, a7
                  sub          tp, tp, s7
                  sltu         s7, t4, t0
                  c.mv         s11, t2
                  c.li         a4, 22
                  csrrci       a1, 0x340, 0
                  csrrsi       t5, 0x340, 23
                  sltiu        t3, s0, 714
                  ori          t2, t5, -1948
                  srli         tp, s9, 24
                  sub          a5, s11, zero
                  c.or         a5, a0
                  ori          t0, s3, 618
                  andi         a4, tp, -1621
                  remu         tp, ra, a4
                  c.li         a3, -1
                  divu         a5, a4, t5
                  rem          a7, sp, s2
                  xori         gp, t6, 1363
                  lui          t4, 782432
                  c.add        t0, gp
                  c.li         s8, -1
                  sra          s7, s9, s9
                  div          a1, t1, a0
                  rem          gp, zero, t3
                  srai         s11, s7, 22
                  xori         t5, s10, 259
                  c.slli       a6, 19
                  c.li         a3, 23
                  c.srli       a5, 19
                  sub          s8, t3, a1
                  c.andi       a5, -1
                  div          a5, tp, a1
                  mulhsu       a1, s5, t4
                  divu         t0, a4, sp
                  c.srai       a4, 2
                  slti         t4, s8, 1958
                  c.nop
                  csrrc        s6, 0x340, zero
                  c.and        a0, a2
                  srai         s5, a0, 21
                  csrrw        a7, 0x340, a3
                  addi         ra, s5, -1058
                  csrrsi       a4, 0x340, 0
                  c.nop
                  remu         a7, s11, t4
                  c.srli       a5, 4
                  csrrs        s0, 0x340, t6
                  addi         t3, s9, 1159
                  c.add        t1, t2
                  c.or         a5, s1
                  c.addi       t0, -1
                  andi         s8, a5, 993
                  c.lui        a0, 20
                  addi         t3, s8, 1774
                  csrrc        t6, 0x340, s0
                  nop
                  c.sub        a3, a5
                  csrrw        a5, 0x340, gp
                  sltiu        t2, s6, 1540
                  csrrc        t2, 0x340, zero
                  lui          a0, 876508
                  auipc        a6, 427183
                  mul          a7, a0, s5
                  auipc        t5, 552780
                  c.xor        s1, a2
                  rem          t2, gp, a0
                  c.or         a1, a5
                  mulh         s0, tp, t6
                  mulhu        t3, s10, zero
                  sra          t5, s8, a2
                  mulhsu       tp, s6, t5
                  c.sub        a1, a4
                  slt          a4, t6, s6
                  auipc        s1, 396642
                  sltu         tp, s7, s4
                  sltu         s4, s4, t6
                  c.slli       s8, 26
                  remu         t6, s10, a1
                  sltiu        a4, tp, 2004
                  c.xor        a0, a4
                  and          s0, s10, s1
                  c.slli       a3, 8
                  c.addi       a1, 14
                  sll          a0, s1, s0
                  c.srai       a0, 22
                  sltiu        t4, a7, -1359
                  or           a7, a6, gp
                  srli         s11, s6, 4
                  csrrs        t0, 0x340, zero
                  c.lui        s0, 18
                  mul          a6, a5, s11
                  sltiu        t2, s6, 1334
                  mulhu        a7, sp, s9
                  sltiu        s7, s8, 1268
                  srai         a6, a0, 18
                  c.or         a4, s1
                  sltu         a3, s5, s4
                  c.li         s8, 7
                  divu         s4, gp, s0
                  srli         t0, t5, 9
                  csrrw        t6, 0x340, s6
                  csrrc        a4, 0x340, t3
                  andi         tp, s10, -440
                  ori          t0, zero, 890
                  sra          s9, t3, s9
                  c.li         s0, 9
                  c.srli       a5, 22
                  csrrsi       zero, 0x340, 0
                  csrrs        ra, 0x340, zero
                  sra          s9, a5, s4
                  c.mv         s4, s9
                  c.srai       s0, 16
                  csrrs        a5, 0x340, zero
                  mulh         a5, s4, a3
                  csrrci       t0, 0x340, 5
                  csrrs        s5, 0x340, zero
                  add          t1, a5, ra
                  addi         t6, s2, 2033
                  div          s0, a1, s11
                  divu         t2, t0, a4
                  csrrwi       t0, 0x340, 20
                  c.lui        a0, 20
                  sll          t4, s8, t6
                  srli         t1, s2, 17
                  addi         t2, s0, 1649
                  rem          t6, s6, gp
                  c.mv         a1, ra
                  mul          s5, t6, a4
                  sub          tp, t0, t6
                  sub          t0, a7, t5
                  ori          s4, gp, 1966
                  slli         s5, zero, 30
                  rem          s4, s3, t3
                  andi         s2, a4, 1754
                  or           a7, s9, t3
                  remu         t3, zero, t4
                  mulh         s5, t1, s4
                  c.srai       a1, 29
                  rem          a1, ra, t6
                  c.srai       s0, 1
                  lui          tp, 1027117
                  srl          s2, s1, s5
                  srai         ra, s9, 13
                  sll          s3, s0, s3
                  andi         s6, s6, -1190
                  sra          a3, s9, sp
                  divu         a1, a1, t1
                  addi         t5, zero, -1120
                  sub          s0, s5, ra
                  c.and        s0, a1
                  c.xor        s1, a4
                  addi         t2, s6, 201
                  srl          s1, t0, t6
                  c.and        a3, s1
                  srli         t5, a4, 1
                  csrrci       a3, 0x340, 7
                  lui          s2, 168385
                  sra          s9, a1, a3
                  csrrwi       t3, 0x340, 21
                  c.sub        a0, a2
                  csrrci       zero, 0x340, 0
                  sltu         s6, ra, s11
                  mulhu        a3, a6, a1
                  csrrw        s4, 0x340, t5
                  c.andi       s1, -1
                  xori         s6, s5, -1116
                  csrrs        gp, 0x340, s3
                  srai         zero, a6, 7
                  xori         gp, s4, -1968
                  srl          s9, a5, a6
                  ori          zero, s8, 907
                  c.lui        ra, 3
                  auipc        t4, 492878
                  rem          a3, ra, t3
                  div          a0, s9, t1
                  mulhsu       t5, a4, s5
                  c.sub        a0, s1
                  rem          ra, s4, a7
                  c.srli       a5, 15
                  rem          ra, s7, s7
                  c.srai       a1, 11
                  sltu         a1, gp, a5
                  sll          s3, a5, t2
                  slli         s4, sp, 24
                  mulh         a4, t4, s1
                  or           s2, a5, s8
                  slli         t6, a2, 9
                  sll          t4, a0, s1
                  mul          zero, gp, s0
                  slt          t4, s6, ra
                  csrrs        s9, 0x340, zero
                  nop
                  srli         a3, gp, 2
                  c.or         a3, a3
                  lui          a4, 411676
                  slti         t1, t5, 2039
                  sra          a4, a2, t5
                  mulh         s2, s11, gp
                  csrrwi       a0, 0x340, 21
                  auipc        t4, 7822
                  slli         s11, s4, 25
                  c.mv         a4, t5
                  ori          s0, a0, 1802
                  xori         s3, a4, -1364
                  mulh         t6, sp, s4
                  csrrw        s11, 0x340, sp
                  xori         t0, a4, 443
                  srl          s1, s3, ra
                  sra          t6, t2, a4
                  c.addi       s2, 26
                  c.and        s1, s1
                  srl          t5, s11, a6
                  c.sub        s1, a4
                  c.srai       a0, 9
                  c.mv         ra, a7
                  auipc        a3, 663897
                  xori         a7, a7, 1138
                  c.and        a4, a5
                  sltiu        s4, s8, 817
                  c.srli       a5, 19
                  andi         s3, s10, 1852
                  c.sub        a4, a5
                  c.lui        s1, 2
                  c.andi       s0, -1
                  sra          t6, t3, s11
                  xori         t6, a3, -191
                  sltu         a0, s9, s7
                  mul          t3, s6, s0
                  nop
                  slti         s5, a5, -1
                  addi         s7, a6, -1561
                  c.sub        s0, a0
                  mulhu        t5, s10, s11
                  c.nop
                  c.andi       a5, -1
                  srai         s7, tp, 7
                  xor          t0, a5, s9
                  csrrsi       t0, 0x340, 2
                  mulhu        s4, a7, s8
                  c.li         gp, 23
                  div          s9, s6, gp
                  div          a0, a2, t5
                  sltiu        t6, s5, -1666
                  sltiu        s1, gp, 1306
                  xor          s1, ra, s2
                  sltiu        s6, s9, -622
                  csrrc        s9, 0x340, t2
                  c.li         t4, 26
                  mul          t0, s0, s3
                  auipc        zero, 912492
                  c.addi       s4, 9
                  divu         t6, t5, t3
                  slli         s11, s6, 15
                  sra          s2, tp, s2
                  c.sub        s0, s0
                  c.andi       a1, -1
                  c.slli       s0, 11
                  c.li         s5, -1
                  c.sub        a0, a5
                  srli         s4, a6, 10
                  c.li         a4, -1
                  c.add        t5, a2
                  nop
                  div          t2, a0, sp
                  c.and        a5, a4
                  c.sub        a1, a4
                  mul          t6, s11, s3
                  csrrc        t5, 0x340, zero
                  csrrwi       t2, 0x340, 19
                  c.xor        a3, a3
                  xor          t1, s11, sp
                  c.add        t2, a0
                  mulh         t3, t6, s6
                  c.slli       ra, 17
                  csrrsi       s11, 0x340, 0
                  sub          s4, a7, s9
                  c.xor        a4, a1
                  or           tp, s11, s3
                  csrrwi       s0, 0x340, 31
                  mulhu        t3, t4, t2
                  xor          s8, s1, s2
                  csrrci       t6, 0x340, 0
                  rem          a7, t0, s9
                  mulhu        ra, t0, t1
                  mulhsu       a3, zero, t5
                  slti         tp, s4, -443
                  c.sub        a4, a3
                  or           a4, t1, zero
                  csrrc        a1, 0x340, s2
                  c.and        a4, s1
                  csrrsi       s3, 0x340, 0
                  divu         t6, t3, t4
                  c.nop
                  slti         s8, a2, -1317
                  and          t3, s11, t1
                  csrrs        a1, 0x340, zero
                  sra          zero, s7, zero
                  csrrs        s7, 0x340, s8
                  c.lui        a7, 29
                  c.lui        t5, 21
                  c.andi       a3, -1
                  addi         s11, tp, -314
                  c.or         a5, a1
                  andi         t2, s8, 1696
                  c.srai       a1, 11
                  andi         s7, tp, -1038
                  slli         a4, s6, 28
                  slti         a5, s8, 1381
                  c.xor        s0, a4
                  slt          a7, t4, a2
                  c.or         a3, s1
                  sltiu        s6, s5, 827
                  csrrsi       s6, 0x340, 9
                  sub          a1, a3, s2
                  sra          a3, a3, s11
                  c.srai       a3, 27
                  sra          t4, s7, t2
                  mulh         t1, a6, gp
                  csrrw        gp, 0x340, sp
                  c.lui        s3, 29
                  addi         s9, s8, -551
                  csrrc        a3, 0x340, zero
                  c.slli       s1, 12
                  srai         t4, zero, 8
                  xori         s2, a4, -1815
                  addi         ra, s10, -1182
                  c.srai       s1, 13
                  div          a1, t2, s6
                  addi         s4, t6, -1755
                  srai         s0, s0, 1
                  csrrci       s7, 0x340, 9
                  c.li         t4, 25
                  auipc        t4, 449362
                  xor          a1, ra, s4
                  rem          t0, a3, s9
                  mulhu        a5, tp, a0
                  sub          s2, s9, s11
                  c.srli       a0, 17
                  c.nop
                  c.li         t3, -1
                  csrrs        a4, 0x340, t1
                  c.add        s1, s11
                  c.srli       s0, 5
                  sltu         ra, t4, s1
                  add          s9, t5, a3
                  c.or         a1, s0
                  csrrci       s5, 0x340, 0
                  c.nop
                  csrrc        tp, 0x340, zero
                  srl          ra, a2, a3
                  xor          a0, ra, t4
                  csrrw        a0, 0x340, gp
                  c.srli       a4, 4
                  slli         s5, s8, 22
                  c.or         s0, a4
                  andi         t5, a4, -806
                  slti         s1, s3, 641
                  slti         t6, t5, -1390
                  c.lui        s1, 1
                  c.xor        a1, a1
                  c.sub        a4, a3
                  or           t2, s9, a1
                  mulhsu       s9, t3, t0
                  srl          a6, s9, s1
                  slti         a5, s5, 1343
                  mulhsu       gp, t2, ra
                  c.mv         ra, s10
                  xor          s11, a2, t1
                  slli         tp, tp, 7
                  csrrw        gp, 0x340, a4
                  mulhu        gp, s10, s3
                  csrrci       zero, 0x340, 13
                  sll          s2, s2, s0
                  xori         s2, t4, -105
                  srli         t3, s2, 15
                  c.addi       tp, 4
                  csrrw        s1, 0x340, t5
                  rem          a3, s1, ra
                  csrrwi       a6, 0x340, 28
                  csrrci       t0, 0x340, 0
                  and          t0, a0, t6
                  csrrw        a1, 0x340, a4
                  sll          ra, sp, t6
                  add          t4, s10, t0
                  mulhu        zero, s0, t6
                  or           a6, ra, a5
                  sltiu        ra, a1, -434
                  xor          a1, zero, s1
                  c.xor        a0, a2
                  mulhsu       zero, gp, gp
                  div          s7, a0, s3
                  c.srli       a5, 9
                  c.addi       a1, 26
                  csrrwi       s6, 0x340, 16
                  slti         t1, zero, 296
                  slti         a1, a6, 587
                  or           s8, t3, t2
                  c.mv         t0, t4
                  srli         s7, a4, 0
                  addi         s3, s7, 964
                  remu         s2, a2, s11
                  c.mv         s2, s1
                  c.li         s9, 16
                  lui          a6, 454854
                  mulhu        t0, t0, s0
                  srli         s11, sp, 9
                  addi         tp, s2, -1151
                  rem          s11, t5, t2
                  ori          s7, tp, -898
                  csrrs        a1, 0x340, s3
                  or           s11, a2, tp
                  c.andi       s1, -1
                  ori          s4, s0, 1105
                  mulhu        t6, t5, s5
                  slti         zero, a7, 1648
                  or           a5, t0, s10
                  c.srli       a4, 30
                  slli         s9, s11, 16
                  c.sub        a1, a5
                  c.lui        a1, 15
                  mulh         tp, s11, t0
                  addi         a6, s2, -1693
                  c.sub        a5, s0
                  c.nop
                  c.add        s8, t1
                  csrrc        a5, 0x340, zero
                  mulhu        gp, t0, a0
                  c.andi       a4, 7
                  c.or         a1, a4
                  xori         s11, t6, -1427
                  auipc        a0, 204490
                  srli         a6, t0, 1
                  div          gp, s3, a7
                  addi         a0, t4, -670
                  c.srai       s1, 12
                  addi         a7, s8, -1008
                  csrrw        a5, 0x340, a7
                  or           s5, tp, t4
                  slt          t6, t5, s5
                  lui          tp, 236941
                  c.sub        s0, a1
                  lui          t0, 577062
                  c.li         a7, -1
                  mul          ra, a1, a6
                  nop
                  srai         s2, a4, 7
                  slli         t3, s0, 13
                  mul          a1, s6, t3
                  slt          a7, gp, t0
                  sll          gp, s2, s0
                  sub          ra, a1, gp
                  xor          a5, ra, ra
                  mulhsu       s8, t4, s0
                  nop
                  c.li         a6, 11
                  csrrsi       s5, 0x340, 0
                  mul          s11, a3, a7
                  andi         gp, t2, -334
                  c.slli       s3, 26
                  csrrwi       a1, 0x340, 28
                  csrrc        t5, 0x340, zero
                  andi         t2, a3, -1868
                  csrrci       s2, 0x340, 0
                  c.slli       a7, 28
                  srai         t1, s6, 22
                  divu         s2, tp, t2
                  c.li         t5, 27
                  mulh         s2, s2, t2
                  lui          t2, 35694
                  xor          s11, a2, a5
                  auipc        t0, 663442
                  csrrc        s2, 0x340, zero
                  c.xor        a3, a0
                  slti         s9, s10, 1849
                  csrrw        gp, 0x340, ra
                  c.addi       t6, 8
                  div          zero, a7, a7
                  mulh         t1, s0, t3
                  divu         s8, sp, a0
                  rem          s5, a3, a1
                  c.nop
                  c.addi       ra, 9
                  and          a7, t3, zero
                  c.andi       a1, 30
                  or           t5, s0, s5
                  srli         s8, t0, 22
                  sll          gp, t2, a7
                  c.and        a3, a1
                  c.and        s0, s0
                  ori          s9, s1, -176
                  csrrsi       t6, 0x340, 0
                  remu         s3, s7, t0
                  c.slli       a4, 31
                  or           a0, s7, a5
                  mulh         s6, a1, s2
                  csrrwi       s9, 0x340, 26
                  slt          gp, s10, a0
                  sll          s7, a6, s8
                  and          s4, s11, gp
                  c.addi       t2, 22
                  csrrs        t5, 0x340, t1
                  sltiu        s11, sp, 840
                  srai         zero, zero, 14
                  sra          ra, a7, s6
                  srai         t4, s4, 14
                  csrrs        zero, 0x340, zero
                  lui          t1, 723822
                  remu         s1, t5, s7
                  slt          t2, t3, a3
                  c.nop
                  c.li         a1, -1
                  addi         t3, t0, 1825
                  c.slli       a6, 30
                  srli         t5, a3, 7
                  csrrwi       t4, 0x340, 29
                  csrrs        s6, 0x340, a0
                  c.addi       s5, 23
                  mulhsu       tp, s6, t0
                  mulh         s8, t0, gp
                  c.srli       a3, 25
                  sub          s8, t0, s0
                  mulhu        s11, s3, s11
                  srai         a6, a5, 23
                  mulhu        a0, a6, tp
                  xor          ra, s8, tp
                  sltiu        a1, t5, -978
                  c.xor        a1, a5
                  srai         a7, s2, 29
                  c.srai       s1, 6
                  c.mv         s9, s1
                  srl          a0, s6, t0
                  remu         s4, a1, s2
                  divu         t3, t5, tp
                  add          gp, s0, s4
                  or           t6, t5, sp
                  c.sub        s0, a2
                  mulhsu       s11, a1, t3
                  csrrsi       s4, 0x340, 13
                  lui          t3, 255877
                  csrrc        s7, 0x340, zero
                  c.li         a6, 18
                  addi         a4, s9, 685
                  sltu         t2, s6, a2
                  c.add        t2, s5
                  div          s7, a7, s3
                  c.sub        a3, s1
                  srl          t4, t5, a5
                  c.addi       t6, -1
                  c.srai       a3, 19
                  c.xor        s0, a1
                  csrrc        s0, 0x340, t6
                  or           s11, s3, tp
                  mulhu        t1, s0, s8
                  sub          a7, s10, a3
                  sub          a6, t3, a3
                  csrrw        a6, 0x340, sp
                  nop
                  c.xor        a0, a1
                  lui          tp, 160712
                  csrrsi       t6, 0x340, 15
                  divu         s7, s7, t4
                  divu         s1, gp, s3
                  c.addi       t1, -1
                  lui          tp, 800600
                  c.addi       a3, -1
                  div          s5, s10, sp
                  csrrwi       s8, 0x340, 3
                  sll          a7, s8, s10
                  xori         a3, s7, -1962
                  c.srai       a0, 7
                  c.and        a4, a0
                  mulhsu       a4, s7, zero
                  c.addi       a3, -1
                  c.addi       s7, 18
                  csrrci       t4, 0x340, 0
                  sltiu        zero, t0, 1061
                  c.srai       a3, 16
                  c.sub        a4, a0
                  slti         t3, t2, -118
                  srl          zero, s10, a7
                  slti         a1, s7, 209
                  slti         s4, t6, 693
                  srai         t0, s8, 3
                  c.andi       s1, -1
                  slti         t5, gp, -756
                  c.or         a4, s1
                  c.srli       a3, 20
                  sltiu        a7, a0, -1795
                  slli         a3, s11, 12
                  csrrsi       s4, 0x340, 24
                  c.mv         a7, s4
                  c.srli       s0, 17
                  c.srli       a3, 9
                  mulhu        a5, s4, s3
                  csrrs        ra, 0x340, zero
                  rem          s7, t5, s7
                  c.addi       a0, 26
                  c.mv         tp, s8
                  c.srai       a3, 2
                  sltu         a1, t2, t1
                  srai         a4, a4, 28
                  rem          a4, a5, a7
                  sltiu        t5, a5, 807
                  nop
                  nop
                  or           a0, s11, s11
                  and          s9, gp, t1
                  remu         a4, t3, s1
                  mul          s2, a1, gp
                  c.lui        gp, 12
                  c.addi       a1, 19
                  csrrs        t1, 0x340, zero
                  sub          s9, t4, s0
                  sra          s11, s2, t2
                  andi         s6, s2, 854
                  c.sub        a3, a0
                  div          s6, s8, t5
                  sll          t3, s11, s7
                  c.srai       a1, 1
                  csrrc        s0, 0x340, zero
                  c.and        s1, a5
                  csrrwi       t3, 0x340, 9
                  xori         t0, t2, -1707
                  mulh         s3, s0, s10
                  xori         gp, a7, 951
                  sll          s4, s6, s6
                  csrrw        t2, 0x340, s5
                  add          a1, a4, t6
                  csrrsi       a3, 0x340, 0
                  mulhsu       t0, a7, a1
                  csrrsi       t1, 0x340, 0
                  sltiu        t2, t4, 544
                  c.srli       s1, 21
                  csrrw        s2, 0x340, t1
                  addi         s5, t2, 561
                  lui          s1, 336917
                  c.sub        a0, a4
                  mulhsu       s1, sp, s6
                  sra          tp, s8, a3
                  slli         s2, a7, 19
                  divu         s2, t3, t1
                  c.mv         s8, s0
                  csrrsi       s0, 0x340, 0
                  remu         tp, a5, ra
                  and          gp, zero, s10
                  andi         a4, s4, 549
                  lui          s1, 58827
                  slti         a4, t5, 254
                  csrrsi       a7, 0x340, 29
                  csrrci       a5, 0x340, 30
                  sub          s11, tp, t1
                  mul          s4, a5, t2
                  rem          s2, s2, a1
                  xor          s6, a5, s3
                  divu         a0, s8, a5
                  csrrc        s8, 0x340, zero
                  csrrs        s11, 0x340, s4
                  divu         s0, t4, a2
                  c.andi       a1, -1
                  mulh         a3, t6, a2
                  and          t6, t0, s7
                  csrrwi       ra, 0x340, 5
                  slli         s5, s3, 10
                  c.srai       a5, 15
                  slti         s11, s4, -78
                  srai         t0, s9, 2
                  c.nop
                  sra          s4, s8, t6
                  lui          t0, 1022021
                  and          t1, t4, s10
                  c.add        a6, tp
                  c.mv         s8, a4
                  mulhu        t3, s7, a7
                  auipc        s6, 291260
                  remu         s11, a5, t6
                  sra          s0, s2, s6
                  c.add        a1, s10
                  auipc        t3, 724181
                  c.nop
                  mulhsu       ra, t2, gp
                  c.andi       a5, 4
                  c.addi       s0, 2
                  csrrc        a0, 0x340, zero
                  csrrci       s2, 0x340, 0
                  sltiu        t2, t4, 1178
                  srli         a5, zero, 12
                  c.srli       a5, 14
                  c.nop
                  ori          s6, t6, -1647
                  c.andi       a4, 29
                  and          s9, t0, s3
                  lui          t4, 196525
                  sltiu        s1, a5, 214
                  add          t2, s1, s5
                  mul          s11, a1, s6
                  csrrs        t1, 0x340, a1
                  c.sub        s0, a3
                  divu         tp, gp, s2
                  c.or         a3, a1
                  c.lui        t1, 5
                  sra          s4, t4, a2
                  c.andi       a5, -1
                  mulhu        t2, s10, t3
                  sltu         s11, t5, s0
                  sltiu        s5, t3, 1337
                  nop
                  c.nop
                  c.or         a0, a0
                  srai         s11, t6, 11
                  csrrw        zero, 0x340, t3
                  c.li         s6, 31
                  slt          t5, tp, s10
                  sll          s4, a7, sp
                  sub          t3, s3, t3
                  srl          s8, a1, a3
                  addi         t3, t2, 1745
                  c.slli       t0, 19
                  lui          gp, 431638
                  c.and        a5, s0
                  c.xor        a3, s0
                  c.xor        a5, a1
                  csrrs        a1, 0x340, zero
                  srl          s6, t5, s6
                  c.sub        a4, a4
                  or           a0, a0, a2
                  c.srai       a0, 24
                  lui          s5, 78458
                  mulh         a3, gp, s9
                  slti         a4, a5, 1104
                  csrrwi       t6, 0x340, 15
                  c.andi       a4, 0
                  auipc        tp, 158060
                  slli         t2, a5, 26
                  xor          a1, sp, tp
                  slli         zero, a3, 7
                  divu         s8, ra, t1
                  sltiu        tp, gp, -213
                  srl          s7, s2, t4
                  c.add        t6, a4
                  divu         s7, a0, a2
                  lui          t2, 283506
                  c.srai       s0, 30
                  c.sub        a3, s0
                  sub          s3, s10, s9
                  sltiu        s9, t0, 1743
                  mulhu        s9, s11, s0
                  mulhu        t2, t1, s4
                  ori          ra, t2, 1146
                  c.slli       s5, 5
                  csrrsi       s4, 0x340, 0
                  csrrc        a5, 0x340, s6
                  mulhsu       s5, zero, ra
                  csrrw        a4, 0x340, s2
                  c.sub        a0, s0
                  divu         a3, s8, s2
                  c.slli       t1, 14
                  c.lui        t2, 19
                  auipc        s4, 656623
                  or           t1, a1, t5
                  mulh         t1, a7, a2
                  ori          t6, s9, -766
                  sltu         s5, a3, a6
                  sll          a6, s6, tp
                  auipc        a6, 604530
                  mul          gp, t3, t1
                  or           a1, t0, a5
                  slli         s9, a7, 20
                  csrrs        a0, 0x340, s4
                  add          a5, gp, zero
                  c.xor        a4, a1
                  c.and        a1, a4
                  csrrwi       s7, 0x340, 13
                  c.or         a3, a1
                  srai         a4, a6, 21
                  slti         s7, t2, 798
                  mul          tp, s0, t3
                  c.srai       s1, 19
                  csrrc        t6, 0x340, zero
                  c.li         tp, 27
                  c.xor        a3, a0
                  c.nop
                  addi         t6, zero, 715
                  div          s7, s7, a1
                  c.or         a5, a3
                  andi         s7, s1, 1621
                  csrrs        a5, 0x340, zero
                  xori         a5, s7, -176
                  mulhsu       s4, t2, s0
                  or           a1, t5, tp
                  and          s1, t5, a5
                  mulhu        t3, a5, t5
                  c.nop
                  csrrs        zero, 0x340, zero
                  mulhu        a6, a6, s7
                  c.mv         t6, s7
                  c.add        gp, s4
                  xori         a0, t5, -1425
                  srai         a6, s6, 2
                  or           s3, s10, t6
                  andi         t4, t6, -1193
                  csrrw        ra, 0x340, a6
                  sltiu        s8, ra, -957
                  c.nop
                  c.xor        a1, s0
                  andi         gp, gp, 1417
                  sltu         s11, a5, s7
                  csrrsi       t4, 0x340, 0
                  xor          a3, a1, s6
                  sll          ra, a1, t4
                  addi         t0, a4, -1395
                  xor          a0, s3, a1
                  c.add        s7, s9
                  c.li         a7, 5
                  addi         s7, s2, 692
                  csrrs        t6, 0x340, zero
                  c.li         s7, -1
                  divu         a7, sp, s9
                  xor          ra, a2, tp
                  slt          t2, s4, t2
                  srai         a0, s7, 9
                  srai         s7, s0, 18
                  andi         t3, s8, 1485
                  srai         t4, s11, 18
                  andi         zero, t4, -1120
                  and          s7, s6, s9
                  div          s9, s0, t0
                  c.srai       a4, 1
                  c.add        s11, s10
                  c.slli       a1, 10
                  sltu         s11, ra, s7
                  mulhsu       a5, s10, a1
                  andi         a1, a1, -1044
                  remu         t3, a2, tp
                  div          a5, a1, t4
                  xori         s9, a7, -1158
                  andi         t5, s5, -52
                  c.and        a5, a1
                  c.lui        t6, 11
                  sll          a0, ra, a6
                  xor          s3, a5, a7
                  srli         t1, gp, 25
                  srli         a5, a1, 23
                  mulhsu       a1, a0, t2
                  slt          t2, a0, a4
                  and          s1, tp, s4
                  sll          s2, s8, a2
                  xori         s1, a5, 1503
                  c.addi       s8, -1
                  sll          t4, s6, t6
                  slt          a4, a6, s6
                  c.lui        a6, 31
                  c.add        t0, gp
                  csrrs        t6, 0x340, zero
                  xori         s5, s9, -1238
                  sll          a5, a1, ra
                  xori         ra, s6, 240
                  nop
                  c.sub        a5, a1
                  rem          a7, a4, zero
                  sltiu        s6, a4, -1910
                  c.and        a5, s1
                  c.lui        t2, 16
                  c.add        t3, t2
                  div          s6, t4, zero
                  div          ra, s0, s10
                  remu         t4, tp, sp
                  c.add        a7, s6
                  or           t6, t6, a5
                  andi         s7, a4, 619
                  c.lui        s11, 12
                  divu         t0, t6, t2
                  csrrw        t2, 0x340, gp
                  srai         a0, t4, 26
                  mul          s9, t3, a3
                  xori         ra, ra, -14
                  c.slli       s6, 11
                  sra          t1, a4, t0
                  c.addi       s2, -1
                  ori          t4, a7, -1805
                  c.mv         a4, t1
                  andi         s1, zero, -573
                  slt          gp, a4, s11
                  slt          t0, s7, t5
                  sub          s9, t0, a1
                  mulh         a1, t2, zero
                  csrrc        a5, 0x340, sp
                  lui          t1, 941314
                  andi         a4, s8, 861
                  c.xor        s1, a2
                  div          t2, t4, a3
                  c.li         t6, -1
                  sra          t2, a2, s8
                  mul          s5, s2, t5
                  c.addi       t5, 15
                  c.xor        a3, s0
                  c.sub        a4, a2
                  slli         s9, t4, 16
                  c.slli       a4, 11
                  c.nop
                  sll          t6, a0, t3
                  sub          a3, a6, a3
                  slt          ra, a6, s0
                  addi         gp, tp, 1683
                  c.and        a3, a3
                  remu         s2, s5, s2
                  srli         t6, a3, 6
                  or           s7, tp, s3
                  auipc        s4, 786802
                  srli         s6, t3, 9
                  ori          s1, s9, 396
                  rem          a7, s2, t5
                  c.andi       s0, 24
                  sll          a0, t3, t6
                  mulhu        a4, ra, t0
                  c.sub        a4, a1
                  ori          a3, tp, -1790
                  csrrci       a6, 0x340, 18
                  add          s4, t4, s5
                  csrrwi       a0, 0x340, 12
                  mul          a6, a2, a2
                  addi         s0, s7, -1335
                  mulh         s5, s4, t5
                  csrrsi       s3, 0x340, 13
                  mul          s11, s10, t6
                  csrrs        s1, 0x340, t6
                  sll          t0, s0, s10
                  lui          gp, 905766
                  srai         t5, tp, 30
                  mul          s9, t0, a6
                  remu         s8, s9, a5
                  sll          t1, a1, s2
                  c.nop
                  addi         s1, a1, -544
                  c.addi       s0, 1
                  c.xor        a1, s1
                  mulhsu       s9, s2, a6
                  sltiu        s0, t0, 985
                  c.addi       a1, -1
                  csrrci       s11, 0x340, 0
                  c.srai       a4, 10
                  rem          s9, ra, s3
                  c.xor        s0, a5
                  c.or         a1, a0
                  c.and        a0, a3
                  and          gp, s4, s5
                  ori          t0, s1, -981
                  csrrs        a4, 0x340, zero
                  csrrci       t4, 0x340, 0
                  addi         a3, s2, -1782
                  c.addi       ra, 30
                  c.xor        s1, a3
                  add          s6, a6, t2
                  xori         t3, t0, 998
                  addi         zero, s7, 294
                  c.addi       s2, 30
                  c.andi       s1, -1
                  sub          s2, t5, t2
                  slt          s0, s2, t2
                  c.lui        t4, 1
                  nop
                  csrrs        s2, 0x340, zero
                  srl          a3, t3, a6
                  xori         s8, s1, -1576
                  mulhu        t5, a3, s4
                  slt          s2, gp, s3
                  mulh         t5, s3, s7
                  xor          s3, s10, t3
                  c.mv         s8, s11
                  c.sub        a1, a4
                  mulh         s9, s1, sp
                  xori         ra, a5, -1904
                  sll          s2, s7, a0
                  div          ra, t3, s7
                  csrrs        gp, 0x340, zero
                  c.and        a3, s1
                  c.and        a0, a5
                  c.sub        a5, a0
                  c.and        a0, s1
                  srl          ra, s1, t4
                  csrrsi       zero, 0x340, 0
                  remu         gp, s5, t6
                  c.nop
                  csrrs        s9, 0x340, t6
                  srl          s7, t1, s4
                  mulh         a0, a0, s3
                  csrrc        s0, 0x340, s2
                  div          a7, t0, s9
                  c.and        a1, a1
                  sra          a6, a6, s3
                  csrrci       zero, 0x340, 21
                  sub          s9, a5, t5
                  csrrwi       s0, 0x340, 9
                  sll          t4, s11, t3
                  slt          s1, t3, t1
                  divu         t6, s10, s8
                  add          s4, a6, t5
                  c.add        s7, a2
                  c.add        a0, s10
                  csrrw        a6, 0x340, s1
                  sll          zero, t0, s3
                  srli         zero, a3, 9
                  mulhu        s6, s6, gp
                  rem          t6, t6, t0
                  sltiu        a4, a1, 1446
                  div          s2, s2, t1
                  c.xor        a1, s0
                  csrrwi       a6, 0x340, 13
                  or           a4, t1, s7
                  slti         a7, a3, -1602
                  csrrw        s11, 0x340, s5
                  xori         t3, a1, 353
                  c.li         a1, 1
                  c.srai       a5, 2
                  or           s11, s8, s7
                  mul          s3, t4, s10
                  c.lui        s9, 24
                  srli         t6, a4, 12
                  c.lui        ra, 18
                  c.andi       a1, 10
                  c.srli       s1, 4
                  srli         s5, s2, 31
                  slt          s1, s1, s1
                  mul          s2, a3, t5
                  slti         a6, a2, 728
                  c.nop
                  addi         s1, a2, 1666
                  c.li         a4, 4
                  c.add        a7, a4
                  mulhu        s3, t4, ra
                  c.and        a3, a0
                  c.sub        a1, a1
                  c.srai       a1, 18
                  c.sub        a3, s0
                  c.lui        s6, 19
                  ori          s1, s4, 1797
                  xor          a6, gp, t2
                  c.srai       a0, 5
                  c.sub        s0, a1
                  sll          t6, a3, s8
                  csrrci       t0, 0x340, 0
                  nop
                  csrrci       s0, 0x340, 0
                  csrrsi       s4, 0x340, 12
                  c.slli       t2, 14
                  c.or         s0, s1
                  mulhu        gp, t3, a1
                  c.slli       s1, 11
                  csrrw        a7, 0x340, s0
                  c.mv         t5, a2
                  c.lui        ra, 6
                  c.nop
                  ori          t1, s5, 1914
                  csrrs        s0, 0x340, s3
                  csrrci       t3, 0x340, 20
                  sub          a6, a2, a4
                  c.srli       a3, 6
                  srl          t4, t1, a7
                  c.li         t2, 29
                  c.slli       t3, 30
                  xor          s3, s10, s2
                  c.mv         s3, s1
                  c.nop
                  ori          s9, s7, -411
                  c.andi       a4, -1
                  ori          t1, s6, 958
                  sub          a6, t6, s2
                  csrrw        t4, 0x340, sp
                  ori          s4, gp, -845
                  sub          s3, t3, s3
                  sltu         a7, s1, s5
                  srai         s3, s7, 20
                  sub          s3, t3, a2
                  csrrw        ra, 0x340, a2
                  xor          s2, s11, s10
                  slt          s8, a0, s10
                  c.sub        a4, a5
                  div          t4, gp, a7
                  c.or         a0, a1
                  sltiu        a1, s3, 430
                  c.and        s1, s0
                  mul          s5, s0, s10
                  c.li         t2, -1
                  c.nop
                  nop
                  csrrwi       ra, 0x340, 20
                  srli         tp, a0, 24
                  c.add        s1, s3
                  c.mv         t1, s7
                  mulhsu       t1, s5, a0
                  slli         a4, sp, 9
                  c.or         a1, a0
                  sra          t3, t0, t3
                  add          a0, s9, s2
                  c.andi       s1, 31
                  remu         s2, t6, t1
                  csrrwi       a0, 0x340, 14
                  andi         s1, s11, 84
                  c.sub        a3, s0
                  c.srai       s1, 7
                  csrrsi       a6, 0x340, 0
                  sra          tp, a2, a1
                  sltu         ra, a0, s1
                  sltiu        a0, t6, 723
                  add          s8, s10, s4
                  nop
                  xor          s0, t0, gp
                  csrrw        s4, 0x340, s6
                  divu         ra, t2, s10
                  nop
                  sra          t4, a2, zero
                  c.mv         s4, t1
                  addi         t0, s7, -1966
                  c.srai       a1, 2
                  srai         t2, sp, 11
                  c.xor        a4, a2
                  c.slli       s2, 6
                  c.and        a1, s1
                  c.add        a5, s0
                  c.lui        a3, 22
                  sltu         s11, s7, s9
                  xor          a4, s4, t6
                  sub          zero, s3, a6
                  srl          t4, t2, a3
                  and          t6, t1, zero
                  add          s3, a2, t1
                  c.or         a4, a5
                  slt          t1, zero, a2
                  sltiu        a1, a6, -1143
                  c.lui        s2, 21
                  csrrs        t2, 0x340, zero
                  c.slli       a5, 15
                  sra          t6, s6, t5
                  c.addi       s3, -1
                  sll          ra, a5, a3
                  c.srai       a3, 2
                  mul          t0, s8, s11
                  srli         s9, a1, 13
                  lui          t5, 209495
                  c.slli       s5, 13
                  mulhsu       a7, t2, a6
                  c.and        a3, a2
                  div          ra, s6, s6
                  remu         s4, a4, a2
                  slli         gp, gp, 3
                  nop
                  xor          t2, s8, t2
                  xori         t1, s9, 1480
                  csrrc        t6, 0x340, zero
                  csrrci       a1, 0x340, 0
                  lui          s3, 401710
                  c.mv         s3, a4
                  c.and        s0, s1
                  c.srai       a4, 19
                  c.lui        t3, 25
                  mul          a1, s7, a7
                  srl          t6, t0, t6
                  rem          ra, a3, t5
                  sltiu        ra, gp, 1365
                  mulhsu       t1, t6, s11
                  sltu         a0, zero, s7
                  c.lui        a0, 21
                  csrrw        a6, 0x340, zero
                  c.mv         a3, t6
                  slt          a0, s10, s9
                  c.xor        a1, a0
                  c.addi       a0, -1
                  andi         t1, a6, 73
                  c.and        a0, a5
                  sub          s2, s11, s11
                  rem          t3, s10, t2
                  c.li         s3, 8
                  c.slli       gp, 29
                  srl          s5, s9, s9
                  c.lui        s2, 26
                  srli         a1, t0, 13
                  csrrsi       t2, 0x340, 11
                  andi         a7, a0, -1297
                  c.nop
                  mul          a7, s3, a7
                  slt          a6, a7, s1
                  slli         s5, tp, 10
                  sll          s0, t1, s10
                  c.andi       a0, 25
                  csrrw        a4, 0x340, t6
                  or           s7, tp, s4
                  slt          s6, a3, s5
                  csrrsi       t0, 0x340, 0
                  and          s9, s7, sp
                  mulhsu       s5, s9, a5
                  mulh         s5, s1, gp
                  mulhu        s3, a1, t5
                  srli         a0, t5, 28
                  csrrwi       t4, 0x340, 24
                  c.srai       a3, 28
                  c.and        s1, a0
                  slt          a7, t2, s2
                  c.sub        a3, a1
                  mulhu        s11, t1, t6
                  slti         t3, s9, -163
                  c.mv         a0, a2
                  mulhsu       a1, tp, s10
                  mul          zero, s5, s10
                  c.lui        s2, 5
                  c.andi       a1, -1
                  srli         s6, t5, 27
                  c.xor        s1, s1
                  slli         t4, s11, 23
                  div          s0, tp, s2
                  csrrwi       t3, 0x340, 12
                  c.xor        a4, s0
                  divu         a4, ra, s11
                  sll          a4, a7, a1
                  c.or         a4, a2
                  addi         s2, a0, -134
                  csrrs        s3, 0x340, a1
                  csrrw        s1, 0x340, s1
                  srli         s2, s2, 19
                  c.addi       tp, -1
                  sll          t3, a6, a6
                  sll          t3, s1, s5
                  or           t5, s4, a4
                  srl          t0, a5, s1
                  c.li         t0, -1
                  c.nop
                  xori         a6, s1, 317
                  csrrci       s9, 0x340, 20
                  srli         zero, sp, 24
                  slli         s11, s10, 29
                  sll          a1, s0, gp
                  sub          gp, t3, zero
                  divu         a7, a1, s6
                  c.sub        a5, a3
                  c.mv         tp, sp
                  mulhsu       t5, a1, a5
                  srl          s2, a6, a7
                  add          a7, t1, s5
                  c.srli       a3, 7
                  slti         s4, a0, -1283
                  c.andi       a0, 7
                  sltu         s7, t5, zero
                  remu         zero, t5, a2
                  rem          s4, t6, a2
                  addi         zero, t3, 1197
                  or           a0, zero, a6
                  csrrci       t3, 0x340, 31
                  c.sub        a3, a5
                  csrrw        t4, 0x340, s0
                  sll          s6, t1, a4
                  sra          t6, s11, tp
                  c.sub        a3, a0
                  c.mv         s11, a5
                  sra          a6, t2, s1
                  xori         t6, a3, -484
                  c.and        a5, s0
                  mulhsu       t6, gp, s2
                  c.sub        a1, a1
                  rem          a3, t2, t3
                  csrrw        t0, 0x340, s7
                  sll          a3, gp, s10
                  slli         s2, s0, 2
                  add          s0, zero, t1
                  csrrc        t6, 0x340, zero
                  or           s7, a7, gp
                  c.andi       a4, -1
                  srli         a1, zero, 4
                  divu         a5, t4, s5
                  c.xor        a3, s0
                  csrrwi       t0, 0x340, 0
                  lui          zero, 104936
                  srai         t2, t1, 25
                  srl          zero, a6, zero
                  xori         zero, gp, 1477
                  srl          s3, a2, s11
                  csrrs        t6, 0x340, a0
                  c.srai       a5, 31
                  or           a0, t2, ra
                  csrrc        a6, 0x340, s9
                  c.slli       s5, 6
                  csrrsi       gp, 0x340, 6
                  csrrsi       t1, 0x340, 9
                  c.addi       t5, 10
                  mulh         s9, a6, t0
                  sltu         s3, ra, sp
                  mulhsu       s2, a6, gp
                  and          a5, s7, zero
                  c.sub        a3, a5
                  c.srai       s1, 4
                  srl          s8, t5, s9
                  mul          t0, s1, s1
                  c.xor        a1, a1
                  auipc        t2, 536404
                  csrrwi       a7, 0x340, 0
                  c.sub        a3, a1
                  srl          t2, s2, a7
                  mulh         s1, s2, s9
                  srli         s7, t6, 4
                  c.lui        a3, 1
                  add          gp, t1, t5
                  c.srai       s0, 12
                  c.srli       a3, 19
                  c.sub        a0, s0
                  sltu         t2, zero, s2
                  c.add        t1, sp
                  csrrc        tp, 0x340, gp
                  sub          s0, a4, s7
                  srai         tp, a7, 31
                  sll          s1, t4, a3
                  c.sub        a1, s0
                  srli         a4, s2, 20
                  add          t0, zero, s10
                  c.and        s0, a1
                  sltiu        s7, s2, 1975
                  xor          a6, s2, s10
                  csrrc        t0, 0x340, a1
                  srl          t6, t4, s1
                  sltu         t1, s3, tp
                  add          s4, t5, s0
                  auipc        t3, 931704
                  c.xor        a4, a3
                  xor          t6, t6, s2
                  add          t4, t0, t3
                  sll          t2, gp, s3
                  mul          s4, a4, s6
                  div          s0, s4, s11
                  nop
                  srl          s11, s0, s4
                  and          s9, s10, a1
                  sltiu        t4, a3, 182
                  csrrci       t6, 0x340, 3
                  add          s3, s2, s11
                  mulh         zero, s0, t5
                  csrrwi       t3, 0x340, 25
                  c.srai       s1, 6
                  c.srai       a0, 4
                  c.xor        a3, s0
                  mul          t6, s8, sp
                  csrrw        gp, 0x340, tp
                  mul          a3, tp, a7
                  sltiu        s0, s11, 1494
                  c.nop
                  c.sub        s0, s1
                  rem          t0, a7, s2
                  div          t3, t3, s11
                  csrrw        s6, 0x340, a5
                  auipc        gp, 879675
                  lui          a3, 274858
                  and          s5, s6, s2
                  xor          s11, a7, a5
                  lui          a5, 73938
                  csrrsi       a1, 0x340, 15
                  auipc        a5, 230612
                  rem          s7, a0, s11
                  mulh         tp, t2, a7
                  c.add        t6, t5
                  andi         t5, a6, 1634
                  csrrs        s1, 0x340, tp
                  c.nop
                  csrrsi       t3, 0x340, 11
                  c.andi       a1, -1
                  or           t5, a1, gp
                  c.xor        a3, a1
                  add          t0, gp, t1
                  xori         zero, s1, 791
                  c.srli       s0, 18
                  mulhsu       t4, t5, s9
                  mulh         a4, tp, s1
                  c.mv         s11, t6
                  auipc        gp, 853987
                  nop
                  c.addi       t5, 26
                  srli         a0, t0, 21
                  srai         t1, a1, 3
                  c.and        a0, a2
                  csrrci       s2, 0x340, 0
                  c.srai       a3, 14
                  sltiu        s6, s0, 119
                  c.addi       gp, -1
                  csrrsi       tp, 0x340, 24
                  c.or         a4, a1
                  mulhu        t3, t4, s1
                  xor          s11, tp, a1
                  c.srai       a4, 1
                  sltu         s2, s6, tp
                  c.addi       ra, -1
                  c.srli       a4, 4
                  csrrci       s3, 0x340, 0
                  c.srli       a1, 25
                  csrrsi       s5, 0x340, 0
                  sltiu        s8, s8, -189
                  slti         s1, tp, 1217
                  csrrs        s8, 0x340, ra
                  divu         t1, s4, s4
                  srli         a3, s3, 16
                  or           s2, t5, t4
                  c.li         tp, 11
                  slli         a4, a5, 1
                  c.srli       s1, 13
                  srl          s4, a0, s4
                  nop
                  divu         s2, s4, a5
                  c.or         s1, s0
                  mulhu        s8, zero, s7
                  sltu         s11, tp, zero
                  sra          t6, s11, t0
                  c.li         t4, 2
                  sra          s4, s6, gp
                  nop
                  c.slli       t2, 21
                  sra          t0, t0, s7
                  remu         t1, t1, a1
                  c.sub        a4, a5
                  sltu         s8, gp, s4
                  csrrsi       t5, 0x340, 0
                  csrrs        t4, 0x340, t6
                  ori          s7, s10, 1916
                  sltiu        s6, s1, -1242
                  slli         a1, s10, 25
                  rem          s3, s2, s2
                  nop
                  slt          t2, s11, sp
                  rem          s11, s10, a2
                  csrrw        a5, 0x340, t1
                  c.xor        a1, s1
                  c.srli       s0, 14
                  and          t2, t4, t4
                  sll          a1, a0, s4
                  csrrsi       a5, 0x340, 30
                  nop
                  c.or         s1, a4
                  c.lui        s11, 9
                  c.andi       a1, 10
                  and          a1, a2, a5
                  sltu         s3, t4, s4
                  andi         s3, s1, 629
                  andi         s0, zero, -1195
                  c.add        s8, sp
                  xor          ra, a1, t6
                  andi         a4, s2, 766
                  c.sub        s0, a3
                  ori          tp, t1, -1480
                  sltu         a6, s9, s10
                  rem          a6, s11, a0
                  srai         s5, s7, 15
                  ori          s9, zero, 572
                  rem          t6, sp, s8
                  addi         t2, s9, -1331
                  addi         s6, t2, 886
                  c.addi       a0, 20
                  xori         s8, s4, 212
                  and          a7, s4, s10
                  addi         s0, s8, -825
                  c.sub        s1, a4
                  c.srai       a1, 23
                  auipc        a0, 68213
                  div          s2, t2, gp
                  c.addi       ra, 22
                  sll          a4, t6, s6
                  sltiu        t3, a1, 472
                  sra          s11, t4, a3
                  c.and        a1, a1
                  c.srli       a3, 21
                  sra          t1, t6, s2
                  srl          s1, s9, s3
                  mulhu        t4, s0, s9
                  c.li         s5, -1
                  sra          s9, ra, s5
                  and          s8, s1, t0
                  srai         s5, a1, 4
                  c.xor        a4, a1
                  add          t3, t6, a7
                  c.xor        a4, a5
                  add          a7, zero, a5
                  c.srai       a3, 8
                  xor          a4, t2, s9
                  c.li         a1, 12
                  mulhsu       a3, t6, s3
                  c.srli       s1, 25
                  add          s6, tp, s3
                  lui          zero, 30724
                  csrrsi       s0, 0x340, 0
                  c.nop
                  c.xor        s1, a2
                  div          a7, t4, t2
                  c.add        s9, a5
                  c.nop
                  c.li         s4, 25
                  c.srli       a5, 30
                  csrrs        s6, 0x340, zero
                  c.srli       s1, 19
                  c.xor        a0, a0
                  c.add        s2, a1
                  auipc        tp, 310351
                  remu         zero, a3, a6
                  mul          t0, s6, ra
                  slt          t1, zero, s11
                  csrrsi       t6, 0x340, 0
                  csrrs        a6, 0x340, zero
                  lui          tp, 1026865
                  xori         s2, t6, -851
                  c.lui        s3, 30
                  add          zero, a3, s2
                  lui          s3, 925259
                  c.lui        gp, 28
                  c.li         a6, 9
                  slti         s5, t3, 747
                  csrrs        s6, 0x340, a5
                  mulh         s3, s10, s8
                  and          s6, s1, a4
                  mulhu        a1, s10, ra
                  slli         t2, t6, 10
                  csrrw        a0, 0x340, s3
                  c.andi       a5, -1
                  csrrw        a7, 0x340, t1
                  remu         ra, a2, a6
                  c.mv         s2, a0
                  c.srli       a5, 26
                  srai         t3, t0, 5
                  ori          s11, t3, 1884
                  div          s0, s7, zero
                  rem          s7, s1, s1
                  div          gp, s9, s6
                  divu         gp, s2, s8
                  csrrci       a0, 0x340, 0
                  nop
                  slti         t6, s11, -1277
                  addi         s7, s10, 1480
                  c.sub        a3, a4
                  sra          t5, s10, s9
                  c.lui        a6, 2
                  remu         s2, ra, t5
                  addi         s11, a4, 572
                  csrrs        t0, 0x340, zero
                  c.li         s0, 27
                  xor          tp, tp, s4
                  c.srai       a1, 31
                  csrrci       s2, 0x340, 0
                  remu         s7, a2, zero
                  c.srli       a4, 3
                  sltu         s8, sp, tp
                  srai         s2, a0, 27
                  csrrci       s0, 0x340, 18
                  sub          s0, t4, sp
                  xor          a1, s10, s1
                  slti         a3, s0, 410
                  addi         t4, t2, 526
                  slti         t4, a4, -1813
                  sll          s9, t3, t1
                  c.srli       s1, 31
                  sltiu        s3, a5, -1343
                  sltu         t4, t2, zero
                  rem          t1, a7, a7
                  andi         a4, a5, 1321
                  c.lui        t4, 25
                  mul          s5, t0, a4
                  c.add        a5, s11
                  c.mv         t0, a0
                  c.mv         a0, s11
                  c.srli       s1, 20
                  c.sub        a1, a4
                  csrrc        a6, 0x340, zero
                  csrrc        s9, 0x340, zero
                  or           a7, a0, s11
                  csrrs        t0, 0x340, zero
                  c.or         a3, s0
                  c.sub        a4, a1
                  c.and        s0, a5
                  remu         a7, t4, t4
                  srl          s1, a3, a3
                  c.slli       t6, 2
                  c.add        a7, a1
                  xori         t0, a4, 2
                  c.and        a4, a5
                  or           s5, zero, s11
                  slli         s7, s4, 3
                  c.or         a1, a1
                  c.and        s0, a4
                  c.sub        a4, a1
                  sll          zero, s5, s8
                  remu         gp, a0, a7
                  c.srli       a1, 30
                  mul          a0, s5, a0
                  srai         s0, a2, 6
                  rem          s0, s0, s1
                  rem          s1, s10, sp
                  c.or         a5, s1
                  c.lui        t1, 17
                  csrrc        ra, 0x340, zero
                  lui          s11, 861416
                  sra          a3, gp, t1
                  c.sub        s1, a3
                  c.mv         s0, s3
                  sll          a0, s0, a2
                  csrrwi       s4, 0x340, 28
                  sltu         a6, t3, a1
                  csrrc        t4, 0x340, zero
                  c.srai       s0, 28
                  c.andi       s1, -1
                  c.add        s2, t1
                  c.mv         s9, t0
                  c.nop
                  c.lui        t1, 22
                  csrrwi       t5, 0x340, 13
                  srli         s5, s9, 29
                  c.slli       s3, 20
                  c.sub        s0, s1
                  slt          gp, zero, a3
                  rem          s0, a4, gp
                  c.and        a4, a1
                  csrrs        a1, 0x340, t3
                  addi         a4, a4, -507
                  c.add        s5, a3
                  mulhsu       a6, a4, s10
                  csrrw        gp, 0x340, s7
                  srai         s9, t3, 12
                  csrrc        a4, 0x340, s11
                  sll          t2, s4, t0
                  andi         s7, t4, 34
                  c.srai       a3, 14
                  srai         s7, zero, 31
                  csrrwi       s11, 0x340, 17
                  slt          a6, t0, tp
                  c.addi       s9, 28
                  rem          ra, s6, s6
                  c.or         a0, a2
                  srl          t5, a7, t0
                  div          s2, s0, tp
                  c.srli       a3, 14
                  rem          s4, t4, s10
                  c.sub        a3, a1
                  div          t2, t1, t2
                  csrrw        t0, 0x340, s1
                  c.nop
                  c.addi       t5, -1
                  csrrci       a6, 0x340, 4
                  srai         a7, s6, 10
                  csrrwi       gp, 0x340, 6
                  c.addi       gp, 18
                  slli         t6, t3, 27
                  c.add        t5, s9
                  sll          s8, a6, s1
                  c.sub        a4, s1
                  srli         t5, a1, 30
                  c.andi       a3, -1
                  mul          ra, a7, a1
                  slti         s7, a6, -1022
                  sltu         zero, a4, a6
                  srai         t6, a1, 10
                  sll          t6, s4, gp
                  srli         s5, s7, 24
                  c.sub        a0, s1
                  c.li         a1, -1
                  csrrs        s7, 0x340, s0
                  srai         a4, sp, 21
                  c.nop
                  c.addi       a0, -1
                  c.mv         s4, t6
                  csrrci       s8, 0x340, 13
                  xori         a6, s11, -1075
                  add          t5, a3, s9
                  slti         s2, s2, -1392
                  c.andi       a5, 26
                  csrrwi       tp, 0x340, 28
                  slli         tp, t1, 21
                  csrrc        s2, 0x340, zero
                  sra          t5, s9, zero
                  c.srli       s1, 26
                  rem          s9, sp, t6
                  slli         a7, a6, 20
                  c.slli       t3, 14
                  ori          a0, a0, 1167
                  nop
                  csrrw        s6, 0x340, tp
                  mulhsu       a4, tp, t6
                  c.lui        t4, 29
                  remu         t5, t2, t0
                  c.li         s6, -1
                  add          s5, a1, a7
                  c.srai       s1, 22
                  c.nop
                  div          a6, a3, s6
                  c.lui        a0, 26
                  c.xor        s0, a4
                  c.srli       s0, 31
                  srl          s9, t3, t5
                  divu         s3, t5, a6
                  c.add        a0, s8
                  slti         a7, s5, 1328
                  lui          t2, 259324
                  c.or         a4, s1
                  slti         t6, ra, 142
                  mulhu        a7, s11, s11
                  csrrwi       s11, 0x340, 17
                  and          s7, t2, sp
                  csrrw        t5, 0x340, a0
                  csrrsi       s0, 0x340, 16
                  csrrs        s11, 0x340, zero
                  div          a5, tp, s6
                  sll          t6, sp, s10
                  c.slli       s2, 27
                  sra          a5, s4, s8
                  add          gp, t5, a5
                  remu         ra, t6, t6
                  and          t1, s8, a1
                  c.slli       a7, 3
                  slli         a4, sp, 29
                  sub          t2, s11, s10
                  c.srli       a3, 31
                  c.add        a5, a7
                  srli         a6, tp, 24
                  slli         zero, a4, 12
                  sra          s9, s1, s4
                  sra          ra, s0, s7
                  add          s7, s6, a7
                  slli         zero, s10, 26
                  xor          s0, s4, a6
                  slt          s2, a5, a0
                  c.srli       a4, 4
                  c.srai       s1, 26
                  lui          ra, 229173
                  csrrwi       t5, 0x340, 0
                  xor          t6, a6, a0
                  c.andi       a1, -1
                  mul          a5, s2, t2
                  srl          t6, gp, ra
                  rem          s6, s6, s6
                  addi         s2, s8, -1941
                  c.and        s1, s0
                  csrrw        ra, 0x340, s2
                  mulh         t4, t5, t0
                  csrrs        gp, 0x340, a1
                  c.xor        a5, a4
                  mul          t2, s8, a0
                  slli         zero, s6, 7
                  ori          s7, s2, -832
                  ori          a7, s5, -1351
                  c.addi       s11, 31
                  c.nop
                  sltu         t5, zero, a5
                  c.addi       a5, -1
                  srli         t5, t2, 26
                  div          a7, s9, s1
                  sltu         s4, t5, s10
                  mulh         s11, s11, s8
                  csrrci       s4, 0x340, 0
                  rem          a5, a3, t0
                  remu         s4, t2, s1
                  ori          a4, s8, -1306
                  nop
                  mulhu        s9, s0, zero
                  mulhsu       s2, gp, t4
                  srli         a1, a5, 25
                  srli         t1, tp, 28
                  xor          s2, s5, a7
                  andi         s7, s10, 1595
                  c.or         s1, s1
                  xori         t0, s8, 1362
                  srl          a4, s4, t3
                  c.or         a0, a0
                  srli         s3, t0, 15
                  srli         s2, a0, 30
                  divu         s6, a5, a0
                  c.srli       a4, 22
                  csrrs        s0, 0x340, s3
                  slt          t1, a7, t3
                  divu         t6, s2, t2
                  csrrwi       a1, 0x340, 15
                  csrrs        s3, 0x340, s9
                  rem          a5, ra, s3
                  divu         a6, ra, a0
                  c.or         s1, a3
                  csrrc        s1, 0x340, zero
                  csrrci       s1, 0x340, 8
                  slt          gp, a3, s9
                  csrrwi       s11, 0x340, 5
                  slli         s1, t2, 18
                  slti         s11, t0, -69
                  c.and        a4, a2
                  slt          t0, s11, t3
                  c.lui        ra, 20
                  c.lui        t4, 4
                  slti         t3, s1, -20
                  csrrs        a5, 0x340, a2
                  csrrs        a7, 0x340, zero
                  nop
                  csrrci       ra, 0x340, 0
                  lui          s0, 503969
                  rem          t6, s8, s3
                  lui          s11, 258206
                  c.li         tp, 2
                  csrrw        s3, 0x340, gp
                  srli         a1, t4, 5
                  addi         a5, a6, -1649
                  slt          a5, a0, t5
                  rem          gp, a4, s2
                  andi         a4, a4, 895
                  sra          s4, t5, t0
                  c.sub        s0, a4
                  c.and        s1, a2
                  mulhu        a3, sp, s7
                  sltu         s0, gp, s9
                  mulhu        a4, s7, s3
                  and          t6, s5, a7
                  mul          t0, s6, zero
                  csrrci       s2, 0x340, 0
                  c.add        tp, tp
                  c.xor        s0, a5
                  mul          zero, t1, s0
                  divu         gp, a7, a3
                  csrrci       a3, 0x340, 0
                  c.xor        a0, a1
                  c.or         s0, a1
                  c.srai       a4, 13
                  c.li         t2, -1
                  c.sub        s0, a2
                  div          t5, a0, s8
                  sltiu        zero, gp, -873
                  ori          a7, s9, -1447
                  mulhsu       a5, zero, t3
                  sll          a3, zero, s4
                  c.xor        a1, s1
                  c.mv         a0, s10
                  div          s4, s11, t5
                  div          s0, s2, t5
                  c.slli       t2, 3
                  c.lui        t1, 22
                  or           t5, a3, gp
                  sra          t1, s8, a5
                  c.or         a1, a0
                  c.sub        a3, a1
                  and          ra, t5, t5
                  c.srai       a3, 25
                  mulh         t1, s3, t4
                  c.slli       s7, 8
                  c.addi       a4, -1
                  c.xor        s0, a3
                  xori         t2, s11, 656
                  c.lui        s6, 22
                  csrrwi       s5, 0x340, 10
                  c.srai       s0, 11
                  mul          a7, zero, s7
                  c.mv         gp, a2
                  xori         t5, s5, -827
                  c.addi       t2, -1
                  sll          a3, t1, gp
                  sltu         a1, t2, s11
                  c.add        s6, tp
                  c.addi       s4, 31
                  c.srli       a1, 29
                  and          t0, t0, t5
                  c.xor        a0, s0
                  c.slli       t6, 7
                  mul          t1, gp, s5
                  c.add        t4, a4
                  sub          s9, tp, a6
                  c.mv         s7, s7
                  sra          s0, s10, t3
                  c.li         s6, 12
                  xori         zero, gp, -595
                  c.and        a0, a1
                  c.srli       a4, 2
                  c.srai       a3, 3
                  and          t5, s9, s3
                  sll          gp, t4, s3
                  c.nop
                  srli         a1, a0, 21
                  div          gp, s9, a2
                  slli         t0, a4, 17
                  csrrsi       a0, 0x340, 0
                  mulhu        a5, t4, ra
                  c.add        t1, t1
                  mul          a4, s2, ra
                  csrrc        t6, 0x340, zero
                  srli         a7, s3, 28
                  sll          s4, a6, a6
                  sltiu        ra, s6, -251
                  sltu         s4, s3, t5
                  srli         s1, t3, 7
                  csrrc        zero, 0x340, tp
                  c.andi       a5, -1
                  addi         s5, sp, -461
                  c.xor        a5, a0
                  mulhu        s7, s6, s3
                  and          tp, t5, s5
                  sub          t1, t2, s10
                  c.sub        a1, a3
                  c.lui        ra, 1
                  srai         t6, s3, 0
                  srli         s1, a6, 22
                  csrrw        a4, 0x340, t1
                  csrrs        s8, 0x340, zero
                  csrrci       a3, 0x340, 12
                  csrrsi       ra, 0x340, 0
                  c.and        a0, a4
                  c.srli       s0, 1
                  andi         s7, s9, 1325
                  mulh         s2, t5, s6
                  andi         a4, sp, 693
                  c.mv         a0, s10
                  csrrci       s3, 0x340, 23
                  ori          t1, a2, 634
                  c.addi       s9, 5
                  csrrwi       s4, 0x340, 16
                  slti         a5, a4, 1327
                  and          t2, s7, ra
                  or           s3, sp, gp
                  or           a5, tp, a2
                  slti         s9, a4, 306
                  ori          a1, sp, 644
                  c.add        s0, t3
                  c.xor        a4, a5
                  c.and        s1, s1
                  mul          s5, t5, s3
                  c.lui        s1, 16
                  div          s6, a6, s5
                  rem          s0, a3, t5
                  nop
                  xor          s7, zero, t1
                  slti         t2, s11, -1406
                  c.slli       s9, 15
                  sltu         t6, a0, a1
                  lui          t6, 1014807
                  div          s9, s3, s2
                  c.srli       s0, 23
                  ori          a5, s6, 1526
                  csrrc        s11, 0x340, ra
                  auipc        s2, 606809
                  mulh         t2, a0, ra
                  mulhu        gp, a2, s0
                  csrrsi       s1, 0x340, 17
                  add          s8, gp, t1
                  slti         s9, sp, -1283
                  mulh         s4, s1, s4
                  mul          s5, s6, t2
                  c.mv         s9, s10
                  mul          s7, zero, zero
                  sub          t1, sp, a4
                  remu         t4, a7, s3
                  nop
                  mulhsu       s1, s4, t1
                  csrrs        a0, 0x340, zero
                  c.or         a4, a5
                  rem          a0, t5, a1
                  nop
                  csrrs        t3, 0x340, zero
                  mulh         t3, s11, a5
                  xor          s3, a3, s11
                  slti         t0, t0, -875
                  c.slli       tp, 15
                  rem          s1, s6, a2
                  c.srli       a1, 17
                  c.mv         tp, s2
                  sra          a7, gp, sp
                  srai         s0, t0, 23
                  c.nop
                  sltu         t3, a5, t3
                  mulhu        s6, s5, t1
                  c.xor        a4, s0
                  c.mv         s6, ra
                  or           s7, sp, t4
                  csrrs        s9, 0x340, a0
                  c.mv         gp, a3
                  c.nop
                  srai         a1, a1, 10
                  c.srai       a3, 5
                  ori          a6, tp, -433
                  or           a3, s9, t3
                  mulhsu       s1, t6, a5
                  add          s9, t1, a0
                  mulhsu       a3, s0, sp
                  nop
                  sra          a0, s2, t5
                  c.srli       a1, 16
                  c.srli       s0, 12
                  slti         s2, s9, 457
                  mulhu        t0, s11, a3
                  or           t4, s5, a7
                  csrrci       a6, 0x340, 0
                  c.lui        a5, 28
                  or           s2, a7, t6
                  sll          s11, zero, zero
                  mulh         a3, s5, t2
                  c.and        a0, a3
                  div          a1, s4, a3
                  csrrs        a5, 0x340, s2
                  c.andi       a1, -1
                  sra          s8, tp, t6
                  c.lui        a0, 4
                  c.or         s1, a4
                  mul          s3, a4, t5
                  csrrci       s2, 0x340, 0
                  csrrwi       s6, 0x340, 12
                  c.addi       t0, 6
                  csrrc        s4, 0x340, zero
                  rem          ra, t1, tp
                  c.add        a4, s11
                  divu         a1, s5, tp
                  div          s11, s9, s6
                  ori          s3, s1, 307
                  nop
                  csrrw        a4, 0x340, s10
                  sra          t5, ra, sp
                  c.add        t1, a2
                  mulh         a6, t4, a6
                  sra          a1, t1, ra
                  c.add        gp, s1
                  srai         s4, a2, 13
                  srai         t2, gp, 30
                  xor          a0, s5, t4
                  andi         ra, s2, 815
                  or           s1, a4, tp
                  slt          s7, s1, a2
                  c.xor        a0, a2
                  c.and        a5, s0
                  mulhsu       zero, sp, t2
                  sub          s4, a1, s1
                  c.srai       s0, 2
                  slti         s3, s3, 1151
                  csrrsi       t4, 0x340, 21
                  mulhsu       s1, sp, s1
                  csrrs        s0, 0x340, zero
                  mulhsu       t1, zero, a2
                  ori          a6, s3, -1138
                  c.srli       a4, 8
                  nop
                  c.mv         t1, a2
                  csrrs        zero, 0x340, s8
                  c.andi       s0, 25
                  srai         tp, s6, 21
                  csrrci       ra, 0x340, 25
                  c.and        a1, a0
                  ori          s9, t3, 1241
                  c.sub        a5, s0
                  c.add        t3, s9
                  c.xor        a3, a3
                  addi         a6, s0, -1422
                  c.and        a5, s1
                  c.add        s0, s9
                  c.xor        s1, s1
                  c.and        s1, a3
                  ori          s4, a2, 169
                  c.andi       a0, 10
                  sltiu        s5, s10, -1495
                  c.and        a3, a1
                  remu         gp, s8, a3
                  mulh         a6, s0, a5
                  c.xor        s1, a0
                  xori         s11, ra, 11
                  csrrw        t2, 0x340, tp
                  c.srli       a4, 19
                  slti         s3, s2, 214
                  csrrs        ra, 0x340, zero
                  csrrs        ra, 0x340, zero
                  sltu         t1, a3, t1
                  c.sub        a1, a3
                  lui          zero, 67866
                  c.lui        s7, 21
                  add          gp, a6, s10
                  c.slli       a0, 22
                  csrrw        s2, 0x340, s7
                  sltiu        s7, s10, 1440
                  c.and        s1, a5
                  c.or         a5, a0
                  mulh         s8, s9, s2
                  add          s9, a4, s10
                  c.lui        s3, 29
                  csrrwi       a3, 0x340, 11
                  addi         tp, zero, 264
                  sll          t4, s3, a7
                  lui          gp, 187518
                  rem          s6, s9, t4
                  c.srli       a0, 26
                  mul          a7, a2, gp
                  and          a5, tp, ra
                  mulhu        t6, s6, a1
                  c.srli       a0, 11
                  xor          s3, s10, t6
                  csrrci       s3, 0x340, 12
                  c.mv         a4, gp
                  c.mv         t3, s0
                  srli         s4, gp, 27
                  mulh         a7, s3, s1
                  csrrci       t2, 0x340, 0
                  slt          a7, a6, ra
                  sltiu        s4, t3, -695
                  srli         t6, t1, 1
                  mulh         t2, s1, a3
                  nop
                  rem          s7, a7, zero
                  andi         s4, t2, 1058
                  c.and        a3, a5
                  andi         ra, a4, 643
                  c.andi       s1, 21
                  sll          s8, a2, s2
                  csrrsi       a6, 0x340, 0
                  xori         t3, t5, -994
                  c.nop
                  or           gp, s2, a3
                  csrrw        a4, 0x340, a6
                  srli         s8, a4, 29
                  c.addi       tp, 20
                  rem          a3, a7, gp
                  mulhu        a7, a6, s7
                  c.sub        a1, s0
                  mulhsu       tp, s1, t5
                  ori          s9, s10, -588
                  c.addi       a7, 10
                  c.srai       s1, 13
                  addi         t5, s2, -2030
                  c.srai       a1, 29
                  andi         t0, s10, 381
                  rem          zero, a3, tp
                  c.and        s1, a5
                  xori         gp, s2, -146
                  nop
                  c.sub        a4, a1
                  c.lui        s4, 2
                  and          a3, s7, t5
                  sub          t3, s7, a6
                  mulhu        s7, s9, s6
                  rem          a6, s0, a2
                  srli         t2, a3, 8
                  nop
                  srl          s8, s11, a6
                  c.lui        a5, 16
                  lui          s1, 309204
                  c.sub        a1, a5
                  c.sub        a4, a4
                  c.xor        a1, a0
                  add          tp, t4, t2
                  addi         s7, a6, 887
                  csrrs        t3, 0x340, zero
                  csrrc        a1, 0x340, zero
                  srl          t4, s0, t1
                  c.andi       a0, -1
                  addi         s8, a5, -1626
                  xor          s1, t2, t0
                  csrrc        s2, 0x340, zero
                  csrrwi       a1, 0x340, 7
                  and          t4, tp, s3
                  mulhsu       t5, s11, a1
                  csrrsi       tp, 0x340, 25
                  c.li         a0, 20
                  c.sub        s1, a3
                  sll          a7, s4, s0
                  sra          t3, zero, a2
                  xori         a0, t3, -422
                  c.or         a3, a5
                  csrrsi       s0, 0x340, 0
                  srai         s4, s10, 12
                  xor          t2, s3, a7
                  sltiu        s1, a5, 1126
                  sltiu        ra, zero, -131
                  c.mv         s0, t1
                  mulhu        t3, a3, a3
                  slt          a4, s4, a0
                  sra          s7, s8, s5
                  c.or         s1, a4
                  sll          s6, s8, s10
                  c.mv         a0, s4
                  xor          ra, a1, a1
                  divu         s9, s10, a3
                  srli         ra, s10, 22
                  c.xor        a0, a4
                  srai         t1, t4, 4
                  auipc        t3, 849001
                  add          t6, s10, a7
                  c.andi       a4, 11
                  c.srli       a1, 26
                  andi         s2, gp, 472
                  xor          s4, a6, a4
                  rem          a1, a5, s0
                  c.slli       t6, 13
                  ori          s2, s5, -1231
                  sra          a0, s11, zero
                  sltu         s4, t2, s9
                  csrrci       s2, 0x340, 0
                  add          tp, tp, s11
                  andi         a4, a0, 978
                  c.or         a5, a3
                  sra          t3, t3, t0
                  csrrw        a0, 0x340, s5
                  add          a4, a2, s10
                  slt          a5, zero, s9
                  andi         s4, s8, -186
                  slli         a1, t3, 9
                  add          a0, s6, a2
                  c.and        s1, a0
                  c.addi       s11, -1
                  srl          s11, s9, tp
                  csrrc        a7, 0x340, s6
                  andi         s9, s6, 114
                  xori         t0, s11, 1377
                  xori         t1, s6, -33
                  srl          s11, t1, a3
                  c.or         a1, a4
                  nop
                  slt          a3, s3, a1
                  remu         a4, s9, s4
                  srai         t0, t2, 26
                  sub          t4, a5, a1
                  remu         a3, s7, t3
                  c.lui        a7, 25
                  srl          s1, t4, sp
                  c.lui        a0, 2
                  nop
                  c.li         t5, -1
                  xor          t5, s3, s4
                  csrrsi       a3, 0x340, 12
                  addi         ra, t3, 37
                  c.addi       gp, 30
                  auipc        a5, 173466
                  slti         s5, ra, -299
                  csrrsi       a5, 0x340, 28
                  csrrci       s4, 0x340, 0
                  srl          t4, t5, a6
                  xor          a5, s1, s9
                  csrrs        s5, 0x340, zero
                  xori         t6, a6, -1879
                  c.lui        s6, 15
                  nop
                  mulh         gp, t2, t2
                  c.srli       a3, 17
                  c.li         gp, -1
                  lui          t1, 860963
                  slti         t3, s10, -1712
                  xori         a4, s7, -1812
                  lui          zero, 705519
                  auipc        t6, 846638
                  c.addi       t3, 19
                  c.srai       s1, 7
                  andi         s8, s10, -1217
                  divu         s7, zero, s8
                  c.or         a4, a3
                  csrrs        a3, 0x340, t0
                  lui          t5, 754875
                  xor          a6, a3, sp
                  mulh         ra, s4, s3
                  c.nop
                  slt          a4, s2, ra
                  c.srai       a4, 12
                  c.srai       a3, 14
                  c.sub        a3, a4
                  c.and        s0, a3
                  sltiu        a0, t0, -855
                  mulh         t4, s11, s3
                  lui          a4, 579482
                  andi         s11, a6, -1259
                  sltiu        s0, a6, -1258
                  srli         a4, s1, 0
                  csrrw        s2, 0x340, zero
                  c.li         s11, -1
                  c.nop
                  c.andi       a1, 20
                  csrrci       t6, 0x340, 0
                  div          a0, s4, s3
                  c.li         t4, -1
                  c.nop
                  c.addi       t0, 2
                  sll          s7, s3, a4
                  c.li         t0, -1
                  addi         s5, t5, 1280
                  c.mv         s1, t2
                  sll          t3, t1, s5
                  srai         s1, s3, 27
                  c.srai       s0, 14
                  xori         a5, s5, 2017
                  remu         s5, t1, a6
                  csrrwi       t4, 0x340, 19
                  sll          a4, s0, s10
                  csrrs        a7, 0x340, gp
                  c.nop
                  nop
                  sra          s7, s0, t2
                  c.xor        a4, a3
                  c.or         s0, a0
                  sra          a3, a4, s11
                  csrrsi       a0, 0x340, 0
                  mulh         gp, t3, t3
                  sltu         tp, s11, a3
                  sll          s0, zero, s10
                  c.xor        s0, a0
                  remu         tp, t2, a1
                  div          a7, a3, s10
                  mulhu        s4, s0, sp
                  mul          a0, t5, s1
                  c.srai       s0, 16
                  c.and        a3, a3
                  mulhu        a0, s11, a2
                  ori          t3, s10, -269
                  mulhsu       zero, sp, a6
                  c.sub        a3, a1
                  rem          s0, a3, a6
                  c.slli       t1, 7
                  csrrc        zero, 0x340, zero
                  c.slli       s2, 19
                  rem          t6, s0, a0
                  sra          s8, s9, a4
                  div          tp, s0, zero
                  addi         t1, s8, -153
                  or           s4, s2, t0
                  lui          a3, 986363
                  c.addi       ra, -1
                  c.li         a5, 26
                  csrrci       s7, 0x340, 10
                  c.add        t4, s5
                  lui          t4, 252706
                  sltiu        a6, gp, -1235
                  slti         s6, a0, -1464
                  or           t3, ra, s10
                  rem          a4, a1, t5
                  srl          s3, a7, t6
                  csrrc        gp, 0x340, s1
                  rem          s2, s2, s5
                  c.add        t2, t5
                  xor          t2, a5, t0
                  lui          s9, 13110
                  addi         t3, s4, -372
                  c.and        a4, a4
                  sll          a4, a7, a2
                  xor          s9, gp, s6
                  c.lui        s1, 29
                  add          s3, sp, a1
                  mulhu        tp, s3, t5
                  remu         s11, t3, s4
                  auipc        tp, 701271
                  c.sub        a1, a4
                  srl          gp, t4, s8
                  remu         s11, s11, s5
                  sub          s9, s5, t2
                  csrrwi       a5, 0x340, 30
                  lui          s9, 652791
                  nop
                  nop
                  csrrs        a0, 0x340, zero
                  sltiu        s2, a1, -682
                  remu         a3, t4, s11
                  slti         s3, s8, 442
                  c.lui        t5, 30
                  c.li         t0, -1
                  c.li         s7, 5
                  sltiu        t4, t5, 1162
                  csrrs        zero, 0x340, zero
                  c.add        a1, tp
                  mulhsu       t0, s7, ra
                  c.srai       s0, 30
                  csrrs        zero, 0x340, a0
                  ori          a0, a3, -1302
                  c.addi       s3, -1
                  or           t6, sp, s4
                  c.andi       a4, -1
                  sltu         s2, t3, a1
                  sra          s6, s8, t4
                  c.slli       s1, 26
                  c.sub        a1, a4
                  c.slli       s7, 17
                  ori          gp, t6, -1044
                  c.srli       a3, 5
                  slli         a3, s7, 21
                  mulhsu       a1, s5, s10
                  remu         s7, a0, a2
                  c.srai       a5, 27
                  mul          a3, s0, s1
                  sll          tp, t2, s4
                  rem          s4, s4, t3
                  c.andi       s0, 14
                  csrrci       tp, 0x340, 0
                  lui          a7, 413804
                  c.and        s1, a1
                  divu         ra, s9, t6
                  remu         a7, t2, a4
                  csrrw        ra, 0x340, a0
                  csrrw        s0, 0x340, a3
                  c.and        a0, a1
                  or           s3, s3, s11
                  csrrs        tp, 0x340, zero
                  ori          t1, s0, -1953
                  addi         s4, ra, -26
                  mul          s2, t0, s5
                  csrrsi       t0, 0x340, 24
                  slti         a3, tp, 606
                  addi         t4, t2, -1867
                  slli         t1, s9, 10
                  c.srli       a1, 25
                  sltiu        gp, s3, 1799
                  sltiu        a6, t2, 588
                  c.lui        t2, 1
                  c.lui        a1, 13
                  c.addi       s11, 27
                  c.nop
                  mul          t2, ra, s0
                  nop
                  srli         s7, s2, 11
                  slli         s11, ra, 3
                  csrrci       zero, 0x340, 11
                  xor          a0, s11, a5
                  sra          t0, zero, a5
                  sltu         s2, s10, s10
                  or           s6, tp, t1
                  divu         gp, t0, s1
                  c.addi       s5, 12
                  nop
                  divu         s5, t0, t2
                  mulhu        s8, s4, s1
                  sll          zero, s2, a1
                  mulhu        gp, a3, a0
                  c.mv         a6, s4
                  sltu         s2, t1, t0
                  srl          t5, t0, a7
                  csrrc        s1, 0x340, a2
                  c.sub        s1, a0
                  ori          a1, t5, -1868
                  add          t6, t1, gp
                  mulhsu       a5, s5, s2
                  slt          s6, s1, s8
                  c.and        a5, s0
                  slti         t0, t3, -1715
                  lui          s1, 888712
                  divu         s7, gp, t1
                  csrrc        a1, 0x340, zero
                  c.addi       a0, -1
                  c.srai       a4, 3
                  csrrw        t6, 0x340, a0
                  srl          s0, t6, a6
                  mulh         zero, t0, a4
                  csrrc        a0, 0x340, s0
                  mul          ra, a0, t2
                  addi         t6, s5, -1006
                  mulhsu       s4, s3, s2
                  c.lui        t0, 3
                  c.srli       a3, 22
                  sub          s0, t6, a5
                  csrrsi       t4, 0x340, 0
                  rem          a4, zero, gp
                  c.li         s9, -1
                  c.slli       t3, 13
                  mulhu        s5, s7, s11
                  rem          a0, t1, s9
                  slti         ra, t0, -1066
                  sltu         a7, t5, s4
                  mul          zero, t6, s2
                  mul          gp, s1, a0
                  csrrw        s7, 0x340, s7
                  sltu         s5, a5, a2
                  csrrs        t4, 0x340, a6
                  srl          s3, s5, zero
                  mulh         s2, tp, t0
                  c.or         s1, s0
                  slt          a7, gp, s8
                  c.nop
                  sltu         gp, s5, a7
                  ori          s6, a2, 1302
                  ori          gp, s2, -504
                  c.srai       a4, 16
                  csrrsi       s6, 0x340, 19
                  addi         t1, s11, -1412
                  c.nop
                  sltu         a3, s9, a1
                  add          zero, s3, ra
                  c.sub        s1, a3
                  c.sub        s1, a0
                  csrrc        s5, 0x340, zero
                  andi         s9, t6, -1128
                  srl          tp, s8, t5
                  mulhu        s11, t6, s5
                  mul          s6, t2, gp
                  sra          s3, a5, s7
                  c.li         s7, 1
                  ori          t0, t0, -886
                  remu         ra, a3, s1
                  c.add        t1, a2
                  rem          t6, s9, t4
                  csrrc        s8, 0x340, zero
                  c.sub        s0, a5
                  mulh         zero, tp, a2
                  slli         t1, t1, 9
                  nop
                  xor          t4, s4, a3
                  auipc        gp, 686947
                  lui          s6, 636731
                  c.nop
                  c.addi       ra, -1
                  c.slli       s8, 12
                  c.slli       t1, 16
                  mulhu        s8, s9, t3
                  or           a5, t6, tp
                  mulhu        s2, s7, s0
                  srl          gp, s4, s2
                  sltu         s7, t5, s8
                  c.and        s1, a4
                  slti         gp, t1, -1743
                  slti         zero, t2, -993
                  sltiu        t3, a2, -1221
                  csrrs        s9, 0x340, zero
                  sra          tp, s7, t0
                  c.slli       t1, 2
                  sltu         a3, sp, s4
                  c.srli       a3, 1
                  slli         ra, s3, 12
                  c.srli       a1, 17
                  sra          t5, s8, s10
                  auipc        a0, 439027
                  slt          a7, s10, t1
                  c.sub        a1, a1
                  sub          t1, s0, t5
                  lui          s4, 498467
                  auipc        tp, 850247
                  srli         t2, a5, 17
                  addi         s1, s1, 2039
                  remu         t3, a0, a3
                  csrrs        a4, 0x340, zero
                  mulhsu       s9, a4, a3
                  mulhu        s2, s9, t5
                  c.lui        tp, 29
                  c.li         t2, 28
                  c.srai       a1, 17
                  c.srai       a3, 15
                  c.srli       a4, 18
                  c.slli       s9, 4
                  auipc        s7, 382574
                  mulhu        s0, s11, gp
                  csrrwi       s3, 0x340, 21
                  mulh         t3, t1, tp
                  xor          ra, t0, gp
                  add          t6, t0, t3
                  c.nop
                  mulhu        t6, s8, s0
                  c.slli       t3, 21
                  sll          t6, t5, t2
                  mulhsu       a1, t6, t2
                  mul          a3, t5, t1
                  remu         ra, s5, t5
                  slti         s1, s1, 1351
                  c.nop
                  mulh         t1, t5, a1
                  andi         s5, s9, -1207
                  mulhu        zero, s9, s11
                  csrrci       t3, 0x340, 0
                  auipc        s7, 713230
                  srai         t3, tp, 2
                  mulhu        s1, a4, s8
                  c.or         a4, a2
                  divu         s8, a6, a7
                  sub          s8, s5, t5
                  and          t2, t2, a2
                  divu         t0, a0, s3
                  slt          t6, s0, t0
                  ori          t1, s7, 1469
                  c.xor        a1, a0
                  c.mv         t2, t3
                  sltu         a3, tp, a6
                  c.slli       s11, 25
                  divu         a0, t1, t3
                  csrrci       t4, 0x340, 0
                  mulh         s5, s5, s1
                  c.and        s1, a2
                  csrrci       s2, 0x340, 0
                  mulh         s3, zero, s11
                  remu         a3, a7, t5
                  nop
                  lui          s4, 387206
                  auipc        s1, 898661
                  sltu         a1, s9, t0
                  c.mv         a3, t0
                  c.li         s5, -1
                  c.srai       a0, 12
                  c.add        gp, a2
                  andi         a1, s9, -1
                  csrrsi       gp, 0x340, 17
                  slli         t6, tp, 28
                  xor          t6, t0, s9
                  mulhsu       s8, sp, t1
                  div          t6, t5, s0
                  slt          a4, s5, t6
                  c.lui        a0, 14
                  mul          a4, s5, s7
                  c.nop
                  sltiu        s11, s3, -958
                  slli         s7, zero, 23
                  c.sub        s0, a3
                  c.li         a0, -1
                  c.srli       a5, 11
                  divu         a3, zero, a2
                  rem          a4, s10, ra
                  c.nop
                  and          a7, t0, s8
                  mulhu        t4, t4, s2
                  auipc        t4, 730685
                  srl          t6, s7, tp
                  auipc        s4, 596595
                  xor          s11, t0, t5
                  xori         gp, t0, -579
                  sltu         gp, t3, s9
                  srli         a6, s10, 22
                  c.andi       s1, 25
                  xor          t6, zero, t1
                  csrrs        t1, 0x340, zero
                  c.addi       t5, 26
                  ori          s7, s11, -1970
                  div          t4, ra, a6
                  ori          t1, zero, 252
                  csrrsi       s11, 0x340, 0
                  c.xor        a1, s0
                  slti         gp, s0, -1117
                  lui          ra, 179596
                  c.li         s5, -1
                  div          zero, zero, sp
                  c.nop
                  c.lui        t4, 2
                  c.addi       s3, -1
                  and          t6, s6, a3
                  c.addi       a1, -1
                  c.or         s1, a0
                  c.sub        a3, a3
                  mulhsu       a6, zero, s8
                  mulhu        a4, t3, zero
                  csrrwi       t1, 0x340, 11
                  slli         t1, s0, 7
                  add          s6, a0, t3
                  c.slli       a1, 30
                  c.add        t2, tp
                  c.srli       s1, 7
                  c.srli       s0, 1
                  c.mv         gp, a4
                  xor          t4, t4, a5
                  c.slli       t6, 15
                  nop
                  xor          a3, s9, ra
                  ori          t0, t6, 1356
                  remu         s3, t4, gp
                  remu         s5, t6, a0
                  lui          t0, 1013071
                  srli         s6, t5, 27
                  csrrwi       s4, 0x340, 1
                  mulh         s5, s5, t1
                  addi         s6, s4, -1632
                  mulhu        s6, a6, s10
                  add          t2, s6, a0
                  c.slli       t1, 24
                  csrrc        a7, 0x340, s5
                  c.add        a3, s8
                  c.nop
                  and          a0, t6, s11
                  rem          t1, a6, s10
                  c.xor        s0, s0
                  csrrs        s8, 0x340, t5
                  slt          gp, ra, a2
                  mulhsu       s4, a4, a4
                  div          ra, t2, s10
                  sltu         t1, s0, gp
                  mulhu        t6, a4, t6
                  mul          t6, s6, a3
                  srai         s0, a6, 29
                  c.or         s1, a2
                  c.andi       a5, 7
                  srl          t4, t6, a0
                  c.or         a4, s1
                  mulh         zero, gp, a7
                  ori          t4, gp, 824
                  sra          t3, s2, s5
                  slli         s7, s2, 22
                  csrrs        s9, 0x340, t4
                  c.mv         a1, s7
                  addi         t6, ra, -483
                  c.add        a5, t6
                  csrrci       t4, 0x340, 13
                  sltiu        t6, s10, -1197
                  srai         s0, s6, 25
                  andi         s8, tp, 951
                  nop
                  csrrs        t0, 0x340, a4
                  sll          gp, t1, zero
                  c.and        s1, s0
                  c.or         a1, a2
                  andi         t2, t6, 1203
                  remu         gp, t1, t1
                  csrrsi       s0, 0x340, 0
                  mulhsu       a4, s6, a3
                  c.addi       a5, -1
                  c.and        a5, a1
                  srai         s2, s1, 7
                  sub          a4, s6, zero
                  sub          a0, zero, gp
                  csrrci       gp, 0x340, 0
                  slt          zero, s7, a1
                  c.slli       s0, 20
                  or           s3, s0, gp
                  mulh         s2, s1, t2
                  sra          t5, a0, tp
                  sll          s3, sp, s7
                  c.and        s1, a0
                  sll          s0, t5, a5
                  nop
                  ori          tp, gp, 444
                  c.sub        a5, s1
                  c.sub        s0, a2
                  ori          s6, s7, 1640
                  c.or         a1, a1
                  mulhu        s7, s3, s8
                  c.xor        s0, a0
                  csrrs        t6, 0x340, zero
                  slli         s8, a5, 12
                  slli         s9, t3, 24
                  slt          t5, tp, gp
                  div          s5, a3, s11
                  mulhu        a4, s8, s3
                  nop
                  c.sub        a0, a0
                  csrrci       s0, 0x340, 20
                  srai         s3, a0, 1
                  c.srai       a4, 3
                  auipc        t5, 47295
                  c.li         s3, 14
                  csrrwi       t6, 0x340, 2
                  srai         t1, s0, 2
                  add          a5, s4, s1
                  auipc        s3, 730158
                  sltu         s2, sp, a5
                  andi         t0, a3, -935
                  divu         s3, s4, zero
                  remu         tp, gp, t3
                  xor          t4, t5, tp
                  c.mv         s1, gp
                  c.add        a1, s11
                  xor          s3, s11, t0
                  c.li         t2, -1
                  srl          t3, ra, a3
                  mulh         s7, t3, a3
                  c.nop
                  csrrw        a0, 0x340, s2
                  srl          t6, t0, s7
                  andi         s9, t6, -324
                  mulhu        a0, s8, t2
                  csrrc        t3, 0x340, zero
                  sltu         a4, a3, a1
                  slli         a5, t2, 6
                  div          gp, a2, a5
                  sra          t6, s7, a2
                  sra          t2, t3, s8
                  ori          t1, gp, 1529
                  c.slli       s2, 7
                  c.li         t2, 3
                  sub          s8, zero, s4
                  csrrsi       a4, 0x340, 0
                  addi         a5, s5, -1279
                  sub          t0, s8, t0
                  ori          s7, a6, 1262
                  csrrwi       a1, 0x340, 12
                  rem          s3, t3, t6
                  divu         s0, s0, s5
                  c.li         a7, 13
                  c.or         s1, a3
                  srl          t0, s11, s0
                  c.lui        s2, 29
                  nop
                  div          ra, s1, s9
                  srl          a4, a0, a3
                  divu         t6, a6, sp
                  csrrsi       a4, 0x340, 0
                  c.srai       a1, 25
                  c.and        a4, a4
                  slli         t5, s1, 15
                  slli         t3, s7, 13
                  xor          s3, t0, a6
                  slt          s3, t2, tp
                  nop
                  csrrwi       t2, 0x340, 4
                  srli         a0, zero, 30
                  ori          s6, ra, -1751
                  csrrw        a5, 0x340, s6
                  ori          s7, s11, 172
                  or           t1, s0, s10
                  c.or         s0, a0
                  c.addi       s4, -1
                  c.add        a3, tp
                  slt          s5, a7, s5
                  slli         s9, a6, 20
                  c.or         a4, s0
                  c.and        s1, a3
                  mulhsu       s7, zero, t3
                  rem          a3, s4, s9
                  c.mv         a1, s3
                  csrrc        ra, 0x340, zero
                  slti         s6, s0, 915
                  slt          s8, t1, s9
                  c.andi       a1, -1
                  c.nop
                  xor          t3, s11, s5
                  c.li         a4, -1
                  c.srli       a1, 5
                  mulhu        t3, t3, t6
                  c.nop
                  remu         s11, t6, s8
                  mulh         a5, s0, t2
                  or           a4, gp, a4
                  c.add        t6, ra
                  addi         a5, s2, -1651
                  csrrci       s5, 0x340, 0
                  remu         a5, a5, s8
                  add          a6, s10, gp
                  xori         t6, s2, 655
                  sub          t5, t2, t1
                  andi         a1, a5, -1578
                  c.lui        a1, 31
                  divu         t3, a4, s8
                  c.andi       a5, 9
                  c.and        a3, s0
                  sltiu        a7, a5, -103
                  c.nop
                  c.xor        s0, a1
                  mulhsu       a6, zero, t3
                  csrrci       ra, 0x340, 4
                  or           tp, s5, t1
                  sll          t5, ra, a5
                  mul          s6, s4, zero
                  c.add        ra, t6
                  addi         t0, s7, 2034
                  c.sub        s1, a3
                  srai         t6, t6, 4
                  csrrwi       s11, 0x340, 2
                  divu         t1, sp, s5
                  slt          s5, s4, tp
                  c.or         s1, s0
                  c.nop
                  slti         s8, s0, -181
                  c.srai       s0, 24
                  xori         s1, a6, 1367
                  srli         a6, a1, 0
                  mul          t1, ra, gp
                  c.and        a3, a0
                  mulh         s5, s5, ra
                  slti         s7, s11, -1673
                  mul          zero, sp, s5
                  c.lui        s4, 11
                  c.or         s0, a3
                  mulhu        s3, t5, a0
                  sub          a5, a3, t6
                  c.mv         a5, s1
                  div          t2, a4, sp
                  csrrw        t3, 0x340, s8
                  divu         t6, gp, t5
                  sra          s5, t6, s10
                  csrrw        s2, 0x340, zero
                  c.andi       a1, -1
                  csrrwi       s7, 0x340, 0
                  c.add        s7, a5
                  csrrsi       a6, 0x340, 3
                  c.sub        a4, s0
                  c.srai       a4, 22
                  c.sub        a0, a2
                  csrrwi       a5, 0x340, 31
                  addi         a1, ra, -454
                  sltiu        s8, zero, 225
                  c.lui        a1, 26
                  c.sub        a4, a5
                  c.mv         tp, a3
                  csrrc        s4, 0x340, a7
                  csrrwi       a6, 0x340, 7
                  mulhsu       s7, s9, t4
                  sltu         a4, a4, t4
                  auipc        t1, 615669
                  slt          a1, a1, ra
                  rem          t4, t1, ra
                  add          s8, t4, a2
                  sll          s7, a5, a6
                  addi         t5, a3, 130
                  rem          s7, s7, s1
                  lui          s8, 723384
                  slti         s9, s7, -850
                  c.nop
                  ori          gp, zero, -1451
                  div          a3, gp, s3
                  c.nop
                  mulh         zero, s2, a5
                  csrrwi       s2, 0x340, 29
                  c.slli       tp, 9
                  c.srai       a4, 10
                  mulhsu       tp, tp, t4
                  csrrsi       s1, 0x340, 0
                  c.mv         s9, a0
                  slt          s6, s3, s11
                  c.sub        a4, a0
                  c.srli       a5, 11
                  c.slli       a4, 16
                  lui          tp, 950275
                  c.xor        a1, s0
                  c.addi       s0, 3
                  c.addi       s11, 29
                  srl          a1, a6, s4
                  csrrs        t6, 0x340, sp
                  and          a6, a0, s1
                  sub          gp, tp, a3
                  add          t1, s6, s6
                  srai         t0, a3, 18
                  nop
                  mulh         s3, a4, s9
                  c.sub        a1, a2
                  c.mv         s11, t5
                  csrrsi       t4, 0x340, 0
                  mulh         t6, s10, s7
                  sltu         s8, s7, s3
                  c.srai       a1, 25
                  csrrwi       a1, 0x340, 6
                  and          s0, zero, t2
                  divu         s0, s0, s8
                  ori          s6, s4, 1786
                  c.slli       s9, 24
                  remu         s2, s2, s0
                  c.sub        a5, a1
                  c.sub        s0, a3
                  c.add        s11, s4
                  divu         a1, s1, s2
                  csrrs        t2, 0x340, t1
                  csrrs        t4, 0x340, zero
                  c.nop
                  c.lui        t3, 31
                  csrrsi       s4, 0x340, 11
                  and          a5, s7, s10
                  c.srai       s1, 14
                  c.xor        a3, a1
                  c.nop
                  rem          a5, t2, s7
                  auipc        a7, 958007
                  srli         t2, s11, 4
                  xor          zero, a6, t4
                  csrrw        gp, 0x340, a6
                  mulh         s4, a6, sp
                  divu         ra, a6, a0
                  xor          s6, a1, a6
                  xori         t3, s4, 1648
                  c.nop
                  slti         t5, s8, 625
                  xor          a7, s4, a0
                  sll          s7, t3, s1
                  xor          a0, t4, a0
                  c.srai       s1, 30
                  or           s3, a4, t6
                  and          s2, s1, a7
                  divu         a1, t0, s9
                  mulh         t1, t4, a6
                  c.srai       s0, 10
                  c.srli       a5, 13
                  srai         s3, s10, 12
                  sra          s9, s2, a5
                  c.mv         t2, a7
                  c.srli       a0, 15
                  c.srli       a3, 27
                  addi         t1, a3, 72
                  c.nop
                  c.or         a5, a0
                  c.lui        a0, 5
                  c.addi       t3, 29
                  sll          t6, zero, t5
                  xor          t2, s9, gp
                  lui          s4, 916166
                  mul          a1, s4, s3
                  srl          a3, s3, a4
                  c.slli       a5, 13
                  sub          t6, tp, a2
                  c.mv         a1, a1
                  addi         a1, a0, 509
                  addi         a4, t3, -853
                  andi         t3, s3, -418
                  mulhu        s5, s5, t6
                  srli         s1, a3, 16
                  csrrc        s7, 0x340, s9
                  mulhu        t0, zero, s2
                  csrrc        s7, 0x340, zero
                  mulhsu       s7, a5, a3
                  mul          gp, t6, t2
                  c.addi       a4, 21
                  csrrw        s0, 0x340, s10
                  csrrsi       s4, 0x340, 16
                  or           a7, s0, s3
                  divu         s6, t2, a4
                  c.mv         s0, s6
                  srli         a0, t0, 12
                  rem          ra, gp, s4
                  lui          t4, 228926
                  slti         a3, zero, -1590
                  slt          s0, t1, t1
                  slli         s5, a6, 6
                  csrrc        s5, 0x340, zero
                  csrrsi       s8, 0x340, 0
                  or           s2, s6, sp
                  sltu         a1, t6, t4
                  or           zero, t5, s1
                  mulhsu       a1, t3, s3
                  c.addi       a3, 27
                  auipc        s9, 630227
                  c.xor        s0, a1
                  rem          s8, t5, s6
                  div          a1, t6, t5
                  lui          s2, 749118
                  xor          t1, s2, t1
                  srai         s5, t3, 29
                  srl          a7, gp, a2
                  sltu         tp, s3, s7
                  mulhsu       ra, t4, a7
                  sra          gp, s2, t0
                  c.add        gp, t2
                  and          t3, ra, a2
                  auipc        s6, 565170
                  csrrwi       s8, 0x340, 20
                  sltu         s5, s2, sp
                  c.nop
                  srli         s11, t5, 9
                  c.and        a1, a5
                  csrrwi       gp, 0x340, 10
                  csrrc        t6, 0x340, a5
                  c.nop
                  csrrsi       tp, 0x340, 0
                  srli         s8, ra, 8
                  and          t6, a7, s6
                  sltiu        s3, t1, -528
                  c.xor        a1, s0
                  csrrci       ra, 0x340, 23
                  or           s0, t2, sp
                  c.slli       t5, 7
                  c.mv         ra, sp
                  sub          t6, s6, s2
                  div          t1, s9, t6
                  csrrs        s6, 0x340, zero
                  or           s0, a7, ra
                  xori         s6, a2, 1559
                  c.slli       t2, 11
                  and          s0, s1, a2
                  csrrsi       s7, 0x340, 0
                  csrrci       s2, 0x340, 0
                  c.xor        a4, a5
                  c.add        s1, t5
                  c.andi       s1, 2
                  csrrsi       tp, 0x340, 14
                  addi         a6, zero, -1138
                  csrrwi       a5, 0x340, 26
                  c.slli       t1, 5
                  slli         s11, a2, 11
                  srl          a5, s9, a7
                  c.addi       t1, -1
                  nop
                  xori         s5, a4, 1235
                  or           t4, sp, ra
                  xor          ra, a6, a4
                  csrrw        a4, 0x340, a0
                  sll          s9, t2, s3
                  mulhu        a0, a5, a7
                  srli         ra, a0, 7
                  xor          zero, s3, a4
                  c.sub        s1, a0
                  ori          s6, t5, -1113
                  remu         zero, s5, s11
                  slli         t4, a4, 7
                  sub          t4, s8, a6
                  and          s9, s10, t5
                  c.lui        a1, 18
                  srl          a7, t5, t1
                  lui          s9, 244337
                  mul          a0, ra, t5
                  mulhsu       zero, zero, t2
                  xori         s8, s3, 178
                  c.and        s1, s0
                  c.and        a3, a5
                  csrrci       t1, 0x340, 0
                  csrrw        a6, 0x340, tp
                  srli         gp, a4, 21
                  c.slli       s5, 6
                  xori         s6, t1, 1808
                  sltiu        t4, s9, 1694
                  mulh         gp, tp, a4
                  div          t3, s9, t4
                  c.or         s1, a4
                  auipc        t3, 928699
                  c.lui        a0, 9
                  csrrci       t2, 0x340, 0
                  c.add        t3, s4
                  andi         t2, a5, -842
                  csrrs        s7, 0x340, a5
                  mulh         t4, s5, s2
                  or           s1, s11, t0
                  sra          zero, sp, s9
                  mulh         s8, tp, t1
                  div          a5, s4, tp
                  mulhsu       t3, s9, s7
                  auipc        a5, 112174
                  sltu         t0, s0, gp
                  csrrw        a5, 0x340, sp
                  c.srai       a4, 13
                  c.add        t1, s0
                  slt          s6, a5, a5
                  c.lui        tp, 30
                  mulhsu       s11, gp, a5
                  c.li         s6, -1
                  xori         a3, s6, -284
                  srai         a6, s11, 11
                  slti         a5, s8, -964
                  rem          s5, s7, t0
                  div          ra, ra, a6
                  c.add        a5, t0
                  c.addi       s6, 1
                  srl          gp, zero, t1
                  andi         a7, gp, 819
                  slli         s1, s6, 6
                  slt          t5, a7, a4
                  slli         ra, t2, 16
                  sra          t0, s7, s10
                  sltu         a0, s2, a3
                  c.srai       a1, 27
                  xor          t4, s3, s3
                  c.srli       s0, 1
                  lui          t4, 739312
                  mulh         a7, a2, t3
                  c.lui        a4, 18
                  c.xor        a3, a4
                  c.srli       s0, 9
                  div          tp, a4, s6
                  c.andi       a4, 20
                  csrrs        s9, 0x340, s7
                  divu         gp, t3, s8
                  sltu         t3, a3, ra
                  c.li         t1, 18
                  c.addi       tp, -1
                  mulh         s6, s10, a4
                  srli         a3, t4, 11
                  add          s11, a0, a1
                  c.mv         a5, s5
                  c.addi       a7, 31
                  addi         t4, a7, 1597
                  xor          t6, t2, tp
                  c.srai       a5, 31
                  slti         t1, s2, -311
                  c.andi       a4, 29
                  c.add        s2, s8
                  srl          t3, t3, s0
                  c.andi       a1, -1
                  c.srai       a3, 26
                  addi         a5, s3, -1521
                  c.sub        a5, a5
                  andi         t1, s11, -133
                  ori          a6, a2, -146
                  c.addi       s8, 2
                  c.srai       s1, 3
                  c.addi       t0, 5
                  divu         a6, s6, s7
                  srli         s0, s0, 7
                  auipc        t1, 626375
                  srai         s11, ra, 14
                  c.li         s6, 23
                  sll          s6, s8, t2
                  c.andi       s1, -1
                  c.sub        a0, s1
                  xor          a1, tp, s9
                  c.sub        a5, a4
                  ori          s7, t0, 827
                  csrrw        s11, 0x340, t2
                  c.sub        a5, a2
                  addi         s7, t2, 880
                  sll          a0, s2, a3
                  andi         t1, t2, 1704
                  c.li         s5, -1
                  mulhu        t3, t2, a7
                  rem          s3, gp, t4
                  c.xor        a4, a0
                  c.lui        a0, 7
                  slt          gp, s6, gp
                  srli         tp, s9, 27
                  mul          a4, s10, s5
                  sub          t3, t1, t5
                  andi         s3, t2, 1661
                  and          s4, s8, gp
                  slt          gp, zero, a3
                  csrrwi       a5, 0x340, 4
                  c.li         a6, -1
                  c.slli       s6, 5
                  slt          t0, s4, a4
                  sub          gp, sp, sp
                  csrrw        a1, 0x340, t5
                  csrrsi       a3, 0x340, 0
                  remu         a4, s8, zero
                  srai         gp, s10, 14
                  and          s3, s11, t5
                  c.add        t3, s5
                  csrrwi       t0, 0x340, 20
                  c.or         a0, a0
                  c.and        s0, a5
                  c.xor        a4, a4
                  mul          ra, s7, t5
                  ori          t6, t6, 802
                  slt          a1, a3, t5
                  and          s11, s6, a1
                  c.lui        t5, 2
                  and          a3, s0, t6
                  slt          a7, a0, s11
                  csrrwi       a0, 0x340, 21
                  xori         s0, t1, 578
                  c.xor        a5, a1
                  c.srli       a1, 11
                  srai         a5, a7, 16
                  c.andi       a0, 2
                  c.and        a4, a1
                  div          s8, a6, s4
                  mulh         t2, s3, s3
                  c.xor        a1, a0
                  c.and        a1, a2
                  c.li         s7, -1
                  mulhu        zero, gp, s1
                  or           t2, a5, s1
                  c.sub        s0, a0
                  sltu         t2, s6, s10
                  div          t2, s4, s9
                  xor          a5, a7, a7
                  srli         t2, a3, 11
                  c.srli       a5, 22
                  nop
                  c.or         a3, a4
                  c.li         s0, 1
                  sll          s6, a5, t6
                  c.andi       a0, -1
                  nop
                  c.nop
                  mulh         s1, a1, s1
                  mulhsu       t6, s9, gp
                  mulh         s1, sp, a2
                  divu         s3, s3, t5
                  c.sub        a4, a2
                  mulh         t6, t6, s10
                  csrrsi       gp, 0x340, 0
                  sltu         a5, a4, a6
                  sub          s11, s4, s0
                  csrrs        t0, 0x340, s4
                  lui          a6, 606809
                  mulhu        s3, tp, tp
                  mul          s7, t0, s6
                  sra          a5, s11, a2
                  c.nop
                  mulhsu       s11, a0, sp
                  ori          t4, s7, -1125
                  c.and        s1, s0
                  srai         s7, s10, 9
                  and          s6, tp, t1
                  c.or         a3, a3
                  c.addi       a1, -1
                  sub          a4, t6, s8
                  div          a4, a2, s11
                  c.and        a1, a3
                  lui          tp, 639444
                  csrrw        s6, 0x340, sp
                  div          ra, zero, a6
                  srl          t5, s4, s0
                  andi         gp, t4, 779
                  c.srli       a3, 15
                  c.xor        a0, a2
                  ori          gp, a3, 912
                  c.xor        a5, s0
                  srli         s11, a7, 30
                  c.or         s0, a4
                  slli         s0, s9, 27
                  c.sub        a5, s0
                  c.li         s5, -1
                  nop
                  auipc        s3, 329441
                  c.or         s1, a0
                  srli         t0, s4, 25
                  srl          s7, a7, a6
                  sra          s1, zero, a2
                  csrrw        s3, 0x340, a4
                  csrrci       a0, 0x340, 23
                  c.slli       s4, 6
                  lui          s5, 181856
                  or           t4, t0, a1
                  slti         zero, t3, 1647
                  c.lui        t3, 24
                  c.xor        a0, s1
                  csrrwi       s2, 0x340, 14
                  remu         tp, t5, s0
                  mulhsu       t3, s11, sp
                  and          a7, t4, s11
                  rem          s2, s2, a0
                  slt          tp, s5, a6
                  c.add        a6, a2
                  rem          a0, t4, t5
                  c.xor        s1, s0
                  mul          s5, s3, t0
                  csrrs        t5, 0x340, gp
                  xor          ra, s2, s11
                  nop
                  andi         s3, gp, 1534
                  c.andi       a4, -1
                  c.addi       a3, 28
                  and          ra, t5, s6
                  c.li         t1, -1
                  c.mv         tp, s6
                  sltiu        t1, s7, -1156
                  csrrci       s6, 0x340, 0
                  c.nop
                  ori          ra, s8, -1626
                  sub          s8, s5, t1
                  sub          t4, a6, s0
                  slt          tp, a2, t0
                  addi         a0, zero, 1894
                  sltu         a4, t1, s11
                  nop
                  c.addi       s7, 9
                  divu         s0, a4, s2
                  lui          tp, 207261
                  csrrwi       t1, 0x340, 27
                  lui          a0, 367718
                  sra          t5, s5, ra
                  c.and        s1, a4
                  andi         a5, tp, 1669
                  sll          s2, zero, gp
                  c.srli       a1, 10
                  add          a6, a6, t6
                  sltu         s7, t6, t6
                  c.lui        s9, 24
                  remu         s3, a3, s2
                  srai         gp, s7, 15
                  c.nop
                  rem          s4, ra, t6
                  csrrci       s4, 0x340, 23
                  csrrsi       t0, 0x340, 0
                  sltiu        a7, s7, 1576
                  sub          s9, t3, a3
                  csrrsi       a0, 0x340, 12
                  csrrs        t2, 0x340, zero
                  mulh         t2, t3, s2
                  div          a0, s7, s5
                  xori         s4, s11, -993
                  sll          zero, s3, s11
                  c.and        a0, a3
                  xor          t6, tp, s0
                  mul          s0, t6, a2
                  csrrw        t4, 0x340, t2
                  ori          a6, s2, -1768
                  c.andi       a3, 19
                  mul          s2, s1, s6
                  c.nop
                  or           a3, s0, a3
                  c.srli       a4, 15
                  csrrci       t3, 0x340, 19
                  div          s11, s9, sp
                  csrrci       s6, 0x340, 22
                  c.srli       a0, 4
                  sltu         t1, zero, a6
                  div          t5, a3, t5
                  c.mv         s4, a0
                  c.srli       a3, 19
                  c.mv         t0, a5
                  remu         a5, ra, tp
                  rem          s11, t6, s0
                  mulh         a7, t3, a5
                  sll          a1, t5, s10
                  mulhu        s6, t6, a7
                  c.lui        tp, 4
                  c.or         s0, a4
                  div          s4, t0, a2
                  mulh         s6, s11, a3
                  lui          s2, 74698
                  c.li         s3, 4
                  div          a6, t3, a2
                  slli         a1, sp, 1
                  lui          s8, 653321
                  srai         s4, a4, 24
                  csrrc        gp, 0x340, t1
                  xori         a4, tp, 1349
                  slt          t5, s7, t5
                  srai         s5, gp, 22
                  csrrsi       s7, 0x340, 0
                  mulh         t6, a1, tp
                  sltiu        a3, a4, -703
                  mulh         s4, s1, s0
                  srli         tp, gp, 21
                  mulhsu       s0, t3, s1
                  nop
                  csrrci       s0, 0x340, 0
                  slt          ra, s1, tp
                  c.and        a3, s0
                  rem          zero, s10, a5
                  mulh         a3, t1, s10
                  srl          s5, s0, t2
                  sub          s9, t1, a6
                  ori          a6, gp, 975
                  mulhu        s0, ra, a0
                  mulh         s11, s7, t1
                  nop
                  c.nop
                  c.mv         t1, s6
                  c.or         a3, a3
                  csrrw        s7, 0x340, t1
                  mul          s8, gp, a1
                  c.srli       s0, 14
                  rem          s6, s7, s0
                  addi         s9, a2, 1033
                  mulhsu       s11, ra, a0
                  andi         a0, s6, 2031
                  csrrwi       s2, 0x340, 2
                  c.xor        a5, a1
                  c.li         t2, -1
                  c.li         a3, -1
                  addi         s4, a7, 1069
                  add          t4, tp, s9
                  srli         s8, s8, 10
                  c.xor        a4, a0
                  andi         s5, t5, -1981
                  div          t2, s7, s1
                  xor          t1, t5, a1
                  c.and        a0, a3
                  sra          tp, s10, t4
                  csrrc        t5, 0x340, a4
                  c.slli       s0, 8
                  mulhsu       s8, s7, s10
                  csrrsi       s0, 0x340, 0
                  c.srli       a0, 8
                  xor          a4, a0, t6
                  slli         t5, t2, 5
                  c.sub        a1, a4
                  c.sub        a1, a4
                  c.xor        s0, a2
                  srli         s0, s1, 1
                  c.sub        s1, s0
                  c.nop
                  ori          s4, t6, -932
                  sltu         s8, ra, s10
                  c.and        a4, s1
                  slli         t6, t1, 12
                  div          t5, s3, s9
                  mulhsu       a6, t3, s4
                  c.add        s3, tp
                  c.or         a1, s1
                  c.li         gp, 12
                  c.srli       a1, 3
                  lui          t3, 488759
                  c.slli       t6, 16
                  nop
                  c.li         s1, 7
                  csrrwi       a6, 0x340, 4
                  c.srli       s0, 19
                  c.sub        a3, a4
                  or           s5, s1, a6
                  csrrwi       t6, 0x340, 27
                  c.srai       a5, 6
                  srli         s7, t2, 18
                  mulhu        gp, s0, t1
                  sll          t3, t6, s5
                  sltu         s5, t5, a2
                  andi         s5, gp, 1548
                  sub          a1, t1, t1
                  srai         t5, a6, 0
                  c.li         tp, 3
                  c.srai       a0, 26
                  csrrwi       a6, 0x340, 2
                  sll          a3, t1, s6
                  andi         t3, gp, 1495
                  and          s11, a6, s1
                  ori          s3, s0, 144
                  c.or         a3, s1
                  divu         t5, s4, t0
                  mul          t6, s9, zero
                  srli         tp, t2, 4
                  auipc        s2, 177812
                  mulhsu       a7, gp, a7
                  c.or         s1, s1
                  csrrs        s1, 0x340, ra
                  remu         t2, a5, s5
                  c.addi       s3, 4
                  c.slli       s11, 4
                  add          a6, a5, s8
                  c.sub        a5, a0
                  mulhsu       s9, a2, tp
                  c.srai       a4, 10
                  remu         s8, t3, s4
                  c.or         a3, s1
                  csrrwi       zero, 0x340, 16
                  csrrc        s11, 0x340, a3
                  auipc        a0, 824127
                  c.nop
                  sltiu        t0, t6, -1884
                  div          t5, t0, s2
                  csrrci       s7, 0x340, 0
                  c.mv         tp, s9
                  sltu         t4, gp, a0
                  rem          t6, gp, a6
                  srli         s3, t3, 8
                  c.lui        a3, 18
                  and          s7, s2, a4
                  c.andi       a4, 30
                  mulh         gp, a2, s4
                  c.srai       s0, 16
                  xori         ra, a7, -36
                  nop
                  c.srai       a5, 4
                  or           s5, s8, s10
                  csrrc        tp, 0x340, zero
                  or           s9, t1, zero
                  c.add        a3, t0
                  c.addi       a6, 20
                  c.li         gp, 4
                  rem          s5, a6, a7
                  c.srli       a0, 12
                  csrrsi       s0, 0x340, 0
                  slli         gp, s0, 1
                  c.xor        a5, s1
                  xori         a3, t6, 293
                  divu         s5, a5, a2
                  srli         s2, a2, 13
                  mulh         s8, s7, gp
                  lui          s3, 993804
                  srli         ra, s3, 14
                  c.srai       a1, 30
                  slt          s8, s8, s5
                  andi         s6, t1, -492
                  c.slli       a3, 30
                  csrrc        tp, 0x340, zero
                  mulhu        s1, t2, a7
                  add          s8, s6, t1
                  slt          s7, t0, s9
                  sub          ra, t4, t0
                  mul          tp, t0, t4
                  addi         t0, s7, 1171
                  c.mv         s11, a7
                  c.mv         t1, a0
                  c.or         s1, s1
                  slti         t2, a1, 1306
                  sltu         a1, s0, t2
                  csrrwi       s1, 0x340, 11
                  csrrc        s11, 0x340, zero
                  srli         s4, a5, 1
                  c.addi       s11, 16
                  and          t3, a7, zero
                  mul          ra, t4, s3
                  c.add        s11, s6
                  srl          s4, s10, s2
                  csrrci       a1, 0x340, 0
                  csrrci       s0, 0x340, 0
                  c.slli       a6, 26
                  mulh         a4, a3, sp
                  nop
                  mulhsu       s0, zero, s10
                  c.slli       s1, 11
                  nop
                  slt          a1, s10, t2
                  addi         a4, gp, 394
                  sltiu        a5, s1, -953
                  slli         ra, gp, 5
                  csrrwi       ra, 0x340, 26
                  c.lui        s4, 26
                  c.addi       t6, -1
                  c.or         a3, a4
                  mulhu        t6, s10, s7
                  c.sub        a0, s1
                  mulh         a0, sp, sp
                  srai         s2, s8, 22
                  and          a4, tp, a6
                  slti         t5, gp, 663
                  csrrc        a5, 0x340, zero
                  rem          s4, tp, s6
                  divu         s6, s3, t0
                  div          t1, s7, t1
                  xori         s3, s8, -354
                  sub          gp, a6, s8
                  xor          tp, s11, a4
                  add          s6, zero, t5
                  mulhu        s7, a5, t3
                  c.andi       a4, -1
                  sra          tp, t5, t4
                  mulhu        a0, a4, s8
                  c.sub        a4, a1
                  xori         t3, s9, -292
                  c.xor        a5, a5
                  slti         a6, ra, -1970
                  c.li         t2, 16
                  sll          s3, tp, s7
                  srai         a3, s8, 8
                  and          t5, t6, a4
                  mulhu        a0, s10, a0
                  ori          t6, a2, -1866
                  srai         s2, s5, 7
                  mul          a6, a5, a5
                  or           s9, s8, zero
                  slt          s9, t0, s3
                  csrrsi       s2, 0x340, 0
                  div          s2, s8, sp
                  andi         s9, a3, 167
                  auipc        s11, 355102
                  c.sub        a5, a3
                  c.or         a4, a1
                  c.nop
                  c.and        s0, s1
                  sra          s9, t1, s10
                  csrrs        s8, 0x340, zero
                  csrrs        s6, 0x340, zero
                  c.li         a6, 24
                  c.or         a5, a2
                  csrrw        zero, 0x340, a6
                  csrrs        tp, 0x340, zero
                  c.srli       s0, 11
                  c.or         s0, s1
                  andi         zero, sp, 894
                  csrrw        s3, 0x340, a6
                  auipc        ra, 239168
                  slti         a4, a1, -566
                  c.addi       a7, 20
                  slti         a0, s8, -686
                  divu         s2, s3, t3
                  c.or         a1, s0
                  c.srli       s0, 7
                  mul          t4, tp, a5
                  c.srai       a3, 11
                  srai         a0, a2, 26
                  mul          gp, s9, t5
                  auipc        t0, 583059
                  c.addi       t0, -1
                  sra          a4, t5, t6
                  c.andi       s1, -1
                  slli         s6, s2, 5
                  csrrci       s4, 0x340, 0
                  xor          s3, t1, tp
                  lui          s7, 237301
                  addi         s8, s4, 1827
                  slli         t3, a2, 5
                  mul          s2, s4, gp
                  or           s5, s2, sp
                  c.li         s11, -1
                  divu         s0, t2, s9
                  srl          s2, t2, t5
                  mulhsu       ra, t2, a2
                  mulhu        a4, t5, sp
                  mulhu        s6, a4, gp
                  and          s3, s5, a2
                  xori         tp, t0, -1717
                  csrrc        t1, 0x340, zero
                  addi         tp, a2, 1610
                  slt          t6, s9, s9
                  c.add        s4, t1
                  mulhsu       s0, s7, t0
                  sltu         ra, a7, t5
                  div          a4, t1, s9
                  ori          t2, s9, 579
                  csrrc        s0, 0x340, s9
                  srai         t6, t5, 27
                  csrrc        s9, 0x340, ra
                  c.slli       t0, 27
                  sltu         gp, gp, zero
                  sra          s4, a3, a3
                  sll          s3, t1, a7
                  csrrc        s8, 0x340, zero
                  slli         s4, s4, 25
                  auipc        gp, 759386
                  c.li         a3, -1
                  c.and        s1, a3
                  div          s8, a3, a0
                  csrrwi       t6, 0x340, 4
                  slt          gp, ra, a4
                  divu         s5, s11, t6
                  csrrci       s7, 0x340, 0
                  sra          s6, zero, s0
                  c.mv         tp, s11
                  mulhu        s3, sp, s7
                  c.andi       a0, -1
                  lui          ra, 243452
                  c.mv         tp, s2
                  and          s4, s7, s10
                  c.slli       s8, 31
                  and          t6, s2, tp
                  divu         s9, s7, a4
                  c.addi       a5, 16
                  csrrci       t1, 0x340, 16
                  c.nop
                  sll          t0, a5, s10
                  addi         s9, s0, -2038
                  mulh         s1, t4, a2
                  sra          a0, s7, s0
                  c.or         a0, a5
                  nop
                  c.add        s2, sp
                  c.andi       s0, 10
                  sltiu        a4, zero, 1172
                  lui          a3, 252769
                  nop
                  c.or         s0, s1
                  c.addi       s8, 25
                  csrrs        t1, 0x340, zero
                  csrrs        tp, 0x340, ra
                  csrrs        s1, 0x340, zero
                  xor          a6, t2, s2
                  ori          gp, a2, -1319
                  mulhu        s7, a6, a2
                  c.li         t5, 22
                  mul          t4, s10, a4
                  c.add        t6, s6
                  slli         s7, tp, 14
                  sll          ra, a3, a1
                  c.lui        s11, 4
                  slt          t2, t0, s2
                  andi         s6, a3, 732
                  remu         t2, s8, t6
                  slti         t1, zero, 509
                  slt          s8, a5, s9
                  xori         a5, s10, 1976
                  rem          tp, t1, t2
                  c.srli       a5, 23
                  mulh         ra, s7, a5
                  add          zero, a6, zero
                  c.srai       a1, 11
                  csrrci       gp, 0x340, 8
                  c.sub        s1, s0
                  nop
                  csrrsi       zero, 0x340, 0
                  sltiu        s11, a4, 473
                  csrrw        a0, 0x340, zero
                  c.srai       s0, 24
                  div          s11, a4, ra
                  c.add        s8, s2
                  mulh         a0, a6, s5
                  c.addi       s3, 14
                  c.addi       t6, -1
                  csrrwi       a6, 0x340, 21
                  andi         s6, s0, -1877
                  c.srai       s1, 24
                  addi         tp, s11, -717
                  csrrwi       s11, 0x340, 30
                  div          a5, s10, a3
                  srli         a0, tp, 13
                  and          t6, a1, s4
                  csrrc        t6, 0x340, zero
                  mul          t4, t5, s9
                  sra          s1, gp, s10
                  c.xor        a0, a0
                  c.li         s4, 29
                  srl          s8, s1, ra
                  div          s9, s4, t1
                  mulhsu       t6, t4, s3
                  slt          tp, sp, t3
                  div          s0, t6, s4
                  c.li         tp, -1
                  csrrwi       a7, 0x340, 4
                  c.nop
                  slt          a0, a4, t1
                  div          s8, t1, ra
                  srli         a5, s1, 18
                  c.lui        s0, 31
                  slti         s0, t4, -1305
                  remu         t2, a7, s11
                  c.mv         s8, gp
                  csrrs        s1, 0x340, zero
                  c.xor        a3, a1
                  c.sub        s1, a4
                  div          s7, gp, t5
                  c.mv         t6, a6
                  csrrwi       t1, 0x340, 5
                  lui          t1, 1026842
                  mulhsu       s8, t3, s7
                  srl          t2, s0, s9
                  csrrc        t3, 0x340, a0
                  or           s1, a2, t6
                  mul          t6, ra, a4
                  addi         t5, s9, -278
                  c.slli       a4, 11
                  ori          t4, t3, 740
                  auipc        a0, 214684
                  c.srli       a0, 5
                  nop
                  and          s2, t1, t4
                  c.addi       tp, 27
                  c.xor        a0, a4
                  andi         a0, t2, 1381
                  sltiu        s9, s0, -971
                  c.srli       a1, 22
                  c.slli       a6, 14
                  csrrsi       a0, 0x340, 30
                  lui          a0, 953402
                  c.addi       tp, -1
                  divu         a3, s8, a4
                  auipc        a4, 320090
                  csrrw        s8, 0x340, t2
                  c.nop
                  sub          a5, tp, s0
                  or           s0, a0, s9
                  or           t6, s7, s8
                  addi         s4, a1, 1513
                  andi         s8, s4, 1262
                  lui          s4, 646835
                  csrrci       zero, 0x340, 0
                  c.addi       t5, -1
                  and          gp, s9, t1
                  div          s2, a1, s0
                  csrrwi       a5, 0x340, 27
                  mulhsu       a4, t6, t0
                  c.lui        a3, 31
                  c.srli       a0, 3
                  srai         s9, a3, 29
                  c.add        s4, s1
                  slli         t1, s6, 30
                  sltu         ra, a3, s5
                  c.and        s0, s1
                  sltiu        a7, s5, -1709
                  c.and        a3, a0
                  and          a1, s7, a6
                  xor          s1, s10, s5
                  ori          s8, tp, 99
                  ori          s8, s3, 1160
                  c.slli       a6, 20
                  csrrsi       s0, 0x340, 0
                  ori          s4, t1, -1023
                  or           a0, s4, t3
                  csrrci       a4, 0x340, 21
                  sltiu        a6, t0, -1492
                  xor          ra, zero, s8
                  c.add        s0, s4
                  sll          s7, s0, t2
                  c.srli       a0, 15
                  srl          s9, s11, tp
                  srai         s7, s8, 28
                  slt          s3, a0, a0
                  csrrw        ra, 0x340, a0
                  xor          s8, a0, t1
                  auipc        a1, 248466
                  c.srai       s0, 10
                  andi         gp, s3, -1340
                  sltu         s11, s6, s10
                  add          s1, a7, s3
                  c.srli       a3, 30
                  sltu         t5, t4, a4
                  c.lui        s5, 3
                  nop
                  c.lui        ra, 14
                  addi         a3, ra, -145
                  csrrci       a0, 0x340, 0
                  csrrw        gp, 0x340, s0
                  sra          t5, s2, a4
                  csrrsi       s1, 0x340, 0
                  mulh         s4, s10, a6
                  mulhu        t3, t0, s11
                  c.sub        a4, a2
                  csrrsi       zero, 0x340, 26
                  c.slli       s0, 18
                  c.andi       a1, -1
                  csrrwi       s7, 0x340, 7
                  c.xor        s1, a5
                  c.or         a3, a4
                  sltu         s0, s11, s5
                  sra          a1, a0, s1
                  and          s4, s10, a5
                  c.andi       s1, -1
                  csrrs        a0, 0x340, t4
                  csrrsi       t6, 0x340, 0
                  mulhsu       a4, a1, t1
                  csrrc        a3, 0x340, zero
                  c.li         ra, -1
                  slti         a4, s3, -1134
                  c.srai       a5, 6
                  divu         t6, s1, a6
                  c.sub        a3, a2
                  csrrw        a5, 0x340, t2
                  csrrci       a3, 0x340, 15
                  sltiu        s4, t5, -83
                  xor          a5, s11, s2
                  mulhu        t1, s10, t6
                  c.mv         t6, t2
                  c.lui        s2, 31
                  nop
                  c.lui        a3, 22
                  c.and        a1, a0
                  c.lui        tp, 30
                  slli         s9, sp, 16
                  xori         ra, a2, 1244
                  srai         s7, a5, 7
                  and          s4, s1, ra
                  andi         s5, sp, -1186
                  slt          s3, s4, s0
                  ori          t3, zero, -1170
                  c.nop
                  xor          t4, a4, tp
                  csrrs        ra, 0x340, s0
                  sltiu        gp, t6, -977
                  c.sub        s0, a3
                  csrrwi       a5, 0x340, 30
                  c.li         t1, 28
                  c.xor        a3, a1
                  csrrsi       a6, 0x340, 0
                  mul          s1, a6, t3
                  xor          s1, gp, s8
                  xor          s1, s7, s8
                  xor          s5, sp, s8
                  or           s6, a4, t2
                  csrrsi       a5, 0x340, 0
                  mulhu        s2, a1, s2
                  c.slli       s1, 28
                  sltiu        t2, s11, -1263
                  c.lui        a3, 9
                  c.add        t0, s7
                  srai         t1, t3, 26
                  slt          s6, a5, s4
                  andi         s4, zero, 930
                  sltiu        s5, t3, 2025
                  slli         a6, s10, 8
                  nop
                  c.add        s9, a6
                  divu         s11, s6, a3
                  csrrwi       gp, 0x340, 10
                  slt          a1, s10, a3
                  nop
                  mulhsu       gp, s0, a1
                  csrrsi       t2, 0x340, 24
                  and          zero, t0, t3
                  addi         s11, a5, -1898
                  andi         t1, t2, 24
                  c.srai       a4, 2
                  xori         t4, s3, 167
                  c.li         s2, -1
                  srai         a4, s2, 15
                  xori         s5, ra, -768
                  mulh         a6, t1, s9
                  ori          s0, s10, -1372
                  mulhsu       a3, t5, t6
                  c.lui        a5, 12
                  slt          t6, s11, s8
                  c.or         a1, s1
                  c.lui        s4, 13
                  and          a3, a7, a7
                  c.xor        a0, a3
                  c.li         t0, 7
                  c.slli       s4, 27
                  c.srai       a1, 26
                  xor          a4, t1, a1
                  csrrw        s3, 0x340, s1
                  c.sub        a1, s0
                  divu         s1, a3, t1
                  csrrw        s9, 0x340, t4
                  slli         t2, t2, 12
                  mul          a0, a6, s10
                  c.nop
                  lui          a7, 371958
                  rem          t3, t1, t5
                  and          s6, a6, t5
                  c.li         s2, -1
                  csrrci       t6, 0x340, 0
                  mulhsu       s8, a2, s8
                  csrrci       t3, 0x340, 8
                  csrrsi       s0, 0x340, 0
                  c.mv         a1, s9
                  sll          s0, tp, a0
                  c.nop
                  nop
                  add          s11, s2, zero
                  divu         s7, s3, a4
                  sltiu        t1, s7, -611
                  auipc        a3, 641711
                  mulh         ra, s1, a5
                  csrrs        s11, 0x340, gp
                  sll          s8, t1, a6
                  divu         t1, t5, ra
                  csrrwi       t3, 0x340, 29
                  csrrs        t1, 0x340, tp
                  ori          a5, s2, -1680
                  addi         s9, s3, -1101
                  csrrs        t1, 0x340, zero
                  ori          gp, t5, 186
                  c.sub        a0, a3
                  csrrw        s2, 0x340, gp
                  c.mv         s4, ra
                  c.and        a0, s0
                  slt          s3, sp, s0
                  slli         a7, t1, 11
                  c.srli       s0, 31
                  add          s5, t1, a7
                  c.slli       gp, 14
                  lui          t6, 769501
                  mulhsu       a0, t4, s0
                  c.srli       s1, 24
                  c.li         t6, -1
                  mul          t5, s1, s11
                  lui          a5, 979310
                  slti         a4, s0, 579
                  sltiu        s6, t4, 1688
                  sll          ra, s5, a3
                  div          s5, s9, t1
                  and          t4, t3, s2
                  c.mv         t1, t5
                  c.or         a3, a2
                  csrrc        s6, 0x340, zero
                  slti         t3, s0, 568
                  c.and        s0, a0
                  csrrs        a3, 0x340, zero
                  rem          a5, t5, t4
                  c.sub        a3, s1
                  csrrwi       s2, 0x340, 18
                  addi         a7, t6, -1163
                  div          s1, a1, a6
                  ori          a0, zero, -887
                  c.srai       a1, 5
                  ori          a6, s6, 1357
                  nop
                  ori          a5, tp, 1319
                  div          s5, t3, a3
                  andi         zero, zero, -4
                  xor          s1, t1, s10
                  slt          a5, a3, t2
                  xori         s9, s10, -1260
                  c.addi       t0, 12
                  sub          ra, a2, t0
                  c.andi       s0, -1
                  add          tp, t4, s7
                  c.lui        s1, 2
                  c.xor        s0, a3
                  mulh         t2, a0, a0
                  sltiu        s9, a3, -1896
                  csrrc        s11, 0x340, zero
                  csrrwi       s6, 0x340, 15
                  c.xor        a3, a2
                  sub          s1, s3, t2
                  slli         tp, s2, 10
                  xori         t5, t4, 456
                  c.srai       a5, 5
                  c.srai       a4, 1
                  csrrs        a6, 0x340, s5
                  csrrsi       a6, 0x340, 0
                  c.or         a4, a1
                  sra          s11, a7, a4
                  lui          s4, 97927
                  mulhsu       a1, a4, s0
                  sra          t3, s2, t6
                  c.sub        a4, a2
                  csrrsi       t0, 0x340, 19
                  csrrc        t2, 0x340, s2
                  csrrwi       s6, 0x340, 5
                  lui          a5, 136008
                  c.add        a4, t4
                  sub          s1, zero, s4
                  sltiu        a5, a7, 585
                  csrrw        tp, 0x340, a0
                  c.or         a5, a5
                  srli         a7, t4, 15
                  sll          s1, a6, s0
                  csrrs        a0, 0x340, a1
                  mulhsu       a7, a3, s7
                  srl          s5, s3, a0
                  sub          s8, t1, s5
                  srl          a3, a3, sp
                  csrrw        s9, 0x340, s1
                  slli         gp, s11, 18
                  sll          t3, s11, s5
                  xori         s5, t2, 441
                  c.nop
                  or           s9, s5, s9
                  c.sub        a3, a4
                  c.nop
                  ori          t5, s1, 480
                  c.slli       t2, 23
                  c.srai       a0, 13
                  c.lui        tp, 21
                  andi         t3, s9, 723
                  sltu         t6, a5, a5
                  remu         a5, t2, s8
                  srl          a3, s3, gp
                  c.srli       s1, 23
                  c.slli       s0, 26
                  c.srai       a3, 22
                  sub          a7, a7, t0
                  mulh         t0, t5, s0
                  ori          a1, s3, -1423
                  slli         t3, t6, 20
                  lui          t5, 60505
                  c.andi       a4, 21
                  ori          tp, gp, 1841
                  c.add        s8, s6
                  c.srli       a3, 13
                  slt          t2, a1, a0
                  csrrw        s4, 0x340, s7
                  and          ra, t1, s5
                  rem          tp, a4, s2
                  srl          t2, t4, s2
                  sub          t4, s1, a4
                  divu         t6, gp, s9
                  c.srai       a3, 16
                  csrrw        s9, 0x340, t0
                  addi         s0, a4, -286
                  sltiu        t5, s3, -1466
                  srl          a5, gp, t4
                  c.or         a0, s0
                  xor          s7, t4, a4
                  slli         s9, t6, 28
                  c.addi       s0, 22
                  slli         t3, t3, 20
                  slli         s6, t1, 7
                  c.sub        a4, a0
                  ori          t0, a2, -216
                  c.lui        s1, 23
                  slli         t1, gp, 16
                  sub          s4, s4, s1
                  c.mv         s8, a5
                  c.slli       s7, 30
                  srai         s11, a3, 20
                  addi         s4, t4, 786
                  csrrci       s2, 0x340, 8
                  c.srli       s1, 12
                  c.srli       s1, 22
                  c.sub        a3, a2
                  sltiu        t2, t0, -983
                  c.and        s0, a4
                  csrrsi       ra, 0x340, 0
                  remu         t4, s1, s11
                  xori         a3, t3, 2014
                  c.or         s1, a0
                  c.srai       a4, 5
                  c.srai       a1, 5
                  mul          tp, t5, a3
                  csrrci       s4, 0x340, 24
                  mulhu        a7, t1, s7
                  mulhsu       s7, s3, a0
                  c.add        ra, t2
                  c.andi       s0, 11
                  mul          s11, t0, s9
                  csrrsi       a6, 0x340, 0
                  xor          a5, s11, t1
                  c.li         s9, 5
                  c.srli       a1, 13
                  sll          zero, s1, gp
                  and          s6, s0, s8
                  slti         a6, t1, -1961
                  csrrsi       a6, 0x340, 27
                  c.andi       s0, -1
                  c.add        t3, t2
                  csrrci       tp, 0x340, 14
                  c.and        a1, s0
                  slli         t5, a0, 28
                  andi         s9, t4, 1136
                  srli         t3, a4, 2
                  c.add        a3, ra
                  auipc        ra, 363006
                  slt          s2, gp, t5
                  mul          s8, s11, gp
                  c.li         t3, 18
                  c.nop
                  auipc        a5, 582774
                  c.add        a0, a1
                  slt          zero, s1, s10
                  srli         a7, tp, 7
                  c.addi       s1, -1
                  sltiu        s1, a1, 1647
                  rem          gp, s4, sp
                  c.lui        gp, 14
                  sll          t6, a1, a2
                  sra          a4, s1, a1
                  c.nop
                  c.xor        a1, a2
                  csrrw        a6, 0x340, s11
                  andi         t4, s7, -1737
                  sltiu        t1, ra, 78
                  lui          s1, 561873
                  sub          s7, a1, gp
                  c.nop
                  csrrwi       s11, 0x340, 2
                  lui          tp, 951116
                  c.srai       s1, 31
                  nop
                  c.addi       s2, 8
                  csrrsi       a0, 0x340, 0
                  csrrsi       a6, 0x340, 18
                  slti         s7, s9, 1016
                  addi         s11, s10, -739
                  slti         t4, s3, -231
                  csrrci       s7, 0x340, 0
                  mulh         a6, s6, s3
                  c.xor        a0, a0
                  sra          s0, s7, s3
                  mulhu        a0, a3, s11
                  c.nop
                  c.nop
                  remu         t6, s7, t6
                  c.mv         t2, a0
                  srl          s2, s0, t5
                  c.mv         s8, a7
                  c.lui        t4, 7
                  csrrci       gp, 0x340, 0
                  rem          s7, t1, a0
                  srl          s8, s8, a2
                  slli         a7, zero, 5
                  c.srli       s0, 31
                  and          s3, a5, s3
                  c.or         s0, s0
                  nop
                  andi         s4, t4, 960
                  c.xor        a3, a4
                  mul          t0, s0, t1
                  sltu         a4, gp, a6
                  sra          s9, a3, t3
                  csrrs        a1, 0x340, a3
                  srli         s9, t2, 3
                  xor          s2, a3, s3
                  srai         a6, s9, 30
                  add          a0, t4, a2
                  c.slli       s6, 16
                  div          t1, a3, s8
                  slt          s4, a2, s5
                  sltiu        ra, s5, -191
                  c.lui        t4, 16
                  srl          t2, t0, a2
                  csrrwi       a0, 0x340, 14
                  srai         s7, a2, 4
                  slt          s9, a1, zero
                  c.andi       s1, -1
                  c.sub        a5, a4
                  sltiu        t6, tp, -983
                  sra          s5, s10, a7
                  c.addi       gp, -1
                  csrrci       t2, 0x340, 27
                  sltu         s5, sp, s10
                  xor          ra, s1, t2
                  auipc        s1, 93563
                  and          s11, t5, a5
                  mul          gp, s2, a5
                  srai         a7, s3, 6
                  div          a5, ra, s8
                  sltu         a1, a7, t4
                  c.slli       s9, 26
                  c.lui        a1, 12
                  c.srli       a0, 23
                  c.and        s0, s1
                  c.add        a0, s4
                  srai         ra, s10, 6
                  sra          s5, s11, s0
                  c.xor        a1, s0
                  c.li         s2, -1
                  or           s8, sp, t6
                  remu         s3, a3, s2
                  c.slli       a4, 12
                  c.li         t6, -1
                  sltu         s9, s1, sp
                  mulhu        s8, t0, a5
                  mulhu        a1, s9, ra
                  and          t0, s2, a4
                  sltiu        a7, s1, -571
                  rem          s3, s7, s4
                  mulh         s2, s11, gp
                  sll          a5, a7, s2
                  sra          t6, s7, t5
                  andi         s3, sp, 219
                  c.or         s1, a2
                  c.srli       a0, 7
                  c.xor        s1, s0
                  csrrwi       a3, 0x340, 16
                  csrrwi       a6, 0x340, 3
                  mulh         t2, sp, a2
                  mulhu        a6, zero, t6
                  remu         s2, ra, gp
                  srai         zero, s0, 20
                  c.and        a5, a0
                  c.srli       a5, 19
                  slt          s3, t5, ra
                  c.lui        s7, 3
                  csrrw        a4, 0x340, tp
                  c.xor        s0, a3
                  divu         t0, s10, s6
                  c.add        a0, a3
                  or           s5, a3, a4
                  c.lui        s2, 9
                  c.slli       a7, 27
                  xor          t5, s1, s3
                  rem          s1, a0, sp
                  c.add        s8, a4
                  c.mv         s1, a3
                  rem          tp, a3, a0
                  sra          t1, a2, s6
                  srai         a0, a3, 21
                  c.sub        a3, a4
                  auipc        a4, 954551
                  ori          a4, s1, -1666
                  divu         t5, a0, a5
                  mulh         s9, t1, s7
                  sltiu        s11, a4, 1433
                  c.srai       a1, 18
                  add          a3, t5, s2
                  auipc        t3, 981391
                  rem          s3, ra, a3
                  divu         s3, a3, a1
                  or           s5, a3, t1
                  lui          t2, 697213
                  c.srai       a0, 9
                  mulhsu       s5, s6, t0
                  mulh         t4, sp, t6
                  csrrw        a5, 0x340, t0
                  srl          t2, a4, tp
                  c.add        tp, a6
                  nop
                  c.addi       t2, -1
                  rem          s0, t3, s5
                  slt          s3, a2, tp
                  c.sub        a0, a1
                  csrrw        t4, 0x340, t0
                  c.andi       a3, 26
                  ori          t6, s4, -2010
                  c.slli       t4, 18
                  sub          s3, t6, a0
                  add          tp, zero, gp
                  mul          s6, ra, s5
                  c.srli       a5, 14
                  c.addi       tp, -1
                  c.andi       a1, 7
                  nop
                  sub          a3, s11, a7
                  c.li         s3, 28
                  sll          s6, t2, t4
                  c.add        gp, t3
                  slt          s4, a1, s0
                  xor          zero, s11, a4
                  csrrwi       a1, 0x340, 26
                  mulhsu       t2, a6, a0
                  slt          s6, zero, ra
                  srli         zero, s10, 13
                  and          a7, t1, zero
                  add          t1, t3, t3
                  or           s5, a1, t1
                  c.nop
                  or           a0, s9, t4
                  c.srai       a1, 23
                  mulhsu       s9, a3, s3
                  c.slli       t1, 26
                  csrrw        gp, 0x340, s3
                  csrrc        t6, 0x340, s0
                  rem          gp, t6, s1
                  auipc        t0, 802311
                  xor          a7, t2, gp
                  sll          a3, s2, a1
                  divu         s2, ra, gp
                  csrrs        ra, 0x340, a2
                  sltiu        s8, zero, -1158
                  or           t4, t5, s4
                  slt          a6, s7, t3
                  addi         t1, s5, -1089
                  or           ra, t5, s0
                  csrrc        a7, 0x340, zero
                  c.slli       s4, 29
                  c.sub        s1, a3
                  slt          t6, t1, ra
                  c.mv         a1, t1
                  mulhsu       t0, t2, s10
                  c.mv         t3, a0
                  c.mv         a3, t3
                  rem          s11, a0, t6
                  auipc        s8, 675521
                  c.add        a5, s2
                  auipc        gp, 1024944
                  andi         a7, a3, -1894
                  c.li         s5, 6
                  csrrwi       a4, 0x340, 15
                  mulhsu       t0, s0, s2
                  slli         tp, t6, 16
                  c.or         s1, a1
                  ori          t2, zero, 587
                  auipc        s2, 536563
                  add          s3, a0, gp
                  xori         s8, s1, 731
                  lui          s2, 668791
                  xor          s7, ra, s10
                  c.slli       t1, 8
                  sra          s11, ra, a2
                  mulh         s11, s2, s10
                  c.xor        a0, s1
                  c.slli       s6, 4
                  sra          s1, s10, s2
                  slli         s7, a6, 30
                  srl          t4, zero, a1
                  rem          t4, a6, s4
                  srli         ra, s4, 8
                  sra          a7, a7, t6
                  xor          ra, t3, s9
                  or           s7, t0, a4
                  div          a7, s10, s4
                  c.add        s0, s1
                  slti         a5, t6, -1602
                  ori          s7, a1, 169
                  c.li         a6, 6
                  slt          a7, a1, s2
                  mulhsu       a4, sp, a2
                  csrrc        s8, 0x340, zero
                  csrrsi       zero, 0x340, 25
                  slt          gp, t6, t4
                  sltiu        a0, s0, 411
                  andi         zero, a1, -340
                  mulhsu       s11, s2, a0
                  auipc        a0, 598243
                  csrrw        t5, 0x340, a6
                  rem          t5, gp, a6
                  auipc        a4, 994418
                  auipc        s0, 914578
                  c.or         a0, s0
                  c.and        a1, a0
                  ori          t0, a2, -1598
                  xori         a4, s2, -895
                  slt          s3, t3, s9
                  or           a6, tp, sp
                  rem          t2, t5, gp
                  c.lui        t6, 5
                  ori          s0, s7, -244
                  ori          s3, t6, 1423
                  c.and        a3, a4
                  csrrc        t5, 0x340, zero
                  mulh         a1, t0, s6
                  add          t1, s11, s0
                  lui          a7, 994853
                  srl          zero, s11, s10
                  remu         s6, s10, s3
                  c.or         a0, a1
                  mulhu        t4, zero, a5
                  sra          s6, s4, a7
                  xori         s2, s0, -390
                  csrrs        tp, 0x340, a7
                  sra          s3, s6, s7
                  mul          t1, a1, zero
                  remu         a3, a5, tp
                  sll          ra, a6, t2
                  sub          s4, a6, a2
                  xor          tp, s11, zero
                  rem          s7, a5, a0
                  c.andi       s0, -1
                  sub          s4, t0, t0
                  slti         t0, a0, 751
                  c.sub        s1, a5
                  mulhsu       s4, t0, a1
                  mulhsu       a1, a4, a2
                  c.addi       s6, -1
                  mulh         s5, t4, t0
                  rem          t4, t0, a4
                  c.add        t3, s1
                  remu         s6, s1, a7
                  srli         t0, a3, 17
                  and          s5, t2, s7
                  sll          t4, a5, t0
                  csrrs        s3, 0x340, s6
                  slli         ra, a2, 10
                  sra          t1, t6, t6
                  c.mv         s8, a4
                  csrrci       s1, 0x340, 15
                  c.add        s3, t5
                  csrrsi       t6, 0x340, 0
                  csrrs        tp, 0x340, zero
                  c.andi       a3, -1
                  csrrw        t1, 0x340, s0
                  xori         a7, s5, -70
                  c.lui        s5, 5
                  srli         a7, t4, 27
                  mul          a7, a2, s1
                  sltiu        s6, s3, 218
                  c.and        a0, s1
                  lui          s1, 850588
                  xori         zero, ra, -819
                  csrrw        t2, 0x340, s6
                  c.and        s0, s0
                  csrrwi       t0, 0x340, 28
                  mulh         a1, a3, a1
                  ori          s0, t4, -2009
                  divu         t3, s0, s2
                  csrrs        t3, 0x340, gp
                  srl          t6, s4, s9
                  csrrw        a6, 0x340, s5
                  xor          s6, s3, s10
                  slti         zero, sp, 17
                  csrrci       s7, 0x340, 13
                  andi         t1, s4, 385
                  c.srai       a4, 24
                  sltu         a5, t5, t6
                  sra          s11, s9, s9
                  srai         s1, s11, 4
                  c.sub        s0, a2
                  srli         s7, s10, 12
                  c.nop
                  csrrs        s6, 0x340, s5
                  mulhsu       a4, ra, s7
                  mulh         a6, a5, s7
                  mulh         s9, s0, ra
                  div          a1, t0, zero
                  csrrsi       t6, 0x340, 0
                  c.lui        t1, 9
                  srai         a4, s2, 31
                  c.or         a4, a1
                  srli         t0, t6, 31
                  c.andi       a3, 31
                  csrrw        zero, 0x340, t4
                  sltu         s5, a6, a7
                  div          t0, s5, s7
                  rem          gp, t6, t0
                  c.nop
                  c.and        a5, a3
                  csrrc        zero, 0x340, zero
                  c.xor        s1, a2
                  c.andi       a1, 9
                  srl          s6, s3, s2
                  mul          t6, sp, s4
                  c.li         t4, -1
                  mul          s11, tp, s6
                  csrrw        s2, 0x340, t5
                  csrrs        t0, 0x340, zero
                  mul          a3, t2, s7
                  c.li         s9, 26
                  sltu         a7, a7, a0
                  c.and        a1, s0
                  c.addi       t2, 18
                  c.srli       s1, 22
                  sltu         a0, s4, t4
                  srli         s3, s6, 11
                  xor          tp, gp, s7
                  csrrs        t6, 0x340, s8
                  remu         s1, a6, a4
                  mulhsu       t5, a5, s3
                  c.srai       s0, 24
                  nop
                  andi         a1, s0, 1425
                  andi         tp, zero, 1890
                  c.li         s4, 1
                  c.srai       s1, 6
                  c.and        s1, a1
                  slti         ra, s6, 862
                  csrrw        a0, 0x340, s9
                  or           t2, s3, a3
                  nop
                  c.xor        a3, s1
                  c.sub        a1, a5
                  mul          a1, s10, t3
                  c.or         a3, a5
                  andi         t1, s5, 129
                  c.srli       a4, 27
                  csrrs        s1, 0x340, zero
                  sub          t5, tp, s6
                  slti         a1, s8, -1103
                  c.srli       a1, 15
                  c.srli       a3, 25
                  or           t3, s7, a0
                  csrrwi       a4, 0x340, 15
                  c.andi       a1, -1
                  slt          t3, s7, s1
                  c.xor        a5, a3
                  mulhu        ra, ra, t4
                  csrrsi       t3, 0x340, 14
                  xor          t3, s9, a3
                  srai         t4, s8, 6
                  and          a0, t5, a6
                  c.li         a3, -1
                  sub          s2, t3, a7
                  srai         s2, s0, 28
                  mulhsu       s6, a7, sp
                  div          t1, tp, a5
                  c.nop
                  csrrwi       s9, 0x340, 28
                  c.nop
                  rem          tp, t6, t1
                  c.srli       a0, 12
                  csrrci       t1, 0x340, 0
                  mul          s6, s4, s0
                  c.sub        a5, s0
                  sltiu        s9, zero, -97
                  nop
                  srai         s0, s6, 31
                  csrrs        a7, 0x340, s5
                  slli         s7, a6, 14
                  xori         ra, a6, 1410
                  csrrci       t2, 0x340, 9
                  nop
                  c.srai       s1, 9
                  srli         a4, t1, 15
                  slti         a4, a6, -1250
                  c.and        a3, s0
                  sll          t6, t4, a0
                  c.srli       s0, 12
                  c.mv         s3, t4
                  csrrc        t6, 0x340, zero
                  rem          s6, a5, s3
                  c.nop
                  c.nop
                  c.mv         t0, t0
                  c.and        a0, a3
                  slti         a4, s10, -1802
                  xori         s11, t5, -1940
                  mulh         s7, s1, a7
                  csrrs        ra, 0x340, zero
                  c.li         s7, 2
                  csrrw        s8, 0x340, t6
                  mul          s11, a1, t4
                  lui          t0, 18900
                  mulhu        tp, a4, t4
                  mulh         s2, ra, s0
                  divu         t5, s7, t1
                  csrrwi       s5, 0x340, 26
                  slti         t2, ra, -1057
                  srai         t4, s8, 5
                  mulhsu       s0, t1, t3
                  c.slli       ra, 4
                  sltiu        t1, t1, -455
                  c.andi       a1, 18
                  c.mv         s1, s6
                  slt          tp, ra, t5
                  xor          a1, tp, s1
                  csrrsi       s4, 0x340, 0
                  xor          t4, t2, sp
                  sltiu        gp, s4, -296
                  rem          t1, s5, t4
                  srai         s5, s11, 20
                  sltu         zero, sp, sp
                  div          s1, t2, s10
                  mulhu        s7, t2, s11
                  csrrci       a4, 0x340, 0
                  c.and        s0, a0
                  c.srli       a0, 19
                  c.slli       t3, 19
                  sub          s5, s5, a4
                  csrrwi       t4, 0x340, 28
                  srli         s4, s8, 13
                  xor          ra, a4, zero
                  c.nop
                  c.xor        s0, a2
                  c.lui        t6, 12
                  sll          s1, t6, a0
                  c.li         s5, -1
                  mulh         s4, ra, gp
                  c.andi       a3, 24
                  lui          s1, 583615
                  srai         t1, s6, 6
                  auipc        t0, 145440
                  c.andi       s1, 30
                  sub          a4, s0, s11
                  c.li         a7, 17
                  div          t2, s9, a5
                  c.andi       a5, -1
                  c.and        a4, a3
                  xor          t5, a6, t5
                  c.xor        s1, a2
                  mulhsu       s3, t1, sp
                  remu         s8, s3, t6
                  lui          t5, 55678
                  auipc        s1, 41165
                  sltu         t3, a5, gp
                  xori         s2, s5, 1299
                  sub          s9, a5, t5
                  mul          t5, s8, a1
                  and          s3, a5, s5
                  xor          s1, t4, t2
                  c.sub        a4, a1
                  slli         t0, a1, 26
                  srai         a3, s5, 4
                  srli         s2, s4, 27
                  csrrci       a6, 0x340, 0
                  c.and        s0, s1
                  mulh         s1, s8, sp
                  csrrwi       a1, 0x340, 0
                  mulhsu       zero, s11, zero
                  rem          s11, a5, a6
                  div          a0, gp, s5
                  or           a6, t1, t5
                  mulhsu       s4, s5, zero
                  sra          a1, s9, s9
                  csrrsi       t3, 0x340, 31
                  csrrwi       a1, 0x340, 14
                  lui          t0, 597602
                  mulhu        a7, a4, s4
                  andi         s1, s7, -420
                  xor          a4, s7, a2
                  lui          s2, 34843
                  auipc        s8, 458772
                  c.li         s3, -1
                  csrrsi       a5, 0x340, 0
                  srl          s6, a4, s6
                  or           a5, a0, t6
                  c.slli       s1, 10
                  c.mv         t6, tp
                  csrrc        a0, 0x340, s2
                  auipc        t6, 814760
                  slt          a7, t6, gp
                  lui          s4, 841605
                  div          a3, a6, zero
                  mulh         t4, a0, s3
                  slli         s6, a6, 30
                  mulhsu       t2, s1, tp
                  csrrc        s3, 0x340, zero
                  auipc        s3, 342732
                  remu         zero, a0, s8
                  and          s7, a6, s11
                  c.srai       a1, 28
                  csrrwi       a5, 0x340, 22
                  csrrci       t3, 0x340, 25
                  add          t3, s5, a4
                  c.srli       a5, 6
                  divu         tp, t3, a7
                  mulh         s4, a0, s10
                  c.lui        t4, 16
                  rem          a0, ra, a2
                  csrrci       t3, 0x340, 4
                  c.sub        a4, a0
                  c.add        s8, s10
                  slli         t5, t3, 31
                  rem          t1, t1, t0
                  sltiu        s11, gp, -605
                  c.sub        s1, s1
                  sltiu        tp, s4, 1285
                  c.or         a0, a5
                  rem          t4, s1, s5
                  sra          zero, a3, a0
                  lui          s5, 234824
                  c.and        a1, a3
                  c.li         t5, 8
                  or           a5, a3, s3
                  sltiu        s1, a3, 1734
                  add          s9, s10, s0
                  mulh         a6, s3, t4
                  sub          s0, t3, s7
                  andi         s3, s7, 1817
                  or           s4, tp, s0
                  andi         s0, t5, 1545
                  c.mv         s8, t6
                  c.slli       t6, 12
                  c.andi       s0, 19
                  xori         s6, s7, -557
                  c.srli       a3, 7
                  c.lui        t6, 11
                  nop
                  c.add        s3, a2
                  slt          tp, t5, a6
                  c.or         a1, a5
                  nop
                  sub          s6, a7, a3
                  or           a6, s3, s5
                  srl          s4, s0, sp
                  c.mv         s4, a3
                  slli         a5, s11, 19
                  slti         s1, sp, 365
                  add          a4, gp, a6
                  slli         a1, a5, 22
                  auipc        s5, 721909
                  rem          a5, tp, s9
                  c.nop
                  c.addi       t6, 3
                  or           s3, a7, zero
                  sltiu        t2, s9, -389
                  mulhsu       gp, s4, t0
                  c.and        a4, s1
                  xor          a4, s7, s11
                  remu         s7, s4, t0
                  sub          t4, a5, a2
                  srli         s7, s4, 8
                  lui          a5, 695460
                  mul          a1, s5, s2
                  csrrc        s0, 0x340, zero
                  c.nop
                  slli         s7, gp, 5
                  sll          t4, t3, t0
                  xor          s1, t6, a3
                  ori          s2, gp, -539
                  nop
                  mul          t1, t4, gp
                  c.nop
                  andi         tp, s1, -1661
                  xori         s3, s8, 859
                  mulhsu       s6, t0, t0
                  and          s5, tp, s3
                  csrrs        a0, 0x340, t0
                  sub          t3, s3, a4
                  xori         s6, s1, 125
                  c.slli       t2, 17
                  xori         ra, s0, 1132
                  csrrs        s6, 0x340, s4
                  mul          gp, s4, a5
                  srai         s11, s5, 11
                  csrrc        s6, 0x340, zero
                  sltiu        a3, s5, -113
                  lui          t2, 627120
                  c.or         a5, a1
                  c.andi       a1, 5
                  c.slli       s3, 2
                  and          s2, a4, a7
                  mulh         t0, s11, a7
                  remu         s5, a7, a7
                  and          s9, a0, a6
                  sltiu        s11, t0, -793
                  csrrwi       a5, 0x340, 31
                  mulhu        gp, s8, s10
                  c.add        t5, a3
                  sll          a0, zero, a3
                  c.add        tp, t3
                  lui          s8, 521770
                  csrrci       s6, 0x340, 3
                  divu         a6, t5, a0
                  c.srai       s0, 7
                  c.and        a4, a3
                  remu         a0, gp, zero
                  slli         s9, ra, 7
                  c.srli       s1, 16
                  c.mv         s11, t6
                  c.srli       a3, 22
                  add          s5, a3, sp
                  c.lui        tp, 28
                  mul          s11, s8, s9
                  nop
                  c.srai       a5, 29
                  csrrci       a0, 0x340, 8
                  or           zero, a1, a7
                  c.addi       s8, -1
                  c.srli       a1, 13
                  mulh         gp, a2, s1
                  xori         t6, t0, 232
                  c.li         t4, 10
                  srai         t5, t0, 6
                  ori          a3, t0, 858
                  slli         a5, s2, 14
                  auipc        s3, 5983
                  sll          s4, s5, s2
                  div          s8, a0, t3
                  csrrwi       t2, 0x340, 21
                  mulhsu       t0, a1, a3
                  sra          zero, zero, a7
                  slti         a1, s5, 716
                  ori          s11, s6, -1295
                  c.add        a7, s5
                  c.or         a0, a1
                  slti         s3, ra, -2030
                  add          s2, t5, t4
                  srli         s5, a3, 17
                  mul          a6, t2, t5
                  andi         s6, a7, -814
                  c.slli       t0, 29
                  xori         a7, t2, -144
                  srli         gp, s2, 22
                  c.xor        a4, s1
                  c.srai       a3, 8
                  div          t1, t1, s2
                  mulhsu       a7, t0, ra
                  xor          zero, t2, t6
                  csrrs        zero, 0x340, sp
                  slti         s6, t3, -143
                  csrrw        s1, 0x340, s11
                  c.mv         tp, a2
                  srli         s3, s2, 27
                  csrrwi       s3, 0x340, 11
                  slli         t5, s6, 18
                  xori         a3, s7, -543
                  ori          t0, t5, 804
                  srli         s8, a6, 3
                  auipc        a5, 773460
                  csrrwi       s1, 0x340, 23
                  c.addi       a5, -1
                  nop
                  srli         s4, s7, 9
                  csrrw        a4, 0x340, a2
                  c.mv         s4, s8
                  csrrs        t5, 0x340, zero
                  csrrwi       s11, 0x340, 10
                  mulh         t0, ra, a1
                  srli         s11, t0, 11
                  csrrwi       t1, 0x340, 10
                  c.addi       a5, -1
                  c.nop
                  c.nop
                  mulh         t0, t6, zero
                  xor          s11, a0, a1
                  c.xor        s0, a3
                  srl          s1, zero, a1
                  c.srli       a1, 7
                  c.li         a0, 27
                  srli         s4, s9, 31
                  rem          s2, s11, sp
                  csrrwi       s6, 0x340, 22
                  sll          s7, a5, a1
                  slt          a0, t3, s4
                  c.xor        a5, a3
                  c.addi       t0, -1
                  xor          ra, a1, a7
                  csrrsi       tp, 0x340, 0
                  c.or         a0, a5
                  c.xor        a5, a3
                  add          a0, a4, zero
                  slli         tp, a2, 15
                  slli         s8, zero, 25
                  c.andi       a3, -1
                  mul          zero, s4, s1
                  c.sub        a4, a2
                  auipc        s11, 318899
                  slli         a6, t3, 22
                  mul          ra, zero, s4
                  c.nop
                  csrrc        a1, 0x340, s4
                  c.srli       s1, 8
                  csrrs        a6, 0x340, zero
                  sltiu        s2, t0, 358
                  andi         ra, s1, -540
                  c.nop
                  c.slli       a4, 22
                  andi         a3, t3, -614
                  addi         t5, a2, 1169
                  divu         s0, s0, ra
                  c.addi       s0, 23
                  csrrwi       zero, 0x340, 11
                  divu         a6, a4, t5
                  xori         a4, s4, -1801
                  csrrci       t2, 0x340, 0
                  ori          s9, s9, -1129
                  c.add        s1, s7
                  c.nop
                  xori         t3, s11, 1665
                  sra          s7, s7, a1
                  sltu         a3, s0, a7
                  xori         s0, t6, 2005
                  c.or         a5, a4
                  c.srai       a5, 14
                  auipc        a4, 1001150
                  add          t5, zero, a7
                  lui          t4, 227874
                  slli         t2, s0, 26
                  csrrw        s4, 0x340, t3
                  add          s8, t1, a2
                  sltiu        a3, s1, 1843
                  sltiu        s9, s7, -234
                  csrrsi       a5, 0x340, 0
                  csrrc        s9, 0x340, s2
                  div          zero, a6, a3
                  c.andi       a1, -1
                  mulhu        s5, s8, t6
                  srli         s0, t1, 21
                  srl          s1, t4, s7
                  csrrw        s4, 0x340, a6
                  c.nop
                  srl          t5, zero, t5
                  csrrci       a0, 0x340, 0
                  c.xor        a5, s1
                  andi         s0, a6, 1125
                  c.lui        s11, 2
                  sra          t5, s6, a2
                  c.add        t1, s3
                  sll          t4, t4, s1
                  rem          zero, s5, a6
                  xori         s11, s11, -1027
                  sub          s1, t6, a5
                  csrrc        s4, 0x340, t3
                  xori         t0, sp, -862
                  csrrc        t5, 0x340, zero
                  srl          t2, a6, s3
                  c.lui        t0, 20
                  xor          s4, s9, t2
                  slt          s0, a7, t4
                  c.addi       s11, 25
                  add          s9, t4, s7
                  or           a7, s3, ra
                  csrrc        s7, 0x340, t4
                  div          t0, a7, t4
                  csrrsi       zero, 0x340, 0
                  c.andi       a3, 16
                  xori         t2, sp, -2036
                  srl          a1, s6, a5
                  lui          s5, 575456
                  c.nop
                  c.xor        a0, a2
                  c.andi       s1, -1
                  c.andi       a1, 7
                  c.andi       a1, 0
                  srai         s6, a5, 14
                  slli         t6, s4, 25
                  c.andi       s1, 27
                  xori         tp, s0, -1703
                  csrrc        s1, 0x340, tp
                  c.li         tp, 27
                  srli         zero, a0, 24
                  addi         a3, t1, 625
                  sub          t6, a5, s10
                  slt          a3, a7, s3
                  csrrci       s2, 0x340, 10
                  c.and        a0, a4
                  c.addi       s3, 1
                  csrrw        zero, 0x340, s11
                  andi         s9, a3, -424
                  rem          s2, sp, s1
                  c.mv         t6, s4
                  csrrw        a4, 0x340, zero
                  sra          s4, a4, a4
                  addi         a3, s5, -2035
                  sltu         gp, t1, t2
                  ori          a7, s0, -1348
                  mulhsu       a7, t2, t5
                  csrrsi       zero, 0x340, 0
                  srai         t5, a5, 1
                  c.add        gp, s9
                  sltu         a6, a2, t2
                  sub          t5, a6, s10
                  remu         s11, t6, a5
                  add          s4, t3, a5
                  slt          s8, tp, t3
                  mulhu        ra, s0, t5
                  rem          s9, a7, tp
                  slti         a4, s1, -171
                  andi         a6, tp, -461
                  c.andi       a0, 27
                  csrrs        s0, 0x340, s7
                  mul          a0, t1, s1
                  mul          gp, a4, ra
                  auipc        tp, 611686
                  rem          t3, s10, a3
                  csrrwi       t2, 0x340, 8
                  c.addi       t3, 21
                  mulhsu       s0, a3, a6
                  c.andi       a1, 7
                  lui          t5, 534249
                  add          s7, s5, a5
                  add          zero, t1, a3
                  addi         s2, ra, -1721
                  mulh         s11, s2, a6
                  and          s3, a3, a7
                  c.addi       s7, -1
                  addi         s9, s1, 272
                  mul          s8, s7, s2
                  c.add        a5, s11
                  or           s6, a1, s0
                  slli         zero, t6, 9
                  divu         a1, t0, a1
                  rem          a3, a3, a7
                  addi         t0, gp, -1288
                  sra          s8, a2, s9
                  lui          a6, 987872
                  div          t4, s3, t4
                  auipc        s0, 263311
                  auipc        t0, 643294
                  mulh         t2, s11, s3
                  mul          tp, a3, a7
                  srai         s8, t2, 11
                  c.nop
                  srai         s3, t0, 17
                  srai         s8, tp, 3
                  sra          t3, s2, a7
                  c.or         s1, a2
                  sll          tp, zero, s0
                  c.addi       s1, 29
                  csrrci       t0, 0x340, 24
                  c.srai       s1, 12
                  remu         a4, s3, s11
                  csrrw        s11, 0x340, a5
                  auipc        t5, 468740
                  c.xor        a5, s0
                  sltu         t5, a7, a4
                  andi         s5, s2, -1248
                  csrrci       t0, 0x340, 0
                  xor          a5, s11, sp
                  slti         t1, a6, 1495
                  or           gp, a6, a5
                  c.li         s0, 22
                  srl          s1, gp, s6
                  c.sub        a0, s0
                  csrrsi       zero, 0x340, 21
                  lui          gp, 99271
                  lui          s9, 722258
                  or           t0, a0, gp
                  sltiu        s8, a3, 1703
                  csrrwi       ra, 0x340, 11
                  lui          t1, 880659
                  c.slli       t4, 7
                  slt          ra, t2, zero
                  and          a3, s7, s1
                  c.sub        a0, a0
                  c.slli       tp, 18
                  c.sub        a3, a0
                  slti         s9, t5, -698
                  csrrs        a6, 0x340, zero
                  xor          t3, s9, s5
                  sltu         s5, gp, t1
                  div          a5, gp, t4
                  srai         s1, t0, 10
                  slli         t6, tp, 4
                  sub          a1, t6, s6
                  srl          s8, s3, s6
                  srl          s2, gp, t6
                  csrrw        t0, 0x340, s11
                  slti         s5, s9, -1174
                  csrrwi       t3, 0x340, 12
                  lui          t1, 820323
                  xori         t0, a4, -520
                  nop
                  c.lui        ra, 27
                  csrrc        t5, 0x340, s0
                  mul          ra, t4, s3
                  csrrs        s1, 0x340, s2
                  sll          ra, t2, s11
                  add          s5, t4, a7
                  srli         ra, ra, 10
                  c.srai       s1, 9
                  mulh         t4, s3, a5
                  c.or         a5, a4
                  c.sub        a5, a5
                  c.lui        t5, 29
                  c.mv         s9, t0
                  c.and        a4, a2
                  c.addi       tp, -1
                  lui          a0, 411838
                  c.add        gp, t0
                  mulhsu       s3, t6, s10
                  slli         t2, a2, 9
                  slt          ra, s5, a5
                  c.lui        t2, 8
                  c.xor        a0, a4
                  ori          s9, a7, -1509
                  mulhsu       a6, t2, t0
                  c.or         s0, s0
                  c.or         a1, s1
                  andi         t2, s2, 978
                  lui          a5, 1030252
                  csrrs        s1, 0x340, s2
                  csrrw        s4, 0x340, t4
                  slli         t6, s2, 0
                  c.xor        a5, a0
                  sltu         s4, s11, a4
                  c.slli       t3, 29
                  c.add        t0, s10
                  c.xor        a5, a2
                  slli         s7, t2, 15
                  add          t4, t3, s5
                  c.andi       a3, 10
                  div          zero, s3, s4
                  c.lui        a3, 31
                  c.xor        a5, a4
                  c.addi       gp, 26
                  sll          t6, ra, a3
                  remu         a0, a3, s8
                  remu         gp, t4, s8
                  slti         s9, t2, 1975
                  c.addi       s2, 12
                  auipc        a0, 305618
                  div          zero, a6, t2
                  sltu         s5, s9, s3
                  sra          s0, gp, a3
                  c.lui        s6, 23
                  andi         s8, s10, 1529
                  csrrwi       s9, 0x340, 22
                  mulhu        zero, gp, sp
                  nop
                  srli         s6, t2, 7
                  mulhsu       s7, s7, a2
                  nop
                  c.xor        a1, a4
                  csrrc        s3, 0x340, a5
                  slt          t1, s7, t3
                  c.sub        a4, a3
                  c.addi       s8, 25
                  csrrc        a3, 0x340, zero
                  srai         a3, s0, 21
                  c.nop
                  divu         zero, a0, zero
                  add          a3, s4, s10
                  mulhsu       a5, zero, a2
                  c.li         t2, -1
                  c.or         a3, a1
                  srai         ra, a5, 21
                  auipc        s2, 815839
                  remu         a7, ra, sp
                  or           t3, t0, s3
                  mul          zero, a0, t4
                  c.slli       tp, 17
                  and          s4, sp, s2
                  xori         s2, s8, -1179
                  mulh         s0, a2, s6
                  lui          a0, 912497
                  csrrwi       s3, 0x340, 18
                  csrrwi       a4, 0x340, 19
                  c.srai       a5, 25
                  mulhu        s1, s9, sp
                  c.add        t2, ra
                  and          t1, a0, s11
                  xori         a3, a2, 1408
                  c.mv         t5, s3
                  lui          s2, 979126
                  c.srai       s1, 26
                  srai         s3, s10, 25
                  addi         t1, a7, -967
                  div          t1, a0, t1
                  sll          s7, a0, a0
                  remu         s7, t0, ra
                  c.mv         t2, ra
                  c.add        s9, t5
                  xor          t1, a0, t1
                  c.nop
                  c.slli       a7, 1
                  srai         s11, zero, 29
                  csrrwi       t1, 0x340, 0
                  csrrc        a0, 0x340, s2
                  sltu         a7, gp, s7
                  srli         a7, t5, 13
                  csrrs        a7, 0x340, zero
                  xor          s8, ra, a1
                  sll          s4, t4, a6
                  slli         s4, s5, 31
                  divu         s11, tp, gp
                  xori         t3, s3, -1827
                  lui          t1, 66981
                  divu         s5, a5, s11
                  sltiu        zero, s6, 729
                  xori         a0, a2, 1693
                  csrrsi       s8, 0x340, 16
                  remu         t2, a2, a0
                  c.or         a4, a3
                  ori          a0, a3, -1729
                  c.andi       a0, -1
                  mul          s3, s1, ra
                  csrrc        ra, 0x340, a0
                  c.add        s0, gp
                  and          s7, t1, s9
                  xori         a6, a4, -269
                  sltiu        ra, t2, -1239
                  rem          s2, s1, s6
                  slti         a5, s8, -1346
                  sltu         s5, a3, t4
                  csrrsi       a4, 0x340, 17
                  srai         s1, s7, 6
                  remu         s7, t5, sp
                  csrrc        t0, 0x340, t5
                  csrrc        t4, 0x340, zero
                  sub          t2, s3, t4
                  c.xor        a1, a4
                  csrrw        a0, 0x340, s6
                  slli         s9, s6, 30
                  nop
                  srai         s6, tp, 30
                  c.lui        s7, 22
                  auipc        zero, 34986
                  csrrci       t2, 0x340, 0
                  c.nop
                  mulhsu       gp, s3, s1
                  c.addi       s11, -1
                  c.andi       s0, 19
                  c.srai       a5, 17
                  divu         s1, a6, s10
                  c.xor        a5, a1
                  nop
                  srai         t5, s2, 17
                  sll          s2, ra, zero
                  c.srli       s1, 13
                  xori         s5, zero, -1829
                  add          t1, s9, zero
                  slli         a3, s5, 9
                  divu         gp, s9, tp
                  slli         a1, s1, 23
                  c.srli       a1, 2
                  mul          s3, ra, a0
                  or           t3, s5, zero
                  srai         s7, s9, 15
                  c.mv         t2, s11
                  csrrci       a6, 0x340, 23
                  nop
                  mulh         gp, s2, s2
                  c.nop
                  nop
                  csrrc        s9, 0x340, s0
                  or           s0, s1, a1
                  addi         s4, s9, -848
                  sub          t2, gp, tp
                  c.lui        s6, 21
                  csrrsi       zero, 0x340, 12
                  c.andi       s1, -1
                  slt          a6, a5, gp
                  divu         s9, s9, t6
                  srl          s5, s6, s8
                  csrrwi       s5, 0x340, 0
                  mulhsu       t2, a1, s1
                  c.sub        a4, a2
                  sub          t4, gp, s2
                  mulhsu       ra, gp, a1
                  slli         ra, a7, 24
                  ori          a1, a5, 12
                  c.xor        a5, a0
                  xori         a3, t1, -1815
                  slt          gp, a4, t1
                  slti         gp, a7, 1013
                  sltu         s11, t0, s11
                  c.slli       tp, 3
                  lui          t5, 477591
                  slli         a0, a7, 22
                  c.xor        a4, a1
                  addi         gp, s4, 1034
                  andi         s3, sp, -1119
                  sra          t1, a7, t4
                  csrrc        s3, 0x340, zero
                  c.andi       a5, 29
                  csrrci       s5, 0x340, 17
                  c.xor        a1, a1
                  mulh         t2, t0, t3
                  sra          a4, s11, a0
                  slli         s0, a7, 6
                  c.or         s1, s1
                  ori          s8, a3, 807
                  div          a4, t5, t6
                  csrrci       s5, 0x340, 14
                  mulhsu       t5, a0, a1
                  sltu         ra, a4, zero
                  sra          s2, zero, s7
                  divu         a6, s3, tp
                  slli         ra, s5, 14
                  lui          s5, 254982
                  c.or         a1, a0
                  srli         t3, a6, 28
                  c.xor        a1, a1
                  sub          s11, gp, a7
                  sltu         s2, s4, a6
                  addi         s1, s8, 1125
                  csrrw        t6, 0x340, s9
                  c.mv         t1, ra
                  mulhsu       s7, t6, a7
                  mulhsu       t1, s0, s6
                  or           a0, a0, ra
                  mul          a5, tp, t2
                  addi         t4, gp, 1500
                  c.xor        a4, a3
                  mul          t2, s10, s4
                  slt          t5, s7, s11
                  ori          a3, a3, -540
                  srl          s0, a0, a6
                  rem          a0, s3, s2
                  csrrwi       s9, 0x340, 3
                  csrrci       s0, 0x340, 1
                  c.sub        s1, s0
                  mulhu        a6, a5, t5
                  c.srai       a1, 23
                  csrrci       s4, 0x340, 30
                  c.and        a0, a2
                  csrrci       tp, 0x340, 26
                  c.sub        a3, s1
                  divu         s3, s2, t6
                  c.srli       a1, 10
                  srli         t1, t0, 8
                  remu         s7, a1, s5
                  sltiu        tp, s5, -627
                  sltu         ra, a2, s10
                  c.add        a5, s1
                  c.add        s9, t1
                  addi         a1, s5, -529
                  srai         tp, s3, 2
                  c.slli       t6, 10
                  or           t1, t5, t4
                  nop
                  andi         a6, s7, -234
                  c.srli       a5, 4
                  csrrsi       t5, 0x340, 0
                  ori          s4, a5, -586
                  csrrc        zero, 0x340, zero
                  xori         a0, a1, 887
                  mul          s2, ra, s5
                  slt          a0, t6, s1
                  add          a6, s5, gp
                  ori          s5, ra, -477
                  c.lui        s2, 2
                  c.slli       tp, 30
                  lui          t1, 10557
                  c.slli       s1, 24
                  c.mv         s2, t3
                  mul          zero, t6, ra
                  or           s6, t5, s4
                  remu         s1, a1, s8
                  srl          s5, t6, a2
                  c.sub        s0, a5
                  sll          s7, s2, s8
                  c.srai       a0, 19
                  slt          s9, s3, t3
                  mul          s9, s2, s6
                  sub          ra, s6, tp
                  nop
                  c.srli       a1, 11
                  c.add        s11, s7
                  nop
                  slli         a3, s3, 30
                  c.srai       a3, 23
                  srl          s7, s10, s4
                  rem          a3, s3, a4
                  sra          s9, t5, a6
                  andi         a4, s5, 539
                  csrrci       s9, 0x340, 11
                  andi         a3, a3, 189
                  c.mv         t1, s0
                  mul          t5, a1, a1
                  c.nop
                  csrrwi       s11, 0x340, 24
                  mulh         t5, zero, a5
                  rem          t2, a5, a2
                  or           t3, s5, t6
                  c.andi       s0, 14
                  csrrwi       a3, 0x340, 6
                  auipc        t5, 342576
                  csrrci       t0, 0x340, 3
                  c.sub        a5, a1
                  lui          t1, 242824
                  csrrsi       s9, 0x340, 0
                  auipc        s7, 785722
                  sub          s5, s1, a6
                  sll          t6, a7, a1
                  slli         a7, a5, 17
                  csrrs        s4, 0x340, zero
                  ori          s11, a0, 1448
                  csrrci       t4, 0x340, 0
                  c.li         a7, 17
                  srl          zero, t6, s9
                  csrrw        s8, 0x340, s6
                  c.srai       s1, 14
                  c.xor        a0, a4
                  c.nop
                  xori         zero, t3, -1123
                  csrrw        ra, 0x340, s2
                  slli         t0, a4, 27
                  c.addi       s5, -1
                  or           t3, a4, ra
                  sra          tp, s7, a4
                  div          s1, t0, s9
                  xor          t6, s10, a2
                  c.nop
                  mulhu        a5, tp, s5
                  addi         s4, t0, -903
                  slt          s1, tp, a0
                  c.or         a0, a3
                  andi         s3, a0, -831
                  lui          a1, 1041004
                  c.xor        s1, a4
                  c.xor        s1, a5
                  c.mv         a5, t3
                  sltu         s5, tp, t0
                  mul          a1, a0, s8
                  srli         zero, s1, 21
                  c.srli       a5, 25
                  sll          t4, ra, a0
                  c.nop
                  c.slli       t2, 3
                  remu         ra, s0, t4
                  sltiu        zero, t1, -940
                  sll          s6, a5, s5
                  csrrwi       t2, 0x340, 10
                  c.li         a3, -1
                  c.sub        a1, s1
                  c.xor        a0, s1
                  and          s2, a2, t5
                  srli         s3, s4, 17
                  sltu         s2, t3, s10
                  addi         s8, s0, 213
                  mulh         s0, s6, zero
                  csrrs        s4, 0x340, zero
                  andi         s8, s6, -143
                  csrrs        zero, 0x340, zero
                  mulhu        s2, t0, t0
                  c.srli       s1, 6
                  mulhu        s8, a2, t5
                  csrrwi       a4, 0x340, 1
                  mulhu        a5, t2, gp
                  csrrwi       s9, 0x340, 13
                  csrrw        s1, 0x340, s1
                  lui          t6, 824701
                  csrrw        s8, 0x340, s8
                  mulhu        s11, a2, s1
                  ori          ra, s2, -1091
                  csrrwi       a3, 0x340, 27
                  csrrs        t1, 0x340, zero
                  c.sub        a0, a1
                  add          s0, s9, t6
                  slt          a5, a5, s2
                  sltiu        s11, t5, -141
                  c.lui        s0, 3
                  c.addi       s0, -1
                  c.xor        s1, s0
                  mul          s3, ra, a0
                  slt          s3, s9, t5
                  mulhu        a6, gp, s4
                  srai         tp, s8, 20
                  c.xor        a5, a1
                  csrrc        a6, 0x340, s6
                  addi         s2, t4, -381
                  lui          zero, 364226
                  c.lui        a1, 6
                  remu         a6, zero, s2
                  mulh         a3, gp, a6
                  csrrci       s6, 0x340, 9
                  nop
                  c.srli       a1, 4
                  c.and        s1, a4
                  and          ra, t5, s11
                  c.nop
                  c.mv         t0, ra
                  csrrwi       s7, 0x340, 31
                  c.li         t3, 23
                  slt          a4, t2, a0
                  andi         t3, s4, -115
                  c.slli       s2, 4
                  csrrc        s4, 0x340, zero
                  c.slli       a3, 18
                  sltiu        s0, t0, -928
                  remu         t1, s9, s1
                  slt          tp, zero, a1
                  sub          t4, t5, a1
                  csrrw        t2, 0x340, zero
                  c.xor        a1, s0
                  csrrs        s8, 0x340, zero
                  slt          t6, s2, s11
                  div          a0, t0, s6
                  c.addi       a0, -1
                  c.mv         t0, s2
                  lui          t0, 767802
                  slli         s2, s11, 13
                  csrrc        s11, 0x340, a1
                  ori          s7, s3, 1106
                  csrrw        a0, 0x340, s2
                  c.srai       a5, 10
                  andi         t4, t5, 969
                  srli         ra, a3, 10
                  c.slli       t5, 21
                  remu         t0, t0, ra
                  csrrwi       a1, 0x340, 16
                  lui          t2, 801341
                  sll          a6, a5, s3
                  lui          t6, 256642
                  c.nop
                  csrrwi       a6, 0x340, 17
                  c.slli       a4, 30
                  div          ra, gp, ra
                  divu         ra, a2, s10
                  c.mv         s6, s6
                  sra          a4, t1, tp
                  or           a6, s1, s6
                  slt          gp, t5, t4
                  andi         t2, s8, -1864
                  csrrci       s7, 0x340, 20
                  csrrw        s11, 0x340, a3
                  sltu         zero, s6, zero
                  csrrw        a4, 0x340, a7
                  c.sub        a5, a3
                  c.or         a1, a2
                  csrrsi       t5, 0x340, 6
                  sltiu        s5, s3, 1256
                  sltiu        s5, a0, 313
                  or           t3, a4, a6
                  andi         t3, t1, -1225
                  slli         t6, s7, 12
                  and          s2, a6, t2
                  c.add        tp, t0
                  csrrsi       gp, 0x340, 0
                  srl          a5, s5, ra
                  addi         s3, t6, -1771
                  csrrw        a1, 0x340, s2
                  sltiu        a5, s11, -789
                  c.andi       a4, -1
                  c.and        a1, a0
                  or           a5, s8, s10
                  sub          a5, s1, a2
                  slt          s4, sp, a7
                  c.andi       s1, 28
                  c.sub        a1, a0
                  srli         a1, s0, 1
                  mulhsu       s1, t3, a1
                  mulhsu       s9, t4, t4
                  c.nop
                  and          gp, s4, t1
                  c.xor        s0, a5
                  mulhu        t3, s1, t4
                  c.add        a4, s1
                  c.or         a1, a2
                  c.lui        t5, 22
                  sub          t1, zero, ra
                  auipc        gp, 1037716
                  mulhu        a6, ra, a7
                  c.or         s1, a0
                  and          t5, sp, a2
                  or           s2, a3, s3
                  csrrci       a5, 0x340, 0
                  slti         s0, t2, -683
                  ori          t0, s1, 1595
                  csrrw        ra, 0x340, t0
                  lui          t1, 660159
                  c.andi       s0, 13
                  sll          s3, a1, a1
                  lui          s4, 772668
                  csrrwi       a4, 0x340, 19
                  mulh         a1, s11, t0
                  mul          a7, a0, a3
                  c.and        a5, a0
                  xor          s1, s7, t6
                  c.mv         tp, a5
                  slti         t2, s6, 1343
                  c.slli       s5, 4
                  mulhsu       s6, s3, t6
                  csrrsi       s4, 0x340, 18
                  c.mv         s5, ra
                  c.andi       s0, 4
                  addi         t2, zero, 1193
                  remu         a5, s1, s9
                  c.mv         ra, a6
                  auipc        a4, 824590
                  c.lui        s1, 11
                  srl          s8, t2, a3
                  addi         a3, a5, 2017
                  c.lui        gp, 31
                  auipc        t2, 379896
                  srli         s9, a7, 1
                  srl          tp, t6, ra
                  csrrci       a4, 0x340, 9
                  rem          s0, s11, s6
                  div          a3, t0, t2
                  c.mv         t1, s1
                  divu         t0, gp, s7
                  lui          t3, 391492
                  div          a4, a0, s7
                  c.or         s1, s1
                  srli         gp, t5, 19
                  c.slli       a3, 28
                  slt          gp, t0, t2
                  c.srli       a5, 2
                  sltu         s3, a1, s4
                  lui          gp, 1033490
                  c.or         a1, s0
                  srai         s9, t0, 13
                  mulhsu       gp, tp, s11
                  div          s0, a3, zero
                  mulhsu       s0, a1, s0
                  c.xor        a4, s0
                  xori         s5, a6, 323
                  srl          t1, a0, a1
                  or           t0, s11, s9
                  sll          t4, a1, a4
                  c.srai       s1, 1
                  divu         s0, a1, a5
                  c.andi       s0, -1
                  and          s9, s1, a0
                  c.xor        a4, s1
                  c.xor        a4, a1
                  nop
                  nop
                  csrrs        t5, 0x340, zero
                  srl          s7, t0, s5
                  c.mv         s2, t0
                  and          s0, a2, sp
                  add          s4, s7, s9
                  sub          s2, s10, a1
                  mulhu        s1, a1, s2
                  xori         s3, t2, -583
                  add          t1, t0, s5
                  sub          t0, a2, s11
                  nop
                  remu         gp, s5, t3
                  or           s5, s10, a2
                  divu         gp, a0, ra
                  rem          s3, tp, s7
                  sltiu        a0, s0, -1835
                  c.addi       t0, 11
                  c.add        t5, t6
                  c.and        a3, a3
                  div          gp, a7, a3
                  mul          gp, s11, t3
                  c.addi       a0, -1
                  sra          t6, s11, ra
                  c.srai       s1, 23
                  c.slli       s4, 27
                  sra          s1, a7, s2
                  csrrw        s8, 0x340, gp
                  c.sub        s1, a4
                  csrrw        a5, 0x340, t3
                  srai         t1, a5, 15
                  sll          t2, a0, a4
                  addi         s9, zero, 1827
                  div          t3, s10, tp
                  c.srai       a1, 7
                  c.li         a7, 29
                  c.and        a5, a3
                  and          a5, s10, t4
                  ori          s2, a5, 1481
                  sub          gp, s3, s0
                  c.xor        a4, a4
                  rem          tp, sp, a0
                  csrrwi       t6, 0x340, 28
                  or           s4, t6, t4
                  divu         t2, s11, t1
                  lui          s4, 19667
                  c.andi       s1, -1
                  xor          a6, t6, s1
                  srl          a3, zero, zero
                  mulh         t1, t1, a6
                  c.nop
                  c.sub        s1, s0
                  divu         t2, a5, t4
                  csrrs        tp, 0x340, zero
                  csrrsi       a7, 0x340, 0
                  slli         a7, s9, 9
                  mul          t6, ra, s9
                  mul          s6, a3, t0
                  divu         s6, s4, t5
                  c.srli       a1, 23
                  c.add        a3, t0
                  andi         ra, s2, 1389
                  c.add        t1, t5
                  csrrsi       t5, 0x340, 0
                  csrrw        t6, 0x340, a1
                  mulhu        zero, t4, tp
                  c.lui        t4, 1
                  srl          s0, s9, t1
                  sub          a7, s2, s2
                  csrrwi       gp, 0x340, 29
                  c.li         t0, 7
                  sra          s11, s7, t0
                  c.srli       a0, 23
                  csrrci       s9, 0x340, 0
                  c.or         a1, s1
                  csrrc        zero, 0x340, t2
                  c.mv         t6, s8
                  c.or         a3, a3
                  slli         a3, t4, 11
                  slti         t1, a6, 520
                  csrrci       s8, 0x340, 0
                  remu         t4, t4, t1
                  or           s11, tp, s2
                  lui          a1, 507059
                  c.xor        a4, a5
                  sub          gp, a6, t2
                  csrrw        t0, 0x340, sp
                  srli         t2, a1, 4
                  srai         a7, t1, 23
                  csrrc        t5, 0x340, s4
                  c.nop
                  srli         a3, s3, 11
                  mulhsu       s3, sp, t1
                  c.andi       a1, -1
                  c.add        a4, s0
                  slti         a0, t2, 21
                  srl          s4, s1, t3
                  c.andi       s1, -1
                  or           t6, s10, s10
                  or           a1, s9, zero
                  c.sub        a0, s0
                  div          t1, a1, a1
                  csrrsi       a3, 0x340, 8
                  c.sub        a3, a1
                  c.srai       a0, 15
                  csrrw        s4, 0x340, s5
                  csrrc        s5, 0x340, zero
                  xor          s6, t0, a0
                  srai         s7, a6, 14
                  c.and        a1, a3
                  c.srai       s0, 22
                  sltu         t6, t2, s10
                  slti         a6, t6, -1948
                  csrrs        t3, 0x340, a4
                  c.mv         a6, a6
                  c.or         a4, a4
                  c.add        a7, s3
                  or           gp, s2, t3
                  c.or         a3, a3
                  slti         s11, a0, -1458
                  csrrw        s6, 0x340, sp
                  xori         a0, a4, 1865
                  csrrwi       a3, 0x340, 14
                  nop
                  c.nop
                  c.mv         s8, t1
                  c.li         tp, -1
                  xori         s11, s6, 1448
                  xori         t3, s3, 562
                  xori         s4, a2, 1630
                  c.srli       a1, 18
                  and          a0, sp, s9
                  divu         t3, s6, t6
                  c.slli       a6, 6
                  mul          s2, a7, t1
                  div          s6, s4, a0
                  c.lui        t1, 31
                  addi         a5, t3, -2035
                  c.srli       s0, 1
                  c.or         a5, a4
                  csrrci       a7, 0x340, 5
                  c.addi       s1, 12
                  sra          s9, a4, a6
                  c.nop
                  srai         t5, t4, 24
                  csrrci       t2, 0x340, 0
                  srai         s6, s0, 31
                  csrrsi       t3, 0x340, 0
                  slt          s6, a6, a4
                  xori         s6, s2, -1720
                  c.sub        a4, s1
                  c.xor        s1, a4
                  div          t1, s4, t6
                  and          t5, s11, s0
                  c.or         a4, a4
                  rem          a6, s11, ra
                  andi         s9, a6, -259
                  srl          s1, a2, s11
                  mulh         s2, a4, t5
                  slt          a5, s3, a0
                  sltiu        a0, s8, 1404
                  ori          gp, a7, 1842
                  mulhsu       s1, gp, a0
                  srl          t5, s5, t4
                  remu         t4, tp, a2
                  nop
                  csrrs        s7, 0x340, zero
                  c.addi       s3, -1
                  c.mv         a4, s2
                  c.add        a3, a5
                  sll          s9, a2, a6
                  c.addi       t0, -1
                  slli         a5, s1, 28
                  srli         ra, t4, 14
                  srai         zero, sp, 6
                  ori          s1, t5, -1214
                  csrrci       t6, 0x340, 0
                  csrrs        s2, 0x340, zero
                  add          t5, s3, s5
                  srl          a0, tp, t1
                  c.addi       a1, -1
                  xor          t1, s6, t4
                  csrrw        s11, 0x340, t3
                  c.addi       t2, -1
                  c.li         a1, 19
                  mulh         s4, a7, tp
                  slti         a7, s7, 1366
                  rem          s0, s5, a2
                  lui          ra, 609665
                  xori         s2, s4, 147
                  sll          t5, a2, sp
                  c.slli       t6, 19
                  csrrc        gp, 0x340, zero
                  csrrw        tp, 0x340, s3
                  c.add        s9, a6
                  auipc        ra, 302280
                  csrrc        tp, 0x340, zero
                  mulhu        t6, a0, s2
                  c.andi       a4, -1
                  c.addi       s8, 29
                  slti         s2, zero, 87
                  c.add        t1, a0
                  ori          t3, a5, 1051
                  sub          gp, a6, a1
                  mulhu        t0, s9, t3
                  c.slli       a3, 13
                  sltu         s3, s0, s0
                  divu         t6, a4, sp
                  mulhsu       ra, s9, s5
                  xori         s8, a5, 1999
                  addi         a7, s4, 1497
                  mulh         ra, zero, s10
                  c.and        s1, a4
                  xor          a3, s3, a3
                  c.and        a0, a0
                  xor          s4, a6, s11
                  sltu         t0, s8, s11
                  c.xor        a3, s0
                  sll          gp, s4, s11
                  mulh         t6, s11, a2
                  c.lui        t0, 15
                  c.srai       a0, 22
                  divu         a5, s1, a1
                  sll          t5, ra, s7
                  mul          s3, t1, a5
                  c.and        s0, a1
                  c.srai       a5, 1
                  remu         a3, t4, a1
                  c.xor        a3, a2
                  sltu         a0, t2, s6
                  add          s6, s7, s5
                  sll          zero, tp, a0
                  ori          s1, a0, -1030
                  mul          s9, a2, t6
                  sra          s5, t5, ra
                  c.mv         s1, a4
                  c.slli       t2, 21
                  mul          s11, s4, a5
                  sll          t0, s1, a6
                  c.nop
                  c.slli       s0, 25
                  mulh         t3, s0, s2
                  addi         s2, a7, 1910
                  c.and        a1, a0
                  csrrs        t0, 0x340, a6
                  c.sub        a5, a1
                  auipc        t3, 887857
                  srai         zero, a4, 7
                  sltiu        s7, s4, -1527
                  slti         t3, t0, -279
                  slti         t2, t2, -234
                  srai         s9, a3, 26
                  sltu         tp, a2, a0
                  andi         a6, tp, 1841
                  sub          a5, ra, t6
                  divu         t1, s3, s9
                  c.mv         s7, a6
                  auipc        t6, 5227
                  addi         a7, zero, 1779
                  div          s0, s9, t0
                  mul          a0, t6, a4
                  divu         t0, t0, s0
                  c.nop
                  csrrc        s1, 0x340, zero
                  xori         s3, s10, 1776
                  slti         s1, s8, -1628
                  xori         a4, a5, -372
                  c.or         s1, a2
                  sub          gp, s4, t5
                  csrrsi       s7, 0x340, 0
                  c.andi       s0, 17
                  lui          a3, 349016
                  srai         tp, s10, 11
                  sltu         ra, s8, s7
                  nop
                  srl          s6, s10, t0
                  srli         s3, s7, 17
                  mulhsu       gp, zero, t3
                  div          s9, t5, a2
                  mulhsu       t2, s8, s9
                  remu         a1, a1, s11
                  csrrci       gp, 0x340, 0
                  mul          a5, a3, t2
                  sll          a4, s9, sp
                  csrrsi       s11, 0x340, 0
                  andi         s8, s10, -254
                  divu         a1, s10, a3
                  csrrwi       s7, 0x340, 22
                  c.srai       a1, 26
                  mulhu        a3, s2, t6
                  slli         s8, s7, 3
                  c.xor        a4, a3
                  csrrw        s11, 0x340, sp
                  c.xor        a0, s1
                  add          s5, s8, s6
                  sll          tp, s4, a6
                  c.or         a1, s1
                  csrrs        ra, 0x340, t5
                  andi         t4, s2, -1617
                  srai         a5, s5, 6
                  or           s11, a7, sp
                  add          t2, a2, a3
                  c.li         s7, 27
                  andi         gp, a5, -1362
                  remu         tp, s3, a5
                  xori         t0, s9, 1233
                  srli         t1, t3, 13
                  andi         t1, s6, -920
                  c.slli       s3, 28
                  srl          a6, s3, s2
                  c.mv         a3, a3
                  ori          a5, s7, -2039
                  c.srli       a4, 7
                  c.mv         s8, s3
                  xori         s1, a2, -951
                  slti         a4, s0, -996
                  addi         zero, a0, 239
                  mulh         s4, s9, s1
                  sll          s0, t2, s3
                  sltu         t0, gp, a2
                  csrrci       tp, 0x340, 4
                  mulhu        t3, a7, s4
                  mulh         zero, s1, s1
                  c.and        s0, a3
                  xori         t6, t6, 1678
                  srl          s4, s9, a3
                  remu         t1, s9, t4
                  c.lui        t5, 21
                  c.sub        s1, a1
                  c.srai       a5, 8
                  xor          t1, s7, a3
                  c.nop
                  lui          s1, 784585
                  csrrwi       zero, 0x340, 24
                  rem          a4, s8, s4
                  lui          s6, 577140
                  c.sub        a5, a3
                  c.nop
                  csrrs        s9, 0x340, t4
                  ori          s7, s8, -1835
                  andi         t6, s6, 1917
                  add          a5, s11, t0
                  c.mv         s8, s10
                  srl          t2, s11, s6
                  c.mv         s4, t4
                  sltu         a7, a0, gp
                  c.and        a4, s1
                  mulhsu       t5, s11, s4
                  xori         s2, t1, 946
                  xor          s5, a7, sp
                  c.xor        a0, a5
                  nop
                  auipc        s8, 266276
                  srl          t6, sp, gp
                  c.xor        a5, a4
                  sltiu        s9, a3, -468
                  and          s5, s4, t0
                  mulhsu       t0, a4, zero
                  andi         a6, a5, -1183
                  xor          s5, a5, t2
                  xor          t5, a1, a3
                  divu         s0, t2, t1
                  sll          t5, s4, t0
                  csrrs        s6, 0x340, zero
                  srai         t2, s7, 3
                  c.nop
                  srli         s9, s8, 19
                  mul          a4, s8, gp
                  srli         s2, tp, 14
                  nop
                  c.li         a4, 24
                  srli         t1, t1, 27
                  c.lui        t2, 28
                  csrrw        ra, 0x340, t1
                  c.sub        a1, a1
                  c.li         a4, 2
                  ori          a3, a0, 985
                  and          gp, s7, s2
                  c.slli       s6, 20
                  addi         t1, a7, 1492
                  divu         a7, a6, a6
                  c.nop
                  srl          t1, ra, t4
                  csrrs        t6, 0x340, s5
                  c.srli       a0, 4
                  c.lui        s0, 18
                  c.srli       a0, 13
                  sltiu        s2, t1, -838
                  sra          t6, a2, s8
                  slt          t6, s3, t1
                  mulhsu       s4, a5, a4
                  slti         s2, s1, 1087
                  slti         s5, a3, 1441
                  lui          s6, 802685
                  c.sub        a3, s1
                  c.or         a3, a0
                  c.slli       s9, 2
                  csrrw        s8, 0x340, t3
                  c.sub        a4, s1
                  lui          t4, 394562
                  csrrw        a5, 0x340, s6
                  csrrwi       a1, 0x340, 5
                  srai         a0, a0, 25
                  add          s8, s2, a1
                  slli         a7, tp, 15
                  auipc        tp, 576891
                  csrrsi       s9, 0x340, 3
                  rem          zero, s11, tp
                  mulhsu       s4, a0, a7
                  slti         a0, tp, 888
                  div          s3, a6, t3
                  c.slli       s3, 16
                  c.sub        a3, a4
                  auipc        tp, 1044620
                  srli         a5, a5, 2
                  add          t1, t6, t1
                  c.lui        s2, 30
                  sra          t1, a6, s9
                  addi         s5, sp, 1074
                  c.srai       a4, 18
                  andi         a3, s1, -1674
                  mulhsu       s3, s6, s8
                  slti         t3, a2, 691
                  add          s2, a1, a3
                  c.add        s2, s1
                  slti         a0, s1, -157
                  srai         s8, t0, 16
                  slli         a4, ra, 19
                  sub          a6, t6, a7
                  c.xor        s1, s0
                  c.add        s6, sp
                  slli         zero, s6, 29
                  c.lui        t6, 22
                  c.xor        a3, a1
                  c.sub        a4, a1
                  auipc        ra, 43358
                  mul          s9, t6, a7
                  c.srli       s1, 19
                  c.and        a3, s1
                  or           a3, zero, a7
                  sltiu        a0, s10, 1803
                  c.slli       s0, 8
                  c.lui        t6, 1
                  mulhsu       a5, a1, s1
                  c.xor        a5, a2
                  csrrci       s5, 0x340, 11
                  c.sub        s0, s0
                  slt          a5, t3, s9
                  c.nop
                  c.add        s5, t5
                  srai         s4, a2, 7
                  c.addi       a7, -1
                  c.addi       a4, -1
                  c.nop
                  slti         t6, s5, 541
                  or           t4, a7, s1
                  xori         a7, a6, -805
                  c.and        a3, a3
                  c.srai       s1, 11
                  c.srai       s0, 1
                  csrrs        t2, 0x340, t4
                  srl          t4, s4, sp
                  mulh         tp, a7, a4
                  csrrc        t5, 0x340, zero
                  c.sub        s0, a5
                  rem          zero, a3, s7
                  c.sub        a4, a3
                  srl          s5, t2, s11
                  c.srai       a5, 13
                  mulh         a0, t4, s3
                  slti         ra, a0, -585
                  auipc        s9, 375262
                  xori         a6, s7, -1896
                  csrrwi       t2, 0x340, 0
                  c.xor        a0, a5
                  remu         zero, s4, sp
                  c.srai       a5, 24
                  lui          s9, 398702
                  c.li         s2, 30
                  div          s1, a1, a5
                  c.slli       gp, 11
                  sra          a3, a3, s11
                  slti         a4, gp, -726
                  csrrc        s9, 0x340, zero
                  sll          zero, gp, t4
                  xor          s4, s10, t1
                  c.slli       s2, 3
                  csrrw        gp, 0x340, a0
                  slli         t2, s0, 1
                  srl          t0, zero, sp
                  c.slli       t0, 13
                  div          ra, t1, a2
                  xori         s5, a1, -724
                  divu         a6, t4, s10
                  sra          s4, s4, s9
                  xor          s2, s9, t3
                  c.slli       gp, 21
                  addi         a3, s7, -1917
                  csrrsi       t1, 0x340, 0
                  c.nop
                  srl          s4, sp, a0
                  remu         a4, a1, a5
                  c.and        a3, a5
                  and          a1, s6, s7
                  slli         s1, gp, 2
                  csrrc        s11, 0x340, a1
                  rem          s8, a0, s2
                  c.xor        s0, a0
                  sltu         a6, s0, ra
                  csrrwi       s1, 0x340, 13
                  c.lui        t5, 3
                  csrrw        t1, 0x340, zero
                  xor          a7, t4, zero
                  c.andi       a1, -1
                  slli         zero, t5, 6
                  or           a4, s9, zero
                  xori         a1, tp, 265
                  auipc        t6, 144714
                  andi         a0, s9, 272
                  sltu         zero, a2, t4
                  sub          a3, s4, s3
                  la x2, test_done
                  jalr x0, x2, 0
write_tohost:     
                  sw gp, tohost, t5

_exit:            
                  j write_tohost

debug_rom:        
                  dret

debug_exception:  
                  dret

instr_end:        
                  nop

.section .data
.align 6; .global tohost; tohost: .dword 0;
.align 6; .global fromhost; fromhost: .dword 0;
.section .user_stack,"aw",@progbits;
.align 2
user_stack_start:
.rept 4999
.4byte 0x0
.endr
user_stack_end:
.4byte 0x0
.align 2
kernel_instr_start:
.text
ebreak_handler:   
                  li x29, 0x8ffffffc
                  li x10, 0xd
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  csrr  x10, 0x341
                  addi  x10, x10, 4
                  csrw  0x341, x10
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret

illegal_instr_handler:
                  li x29, 0x8ffffffc
                  li x10, 0xa
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  li x29, 0x8ffffffc
                  li x10, 0x342
                  slli x10, x10, 8
                  addi x10, x10, 0x3
                  sw x10, 0(x29)
                  csrr x10, 0x342
                  sw x10, 0(x29)
                  csrr  x10, 0x341
                  addi  x10, x10, 4
                  csrw  0x341, x10
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret

pt_fault_handler: 
                  li x29, 0x8ffffffc
                  li x10, 0x8
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  nop

.align 2
mmode_intr_handler:
                  csrr  x10, 0x300 # MSTATUS;
                  csrr  x10, 0x304 # MIE;
                  csrr  x10, 0x344 # MIP;
                  csrrc x10, 0x344, x10 # MIP;
                  li x29, 0x8ffffffc
                  li x10, 0x7
                  slli x10, x10, 8
                  addi x10, x10, 0x0
                  sw x10, 0(x29)
                  add x26, x12, zero
                  lw  x1, 4(x26)
                  lw  x2, 8(x26)
                  lw  x3, 12(x26)
                  lw  x4, 16(x26)
                  lw  x5, 20(x26)
                  lw  x6, 24(x26)
                  lw  x7, 28(x26)
                  lw  x8, 32(x26)
                  lw  x9, 36(x26)
                  lw  x10, 40(x26)
                  lw  x11, 44(x26)
                  lw  x12, 48(x26)
                  lw  x13, 52(x26)
                  lw  x14, 56(x26)
                  lw  x15, 60(x26)
                  lw  x16, 64(x26)
                  lw  x17, 68(x26)
                  lw  x18, 72(x26)
                  lw  x19, 76(x26)
                  lw  x20, 80(x26)
                  lw  x21, 84(x26)
                  lw  x22, 88(x26)
                  lw  x23, 92(x26)
                  lw  x24, 96(x26)
                  lw  x25, 100(x26)
                  lw  x26, 104(x26)
                  lw  x27, 108(x26)
                  lw  x28, 112(x26)
                  lw  x29, 116(x26)
                  lw  x30, 120(x26)
                  lw  x31, 124(x26)
                  addi x26, x26, 128
                  add x12, x26, zero
                  lw  x26, (x12)
                  addi x12, x12, 4
                  mret;

kernel_instr_end: nop
.section .kernel_stack,"aw",@progbits;
.align 2
kernel_stack_start:
.rept 3999
.4byte 0x0
.endr
kernel_stack_end:
.4byte 0x0
