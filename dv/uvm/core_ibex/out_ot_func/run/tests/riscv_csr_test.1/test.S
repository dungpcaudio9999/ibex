.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x80
_start:
	# mstatus
	li x9, 0xa5a5a5a5
	csrrw x4, 768, x9
	li x9, 0x00000080
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 768, x9
	li x9, 0x00200080
	bne x9, x4, csr_fail
	li x9, 0x15d9d0c2
	csrrw x4, 768, x9
	li x9, 0x00021808
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 768, x9
	li x9, 0x00000080
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 768, x9
	li x9, 0x00200080
	bne x9, x4, csr_fail
	li x9, 0xc61819a5
	csrrs x4, 768, x9
	li x9, 0x00221888
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 768, x9
	li x9, 0x00221888
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 768, x9
	li x9, 0x00021808
	bne x9, x4, csr_fail
	li x9, 0x122531c0
	csrrc x4, 768, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 768, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 768, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 768, 0b11111
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrsi x4, 768, 0b00101
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrsi x4, 768, 0b11010
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrsi x4, 768, 0b00001
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 768, 0b00101
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 768, 0b11010
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 768, 0b11011
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mip
	li x9, 0xa5a5a5a5
	csrrw x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xd63feaf9
	csrrw x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x8134c370
	csrrs x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x67f9598c
	csrrc x4, 836, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 836, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 836, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 836, 0b00111
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 836, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 836, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 836, 0b00111
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 836, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 836, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 836, 0b11100
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mie
	li x9, 0xa5a5a5a5
	csrrw x4, 772, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 772, x9
	li x9, 0x25a50080
	bne x9, x4, csr_fail
	li x9, 0x3aee5f6a
	csrrw x4, 772, x9
	li x9, 0x5a5a0808
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 772, x9
	li x9, 0x3aee0808
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 772, x9
	li x9, 0x3fef0888
	bne x9, x4, csr_fail
	li x9, 0xe5d8df4c
	csrrs x4, 772, x9
	li x9, 0x7fff0888
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 772, x9
	li x9, 0x7fff0888
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 772, x9
	li x9, 0x5a5a0808
	bne x9, x4, csr_fail
	li x9, 0x5d554d63
	csrrc x4, 772, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 772, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 772, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 772, 0b00011
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrsi x4, 772, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 772, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 772, 0b11010
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 772, 0b00101
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 772, 0b11010
	li x9, 0x00000008
	bne x9, x4, csr_fail
	csrrci x4, 772, 0b10111
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mscratch
	li x9, 0xa5a5a5a5
	csrrw x4, 832, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 832, x9
	li x9, 0xa5a5a5a5
	bne x9, x4, csr_fail
	li x9, 0xaf4ccaa6
	csrrw x4, 832, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 832, x9
	li x9, 0xaf4ccaa6
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 832, x9
	li x9, 0xafedefa7
	bne x9, x4, csr_fail
	li x9, 0x370f25ee
	csrrs x4, 832, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 832, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 832, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0x8e8d61ad
	csrrc x4, 832, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 832, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 832, 0b11010
	li x9, 0x00000005
	bne x9, x4, csr_fail
	csrrwi x4, 832, 0b00000
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrsi x4, 832, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 832, 0b11010
	li x9, 0x00000005
	bne x9, x4, csr_fail
	csrrsi x4, 832, 0b11010
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 832, 0b00101
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 832, 0b11010
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrci x4, 832, 0b11100
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mepc
	li x9, 0xa5a5a5a5
	csrrw x4, 833, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 833, x9
	li x9, 0xa5a5a5a4
	bne x9, x4, csr_fail
	li x9, 0xd9b7f190
	csrrw x4, 833, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 833, x9
	li x9, 0xd9b7f190
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 833, x9
	li x9, 0xfdb7f5b4
	bne x9, x4, csr_fail
	li x9, 0xc0aa49b7
	csrrs x4, 833, x9
	li x9, 0xfffffffe
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 833, x9
	li x9, 0xfffffffe
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 833, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0xfd2c6423
	csrrc x4, 833, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 833, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 833, 0b11010
	li x9, 0x00000004
	bne x9, x4, csr_fail
	csrrwi x4, 833, 0b10111
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrsi x4, 833, 0b00101
	li x9, 0x00000016
	bne x9, x4, csr_fail
	csrrsi x4, 833, 0b11010
	li x9, 0x00000016
	bne x9, x4, csr_fail
	csrrsi x4, 833, 0b01001
	li x9, 0x0000001e
	bne x9, x4, csr_fail
	csrrci x4, 833, 0b00101
	li x9, 0x0000001e
	bne x9, x4, csr_fail
	csrrci x4, 833, 0b11010
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrci x4, 833, 0b01001
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mcause
	li x9, 0xa5a5a5a5
	csrrw x4, 834, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 834, x9
	li x9, 0x80000005
	bne x9, x4, csr_fail
	li x9, 0x7b65932b
	csrrw x4, 834, x9
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 834, x9
	li x9, 0x0000000b
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 834, x9
	li x9, 0x8000000f
	bne x9, x4, csr_fail
	li x9, 0x5d615b2f
	csrrs x4, 834, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 834, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 834, x9
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	li x9, 0xb01a2337
	csrrc x4, 834, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 834, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 834, 0b11010
	li x9, 0x00000005
	bne x9, x4, csr_fail
	csrrwi x4, 834, 0b10111
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrsi x4, 834, 0b00101
	li x9, 0x00000017
	bne x9, x4, csr_fail
	csrrsi x4, 834, 0b11010
	li x9, 0x00000017
	bne x9, x4, csr_fail
	csrrsi x4, 834, 0b01100
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 834, 0b00101
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 834, 0b11010
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrci x4, 834, 0b01000
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mtval
	li x9, 0xa5a5a5a5
	csrrw x4, 835, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 835, x9
	li x9, 0xa5a5a5a5
	bne x9, x4, csr_fail
	li x9, 0x7a1f2fbe
	csrrw x4, 835, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 835, x9
	li x9, 0x7a1f2fbe
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 835, x9
	li x9, 0xffbfafbf
	bne x9, x4, csr_fail
	li x9, 0xf210c800
	csrrs x4, 835, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 835, x9
	li x9, 0xffffffff
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 835, x9
	li x9, 0x5a5a5a5a
	bne x9, x4, csr_fail
	li x9, 0x9dc88806
	csrrc x4, 835, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 835, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 835, 0b11010
	li x9, 0x00000005
	bne x9, x4, csr_fail
	csrrwi x4, 835, 0b00100
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrsi x4, 835, 0b00101
	li x9, 0x00000004
	bne x9, x4, csr_fail
	csrrsi x4, 835, 0b11010
	li x9, 0x00000005
	bne x9, x4, csr_fail
	csrrsi x4, 835, 0b01111
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 835, 0b00101
	li x9, 0x0000001f
	bne x9, x4, csr_fail
	csrrci x4, 835, 0b11010
	li x9, 0x0000001a
	bne x9, x4, csr_fail
	csrrci x4, 835, 0b11000
	li x9, 0x00000000
	bne x9, x4, csr_fail
	# mtvec
	li x9, 0xa5a5a5a5
	csrrw x4, 773, x9
	li x9, 0x80000001
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 773, x9
	li x9, 0xa5a5a501
	bne x9, x4, csr_fail
	li x9, 0x6ca2a459
	csrrw x4, 773, x9
	li x9, 0x5a5a5a01
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 773, x9
	li x9, 0x6ca2a401
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 773, x9
	li x9, 0xeda7a501
	bne x9, x4, csr_fail
	li x9, 0xc76bc966
	csrrs x4, 773, x9
	li x9, 0xffffff01
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 773, x9
	li x9, 0xffffff01
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 773, x9
	li x9, 0x5a5a5a01
	bne x9, x4, csr_fail
	li x9, 0xeff5f715
	csrrc x4, 773, x9
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrwi x4, 773, 0b00101
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrwi x4, 773, 0b11010
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrwi x4, 773, 0b01100
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrsi x4, 773, 0b00101
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrsi x4, 773, 0b11010
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrsi x4, 773, 0b01101
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrci x4, 773, 0b00101
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrci x4, 773, 0b11010
	li x9, 0x00000001
	bne x9, x4, csr_fail
	csrrci x4, 773, 0b11010
	li x9, 0x00000001
	bne x9, x4, csr_fail
	# secureseed
	li x9, 0xa5a5a5a5
	csrrw x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrw x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xbb3876fb
	csrrw x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrs x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrs x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xb3bf8a1a
	csrrs x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xa5a5a5a5
	csrrc x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0x5a5a5a5a
	csrrc x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	li x9, 0xbd9a7417
	csrrc x4, 1985, x9
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 1985, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 1985, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrwi x4, 1985, 0b00100
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 1985, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 1985, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrsi x4, 1985, 0b11101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 1985, 0b00101
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 1985, 0b11010
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrrci x4, 1985, 0b11011
	li x9, 0x00000000
	bne x9, x4, csr_fail
	csrr x4, 1985
	li x9, 0x00000000
	bne x9, x4, csr_fail
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
