.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x80
_start:
	# mstatus
	li x11, 0xa5a5a5a5
	csrrw x4, 768, x11
	li x11, 0x00000080
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 768, x11
	li x11, 0x00200080
	bne x11, x4, csr_fail
	li x11, 0xeadf8dbc
	csrrw x4, 768, x11
	li x11, 0x00021808
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 768, x11
	li x11, 0x00020088
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 768, x11
	li x11, 0x00220088
	bne x11, x4, csr_fail
	li x11, 0xaae48576
	csrrs x4, 768, x11
	li x11, 0x00221888
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 768, x11
	li x11, 0x00221888
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 768, x11
	li x11, 0x00021808
	bne x11, x4, csr_fail
	li x11, 0x424ec7ba
	csrrc x4, 768, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 768, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 768, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 768, 0b00011
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrsi x4, 768, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 768, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 768, 0b01000
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 768, 0b00101
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 768, 0b11010
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 768, 0b00111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mip
	li x11, 0xa5a5a5a5
	csrrw x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x01b24f1c
	csrrw x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xf8914086
	csrrs x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x652fea83
	csrrc x4, 836, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 836, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 836, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 836, 0b10111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 836, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 836, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 836, 0b00000
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 836, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 836, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 836, 0b01000
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mie
	li x11, 0xa5a5a5a5
	csrrw x4, 772, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 772, x11
	li x11, 0x25a50080
	bne x11, x4, csr_fail
	li x11, 0xf72b47bb
	csrrw x4, 772, x11
	li x11, 0x5a5a0808
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 772, x11
	li x11, 0x772b0088
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 772, x11
	li x11, 0x77af0088
	bne x11, x4, csr_fail
	li x11, 0x596a05d4
	csrrs x4, 772, x11
	li x11, 0x7fff0888
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 772, x11
	li x11, 0x7fff0888
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 772, x11
	li x11, 0x5a5a0808
	bne x11, x4, csr_fail
	li x11, 0xa041782e
	csrrc x4, 772, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 772, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 772, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 772, 0b10010
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrsi x4, 772, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 772, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 772, 0b01010
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 772, 0b00101
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 772, 0b11010
	li x11, 0x00000008
	bne x11, x4, csr_fail
	csrrci x4, 772, 0b10101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mscratch
	li x11, 0xa5a5a5a5
	csrrw x4, 832, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 832, x11
	li x11, 0xa5a5a5a5
	bne x11, x4, csr_fail
	li x11, 0xaf6d784c
	csrrw x4, 832, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 832, x11
	li x11, 0xaf6d784c
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 832, x11
	li x11, 0xafedfded
	bne x11, x4, csr_fail
	li x11, 0x661a2d2a
	csrrs x4, 832, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 832, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 832, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0x5d08a16c
	csrrc x4, 832, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 832, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 832, 0b11010
	li x11, 0x00000005
	bne x11, x4, csr_fail
	csrrwi x4, 832, 0b00000
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrsi x4, 832, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 832, 0b11010
	li x11, 0x00000005
	bne x11, x4, csr_fail
	csrrsi x4, 832, 0b10111
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 832, 0b00101
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 832, 0b11010
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrci x4, 832, 0b01110
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mepc
	li x11, 0xa5a5a5a5
	csrrw x4, 833, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 833, x11
	li x11, 0xa5a5a5a4
	bne x11, x4, csr_fail
	li x11, 0xc0505e96
	csrrw x4, 833, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 833, x11
	li x11, 0xc0505e96
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 833, x11
	li x11, 0xe5f5ffb6
	bne x11, x4, csr_fail
	li x11, 0xe0aa4e91
	csrrs x4, 833, x11
	li x11, 0xfffffffe
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 833, x11
	li x11, 0xfffffffe
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 833, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0xfdf0f975
	csrrc x4, 833, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 833, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 833, 0b11010
	li x11, 0x00000004
	bne x11, x4, csr_fail
	csrrwi x4, 833, 0b00001
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrsi x4, 833, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 833, 0b11010
	li x11, 0x00000004
	bne x11, x4, csr_fail
	csrrsi x4, 833, 0b01111
	li x11, 0x0000001e
	bne x11, x4, csr_fail
	csrrci x4, 833, 0b00101
	li x11, 0x0000001e
	bne x11, x4, csr_fail
	csrrci x4, 833, 0b11010
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrci x4, 833, 0b00110
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mcause
	li x11, 0xa5a5a5a5
	csrrw x4, 834, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 834, x11
	li x11, 0x80000005
	bne x11, x4, csr_fail
	li x11, 0x5ac97741
	csrrw x4, 834, x11
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 834, x11
	li x11, 0x00000001
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 834, x11
	li x11, 0x80000005
	bne x11, x4, csr_fail
	li x11, 0xe72351c1
	csrrs x4, 834, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 834, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 834, x11
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	li x11, 0x9144163b
	csrrc x4, 834, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 834, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 834, 0b11010
	li x11, 0x00000005
	bne x11, x4, csr_fail
	csrrwi x4, 834, 0b11101
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrsi x4, 834, 0b00101
	li x11, 0x0000001d
	bne x11, x4, csr_fail
	csrrsi x4, 834, 0b11010
	li x11, 0x0000001d
	bne x11, x4, csr_fail
	csrrsi x4, 834, 0b11011
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 834, 0b00101
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 834, 0b11010
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrci x4, 834, 0b11111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mtval
	li x11, 0xa5a5a5a5
	csrrw x4, 835, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 835, x11
	li x11, 0xa5a5a5a5
	bne x11, x4, csr_fail
	li x11, 0xf225f379
	csrrw x4, 835, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 835, x11
	li x11, 0xf225f379
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 835, x11
	li x11, 0xf7a5f7fd
	bne x11, x4, csr_fail
	li x11, 0xdffc6316
	csrrs x4, 835, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 835, x11
	li x11, 0xffffffff
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 835, x11
	li x11, 0x5a5a5a5a
	bne x11, x4, csr_fail
	li x11, 0x798fa59c
	csrrc x4, 835, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 835, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 835, 0b11010
	li x11, 0x00000005
	bne x11, x4, csr_fail
	csrrwi x4, 835, 0b10100
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrsi x4, 835, 0b00101
	li x11, 0x00000014
	bne x11, x4, csr_fail
	csrrsi x4, 835, 0b11010
	li x11, 0x00000015
	bne x11, x4, csr_fail
	csrrsi x4, 835, 0b01010
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 835, 0b00101
	li x11, 0x0000001f
	bne x11, x4, csr_fail
	csrrci x4, 835, 0b11010
	li x11, 0x0000001a
	bne x11, x4, csr_fail
	csrrci x4, 835, 0b01111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	# mtvec
	li x11, 0xa5a5a5a5
	csrrw x4, 773, x11
	li x11, 0x80000001
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 773, x11
	li x11, 0xa5a5a501
	bne x11, x4, csr_fail
	li x11, 0x851f4efc
	csrrw x4, 773, x11
	li x11, 0x5a5a5a01
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 773, x11
	li x11, 0x851f4e01
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 773, x11
	li x11, 0xa5bfef01
	bne x11, x4, csr_fail
	li x11, 0x659c25a1
	csrrs x4, 773, x11
	li x11, 0xffffff01
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 773, x11
	li x11, 0xffffff01
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 773, x11
	li x11, 0x5a5a5a01
	bne x11, x4, csr_fail
	li x11, 0xbc19a67d
	csrrc x4, 773, x11
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrwi x4, 773, 0b00101
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrwi x4, 773, 0b11010
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrwi x4, 773, 0b11011
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrsi x4, 773, 0b00101
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrsi x4, 773, 0b11010
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrsi x4, 773, 0b10110
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrci x4, 773, 0b00101
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrci x4, 773, 0b11010
	li x11, 0x00000001
	bne x11, x4, csr_fail
	csrrci x4, 773, 0b01001
	li x11, 0x00000001
	bne x11, x4, csr_fail
	# secureseed
	li x11, 0xa5a5a5a5
	csrrw x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrw x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x3f8ffefb
	csrrw x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrs x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrs x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x6e4ad858
	csrrs x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xa5a5a5a5
	csrrc x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0x5a5a5a5a
	csrrc x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	li x11, 0xa5e13d04
	csrrc x4, 1985, x11
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 1985, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 1985, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrwi x4, 1985, 0b10111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 1985, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 1985, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrsi x4, 1985, 0b11111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 1985, 0b00101
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 1985, 0b11010
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrrci x4, 1985, 0b11111
	li x11, 0x00000000
	bne x11, x4, csr_fail
	csrr x4, 1985
	li x11, 0x00000000
	bne x11, x4, csr_fail
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
