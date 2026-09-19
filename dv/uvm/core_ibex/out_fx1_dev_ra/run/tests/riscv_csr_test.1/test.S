.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x80
_start:
	# mstatus
	li x7, 0xa5a5a5a5
	csrrw x14, 768, x7
	li x7, 0x00000080
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 768, x7
	li x7, 0x00200080
	bne x7, x14, csr_fail
	li x7, 0xc27c7e13
	csrrw x14, 768, x7
	li x7, 0x00021808
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 768, x7
	li x7, 0x00201800
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 768, x7
	li x7, 0x00201880
	bne x7, x14, csr_fail
	li x7, 0x29757e62
	csrrs x14, 768, x7
	li x7, 0x00221888
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 768, x7
	li x7, 0x00221888
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 768, x7
	li x7, 0x00021808
	bne x7, x14, csr_fail
	li x7, 0x5870b71d
	csrrc x14, 768, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 768, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 768, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 768, 0b11110
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 768, 0b00101
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 768, 0b11010
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 768, 0b10111
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 768, 0b00101
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 768, 0b11010
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 768, 0b10010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mip
	li x7, 0xa5a5a5a5
	csrrw x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x88c43950
	csrrw x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0xee7209d0
	csrrs x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x413fa910
	csrrc x14, 836, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 836, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 836, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 836, 0b11001
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 836, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 836, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 836, 0b00011
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 836, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 836, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 836, 0b10110
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mie
	li x7, 0xa5a5a5a5
	csrrw x14, 772, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 772, x7
	li x7, 0x25a50080
	bne x7, x14, csr_fail
	li x7, 0xf8202b2b
	csrrw x14, 772, x7
	li x7, 0x5a5a0808
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 772, x7
	li x7, 0x78200808
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 772, x7
	li x7, 0x7da50888
	bne x7, x14, csr_fail
	li x7, 0xa3369d85
	csrrs x14, 772, x7
	li x7, 0x7fff0888
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 772, x7
	li x7, 0x7fff0888
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 772, x7
	li x7, 0x5a5a0808
	bne x7, x14, csr_fail
	li x7, 0xa8e4667e
	csrrc x14, 772, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 772, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 772, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 772, 0b11010
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 772, 0b00101
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 772, 0b11010
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrsi x14, 772, 0b10101
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 772, 0b00101
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 772, 0b11010
	li x7, 0x00000008
	bne x7, x14, csr_fail
	csrrci x14, 772, 0b10111
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mscratch
	li x7, 0xa5a5a5a5
	csrrw x14, 832, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 832, x7
	li x7, 0xa5a5a5a5
	bne x7, x14, csr_fail
	li x7, 0xf46cd92c
	csrrw x14, 832, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 832, x7
	li x7, 0xf46cd92c
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 832, x7
	li x7, 0xf5edfdad
	bne x7, x14, csr_fail
	li x7, 0x84f464b5
	csrrs x14, 832, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 832, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 832, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0x7e5ed86c
	csrrc x14, 832, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 832, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 832, 0b11010
	li x7, 0x00000005
	bne x7, x14, csr_fail
	csrrwi x14, 832, 0b01010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrsi x14, 832, 0b00101
	li x7, 0x0000000a
	bne x7, x14, csr_fail
	csrrsi x14, 832, 0b11010
	li x7, 0x0000000f
	bne x7, x14, csr_fail
	csrrsi x14, 832, 0b01100
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 832, 0b00101
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 832, 0b11010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrci x14, 832, 0b01000
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mepc
	li x7, 0xa5a5a5a5
	csrrw x14, 833, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 833, x7
	li x7, 0xa5a5a5a4
	bne x7, x14, csr_fail
	li x7, 0x891e2c45
	csrrw x14, 833, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 833, x7
	li x7, 0x891e2c44
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 833, x7
	li x7, 0xadbfade4
	bne x7, x14, csr_fail
	li x7, 0x73faa6c3
	csrrs x14, 833, x7
	li x7, 0xfffffffe
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 833, x7
	li x7, 0xfffffffe
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 833, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0xdd003547
	csrrc x14, 833, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 833, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 833, 0b11010
	li x7, 0x00000004
	bne x7, x14, csr_fail
	csrrwi x14, 833, 0b01100
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrsi x14, 833, 0b00101
	li x7, 0x0000000c
	bne x7, x14, csr_fail
	csrrsi x14, 833, 0b11010
	li x7, 0x0000000c
	bne x7, x14, csr_fail
	csrrsi x14, 833, 0b01011
	li x7, 0x0000001e
	bne x7, x14, csr_fail
	csrrci x14, 833, 0b00101
	li x7, 0x0000001e
	bne x7, x14, csr_fail
	csrrci x14, 833, 0b11010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrci x14, 833, 0b10011
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mcause
	li x7, 0xa5a5a5a5
	csrrw x14, 834, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 834, x7
	li x7, 0x80000005
	bne x7, x14, csr_fail
	li x7, 0xbc28e52b
	csrrw x14, 834, x7
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 834, x7
	li x7, 0x8000000b
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 834, x7
	li x7, 0x8000000f
	bne x7, x14, csr_fail
	li x7, 0x42c83126
	csrrs x14, 834, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 834, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 834, x7
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	li x7, 0xf469b905
	csrrc x14, 834, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 834, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 834, 0b11010
	li x7, 0x00000005
	bne x7, x14, csr_fail
	csrrwi x14, 834, 0b11010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrsi x14, 834, 0b00101
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrsi x14, 834, 0b11010
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrsi x14, 834, 0b00101
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 834, 0b00101
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 834, 0b11010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrci x14, 834, 0b10010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mtval
	li x7, 0xa5a5a5a5
	csrrw x14, 835, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 835, x7
	li x7, 0xa5a5a5a5
	bne x7, x14, csr_fail
	li x7, 0x18a8df3c
	csrrw x14, 835, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 835, x7
	li x7, 0x18a8df3c
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 835, x7
	li x7, 0xbdadffbd
	bne x7, x14, csr_fail
	li x7, 0xf4af031e
	csrrs x14, 835, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 835, x7
	li x7, 0xffffffff
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 835, x7
	li x7, 0x5a5a5a5a
	bne x7, x14, csr_fail
	li x7, 0xbfca1db9
	csrrc x14, 835, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 835, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 835, 0b11010
	li x7, 0x00000005
	bne x7, x14, csr_fail
	csrrwi x14, 835, 0b11111
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrsi x14, 835, 0b00101
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrsi x14, 835, 0b11010
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrsi x14, 835, 0b11010
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 835, 0b00101
	li x7, 0x0000001f
	bne x7, x14, csr_fail
	csrrci x14, 835, 0b11010
	li x7, 0x0000001a
	bne x7, x14, csr_fail
	csrrci x14, 835, 0b00011
	li x7, 0x00000000
	bne x7, x14, csr_fail
	# mtvec
	li x7, 0xa5a5a5a5
	csrrw x14, 773, x7
	li x7, 0x80000001
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 773, x7
	li x7, 0xa5a5a501
	bne x7, x14, csr_fail
	li x7, 0x9252e66f
	csrrw x14, 773, x7
	li x7, 0x5a5a5a01
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 773, x7
	li x7, 0x9252e601
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 773, x7
	li x7, 0xb7f7e701
	bne x7, x14, csr_fail
	li x7, 0xfd26af16
	csrrs x14, 773, x7
	li x7, 0xffffff01
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 773, x7
	li x7, 0xffffff01
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 773, x7
	li x7, 0x5a5a5a01
	bne x7, x14, csr_fail
	li x7, 0x925a12cc
	csrrc x14, 773, x7
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrwi x14, 773, 0b00101
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrwi x14, 773, 0b11010
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrwi x14, 773, 0b10011
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrsi x14, 773, 0b00101
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrsi x14, 773, 0b11010
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrsi x14, 773, 0b11110
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrci x14, 773, 0b00101
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrci x14, 773, 0b11010
	li x7, 0x00000001
	bne x7, x14, csr_fail
	csrrci x14, 773, 0b01101
	li x7, 0x00000001
	bne x7, x14, csr_fail
	# secureseed
	li x7, 0xa5a5a5a5
	csrrw x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrw x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x267e4226
	csrrw x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrs x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrs x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x3068796e
	csrrs x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0xa5a5a5a5
	csrrc x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x5a5a5a5a
	csrrc x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	li x7, 0x911fe1d4
	csrrc x14, 1985, x7
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 1985, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 1985, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrwi x14, 1985, 0b00110
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 1985, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 1985, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrsi x14, 1985, 0b00001
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 1985, 0b00101
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 1985, 0b11010
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrrci x14, 1985, 0b01001
	li x7, 0x00000000
	bne x7, x14, csr_fail
	csrr x14, 1985
	li x7, 0x00000000
	bne x7, x14, csr_fail
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
