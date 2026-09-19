.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x80
_start:
	# mstatus
	li x6, 0xa5a5a5a5
	csrrw x3, 768, x6
	li x6, 0x00000080
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 768, x6
	li x6, 0x00200080
	bne x6, x3, csr_fail
	li x6, 0xd5b91488
	csrrw x3, 768, x6
	li x6, 0x00021808
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 768, x6
	li x6, 0x00200088
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 768, x6
	li x6, 0x00200088
	bne x6, x3, csr_fail
	li x6, 0x1d38c440
	csrrs x3, 768, x6
	li x6, 0x00221888
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 768, x6
	li x6, 0x00221888
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 768, x6
	li x6, 0x00021808
	bne x6, x3, csr_fail
	li x6, 0x0a1a7f9f
	csrrc x3, 768, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 768, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 768, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 768, 0b01110
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrsi x3, 768, 0b00101
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrsi x3, 768, 0b11010
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrsi x3, 768, 0b00110
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 768, 0b00101
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 768, 0b11010
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 768, 0b11111
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mip
	li x6, 0xa5a5a5a5
	csrrw x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x6152ea12
	csrrw x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xa8b479c9
	csrrs x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xc3c920b3
	csrrc x3, 836, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 836, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 836, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 836, 0b11001
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 836, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 836, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 836, 0b00010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 836, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 836, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 836, 0b10110
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mie
	li x6, 0xa5a5a5a5
	csrrw x3, 772, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 772, x6
	li x6, 0x25a50080
	bne x6, x3, csr_fail
	li x6, 0x115d888e
	csrrw x3, 772, x6
	li x6, 0x5a5a0808
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 772, x6
	li x6, 0x115d0888
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 772, x6
	li x6, 0x35fd0888
	bne x6, x3, csr_fail
	li x6, 0x6ce7e727
	csrrs x3, 772, x6
	li x6, 0x7fff0888
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 772, x6
	li x6, 0x7fff0888
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 772, x6
	li x6, 0x5a5a0808
	bne x6, x3, csr_fail
	li x6, 0xfccde405
	csrrc x3, 772, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 772, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 772, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 772, 0b10101
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrsi x3, 772, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 772, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 772, 0b01011
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 772, 0b00101
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 772, 0b11010
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrci x3, 772, 0b01010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mscratch
	li x6, 0xa5a5a5a5
	csrrw x3, 832, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 832, x6
	li x6, 0xa5a5a5a5
	bne x6, x3, csr_fail
	li x6, 0x7a60c829
	csrrw x3, 832, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 832, x6
	li x6, 0x7a60c829
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 832, x6
	li x6, 0xffe5edad
	bne x6, x3, csr_fail
	li x6, 0x08e36967
	csrrs x3, 832, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 832, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 832, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0x93675b64
	csrrc x3, 832, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 832, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 832, 0b11010
	li x6, 0x00000005
	bne x6, x3, csr_fail
	csrrwi x3, 832, 0b11100
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrsi x3, 832, 0b00101
	li x6, 0x0000001c
	bne x6, x3, csr_fail
	csrrsi x3, 832, 0b11010
	li x6, 0x0000001d
	bne x6, x3, csr_fail
	csrrsi x3, 832, 0b11001
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 832, 0b00101
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 832, 0b11010
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrci x3, 832, 0b11011
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mepc
	li x6, 0xa5a5a5a5
	csrrw x3, 833, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 833, x6
	li x6, 0xa5a5a5a4
	bne x6, x3, csr_fail
	li x6, 0xc22776fa
	csrrw x3, 833, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 833, x6
	li x6, 0xc22776fa
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 833, x6
	li x6, 0xe7a7f7fe
	bne x6, x3, csr_fail
	li x6, 0xd99c5c79
	csrrs x3, 833, x6
	li x6, 0xfffffffe
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 833, x6
	li x6, 0xfffffffe
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 833, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0x04aaf4ce
	csrrc x3, 833, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 833, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 833, 0b11010
	li x6, 0x00000004
	bne x6, x3, csr_fail
	csrrwi x3, 833, 0b01000
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrsi x3, 833, 0b00101
	li x6, 0x00000008
	bne x6, x3, csr_fail
	csrrsi x3, 833, 0b11010
	li x6, 0x0000000c
	bne x6, x3, csr_fail
	csrrsi x3, 833, 0b10000
	li x6, 0x0000001e
	bne x6, x3, csr_fail
	csrrci x3, 833, 0b00101
	li x6, 0x0000001e
	bne x6, x3, csr_fail
	csrrci x3, 833, 0b11010
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrci x3, 833, 0b00110
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mcause
	li x6, 0xa5a5a5a5
	csrrw x3, 834, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 834, x6
	li x6, 0x80000005
	bne x6, x3, csr_fail
	li x6, 0xca6859b8
	csrrw x3, 834, x6
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 834, x6
	li x6, 0xfffffff8
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 834, x6
	li x6, 0xfffffffd
	bne x6, x3, csr_fail
	li x6, 0x72f1a3ad
	csrrs x3, 834, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 834, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 834, x6
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	li x6, 0x1c9c0418
	csrrc x3, 834, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 834, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 834, 0b11010
	li x6, 0x00000005
	bne x6, x3, csr_fail
	csrrwi x3, 834, 0b10001
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrsi x3, 834, 0b00101
	li x6, 0x00000011
	bne x6, x3, csr_fail
	csrrsi x3, 834, 0b11010
	li x6, 0x00000015
	bne x6, x3, csr_fail
	csrrsi x3, 834, 0b11101
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 834, 0b00101
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 834, 0b11010
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrci x3, 834, 0b11011
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mtval
	li x6, 0xa5a5a5a5
	csrrw x3, 835, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 835, x6
	li x6, 0xa5a5a5a5
	bne x6, x3, csr_fail
	li x6, 0x45abae7c
	csrrw x3, 835, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 835, x6
	li x6, 0x45abae7c
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 835, x6
	li x6, 0xe5afaffd
	bne x6, x3, csr_fail
	li x6, 0x0669be36
	csrrs x3, 835, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 835, x6
	li x6, 0xffffffff
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 835, x6
	li x6, 0x5a5a5a5a
	bne x6, x3, csr_fail
	li x6, 0x723dd6c6
	csrrc x3, 835, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 835, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 835, 0b11010
	li x6, 0x00000005
	bne x6, x3, csr_fail
	csrrwi x3, 835, 0b10000
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrsi x3, 835, 0b00101
	li x6, 0x00000010
	bne x6, x3, csr_fail
	csrrsi x3, 835, 0b11010
	li x6, 0x00000015
	bne x6, x3, csr_fail
	csrrsi x3, 835, 0b00111
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 835, 0b00101
	li x6, 0x0000001f
	bne x6, x3, csr_fail
	csrrci x3, 835, 0b11010
	li x6, 0x0000001a
	bne x6, x3, csr_fail
	csrrci x3, 835, 0b00010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	# mtvec
	li x6, 0xa5a5a5a5
	csrrw x3, 773, x6
	li x6, 0x80000001
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 773, x6
	li x6, 0xa5a5a501
	bne x6, x3, csr_fail
	li x6, 0x60a163be
	csrrw x3, 773, x6
	li x6, 0x5a5a5a01
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 773, x6
	li x6, 0x60a16301
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 773, x6
	li x6, 0xe5a5e701
	bne x6, x3, csr_fail
	li x6, 0xb6165373
	csrrs x3, 773, x6
	li x6, 0xffffff01
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 773, x6
	li x6, 0xffffff01
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 773, x6
	li x6, 0x5a5a5a01
	bne x6, x3, csr_fail
	li x6, 0xfdafe567
	csrrc x3, 773, x6
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrwi x3, 773, 0b00101
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrwi x3, 773, 0b11010
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrwi x3, 773, 0b10101
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrsi x3, 773, 0b00101
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrsi x3, 773, 0b11010
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrsi x3, 773, 0b10001
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrci x3, 773, 0b00101
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrci x3, 773, 0b11010
	li x6, 0x00000001
	bne x6, x3, csr_fail
	csrrci x3, 773, 0b01101
	li x6, 0x00000001
	bne x6, x3, csr_fail
	# secureseed
	li x6, 0xa5a5a5a5
	csrrw x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrw x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xf39870be
	csrrw x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrs x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrs x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xec50452f
	csrrs x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xa5a5a5a5
	csrrc x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0x5a5a5a5a
	csrrc x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	li x6, 0xd98286ee
	csrrc x3, 1985, x6
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 1985, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 1985, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrwi x3, 1985, 0b11110
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 1985, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 1985, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrsi x3, 1985, 0b10111
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 1985, 0b00101
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 1985, 0b11010
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrrci x3, 1985, 0b01100
	li x6, 0x00000000
	bne x6, x3, csr_fail
	csrr x3, 1985
	li x6, 0x00000000
	bne x6, x3, csr_fail
csr_pass:
	li x1, 0
	slli x1, x1, 8
	addi x1, x1, 1
	li x2, 0x8ffffff8
	sw x1, 0(x2)
	j csr_pass
csr_fail:
	li x1, 1
	slli x1, x1, 8
	addi x1, x1, 1
	li x2, 0x8ffffff8
	sw x1, 0(x2)
	j csr_fail
