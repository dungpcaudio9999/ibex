.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x80
_start:
	# mstatus
	li x3, 0xa5a5a5a5
	csrrw x6, 768, x3
	li x3, 0x00000080
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 768, x3
	li x3, 0x00200080
	bne x3, x6, csr_fail
	li x3, 0x773438a4
	csrrw x6, 768, x3
	li x3, 0x00021808
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 768, x3
	li x3, 0x00201880
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 768, x3
	li x3, 0x00201880
	bne x3, x6, csr_fail
	li x3, 0xaf5249ce
	csrrs x6, 768, x3
	li x3, 0x00221888
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 768, x3
	li x3, 0x00221888
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 768, x3
	li x3, 0x00021808
	bne x3, x6, csr_fail
	li x3, 0x0670555f
	csrrc x6, 768, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 768, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 768, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 768, 0b01100
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrsi x6, 768, 0b00101
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrsi x6, 768, 0b11010
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrsi x6, 768, 0b00100
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 768, 0b00101
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 768, 0b11010
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 768, 0b10011
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mip
	li x3, 0xa5a5a5a5
	csrrw x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x27e72306
	csrrw x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x0b0d615a
	csrrs x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xb16eea13
	csrrc x6, 836, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 836, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 836, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 836, 0b01111
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 836, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 836, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 836, 0b10000
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 836, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 836, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 836, 0b01110
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mie
	li x3, 0xa5a5a5a5
	csrrw x6, 772, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 772, x3
	li x3, 0x25a50080
	bne x3, x6, csr_fail
	li x3, 0x4c990474
	csrrw x6, 772, x3
	li x3, 0x5a5a0808
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 772, x3
	li x3, 0x4c990000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 772, x3
	li x3, 0x6dbd0080
	bne x3, x6, csr_fail
	li x3, 0x5ae0cba4
	csrrs x6, 772, x3
	li x3, 0x7fff0888
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 772, x3
	li x3, 0x7fff0888
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 772, x3
	li x3, 0x5a5a0808
	bne x3, x6, csr_fail
	li x3, 0xf0cf96fd
	csrrc x6, 772, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 772, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 772, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 772, 0b10001
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrsi x6, 772, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 772, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 772, 0b00011
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 772, 0b00101
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 772, 0b11010
	li x3, 0x00000008
	bne x3, x6, csr_fail
	csrrci x6, 772, 0b10101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mscratch
	li x3, 0xa5a5a5a5
	csrrw x6, 832, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 832, x3
	li x3, 0xa5a5a5a5
	bne x3, x6, csr_fail
	li x3, 0xf4ba0363
	csrrw x6, 832, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 832, x3
	li x3, 0xf4ba0363
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 832, x3
	li x3, 0xf5bfa7e7
	bne x3, x6, csr_fail
	li x3, 0x536fc960
	csrrs x6, 832, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 832, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 832, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0x650509ed
	csrrc x6, 832, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 832, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 832, 0b11010
	li x3, 0x00000005
	bne x3, x6, csr_fail
	csrrwi x6, 832, 0b01111
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrsi x6, 832, 0b00101
	li x3, 0x0000000f
	bne x3, x6, csr_fail
	csrrsi x6, 832, 0b11010
	li x3, 0x0000000f
	bne x3, x6, csr_fail
	csrrsi x6, 832, 0b00110
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 832, 0b00101
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 832, 0b11010
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrci x6, 832, 0b10001
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mepc
	li x3, 0xa5a5a5a5
	csrrw x6, 833, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 833, x3
	li x3, 0xa5a5a5a4
	bne x3, x6, csr_fail
	li x3, 0x7c8bd1fc
	csrrw x6, 833, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 833, x3
	li x3, 0x7c8bd1fc
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 833, x3
	li x3, 0xfdaff5fc
	bne x3, x6, csr_fail
	li x3, 0x10d02726
	csrrs x6, 833, x3
	li x3, 0xfffffffe
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 833, x3
	li x3, 0xfffffffe
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 833, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0xe6143305
	csrrc x6, 833, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 833, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 833, 0b11010
	li x3, 0x00000004
	bne x3, x6, csr_fail
	csrrwi x6, 833, 0b10111
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrsi x6, 833, 0b00101
	li x3, 0x00000016
	bne x3, x6, csr_fail
	csrrsi x6, 833, 0b11010
	li x3, 0x00000016
	bne x3, x6, csr_fail
	csrrsi x6, 833, 0b10000
	li x3, 0x0000001e
	bne x3, x6, csr_fail
	csrrci x6, 833, 0b00101
	li x3, 0x0000001e
	bne x3, x6, csr_fail
	csrrci x6, 833, 0b11010
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrci x6, 833, 0b00010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mcause
	li x3, 0xa5a5a5a5
	csrrw x6, 834, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 834, x3
	li x3, 0x80000005
	bne x3, x6, csr_fail
	li x3, 0x1ba617f7
	csrrw x6, 834, x3
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 834, x3
	li x3, 0x00000017
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 834, x3
	li x3, 0x80000017
	bne x3, x6, csr_fail
	li x3, 0xb8da3273
	csrrs x6, 834, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 834, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 834, x3
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	li x3, 0x78c45208
	csrrc x6, 834, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 834, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 834, 0b11010
	li x3, 0x00000005
	bne x3, x6, csr_fail
	csrrwi x6, 834, 0b00110
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrsi x6, 834, 0b00101
	li x3, 0x00000006
	bne x3, x6, csr_fail
	csrrsi x6, 834, 0b11010
	li x3, 0x00000007
	bne x3, x6, csr_fail
	csrrsi x6, 834, 0b11001
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 834, 0b00101
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 834, 0b11010
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrci x6, 834, 0b11011
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mtval
	li x3, 0xa5a5a5a5
	csrrw x6, 835, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 835, x3
	li x3, 0xa5a5a5a5
	bne x3, x6, csr_fail
	li x3, 0x5ce25bec
	csrrw x6, 835, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 835, x3
	li x3, 0x5ce25bec
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 835, x3
	li x3, 0xfde7ffed
	bne x3, x6, csr_fail
	li x3, 0xc989638e
	csrrs x6, 835, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 835, x3
	li x3, 0xffffffff
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 835, x3
	li x3, 0x5a5a5a5a
	bne x3, x6, csr_fail
	li x3, 0x72c9e3c1
	csrrc x6, 835, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 835, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 835, 0b11010
	li x3, 0x00000005
	bne x3, x6, csr_fail
	csrrwi x6, 835, 0b11111
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrsi x6, 835, 0b00101
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrsi x6, 835, 0b11010
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrsi x6, 835, 0b11110
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 835, 0b00101
	li x3, 0x0000001f
	bne x3, x6, csr_fail
	csrrci x6, 835, 0b11010
	li x3, 0x0000001a
	bne x3, x6, csr_fail
	csrrci x6, 835, 0b11001
	li x3, 0x00000000
	bne x3, x6, csr_fail
	# mtvec
	li x3, 0xa5a5a5a5
	csrrw x6, 773, x3
	li x3, 0x80000001
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 773, x3
	li x3, 0xa5a5a501
	bne x3, x6, csr_fail
	li x3, 0xf6935a58
	csrrw x6, 773, x3
	li x3, 0x5a5a5a01
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 773, x3
	li x3, 0xf6935a01
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 773, x3
	li x3, 0xf7b7ff01
	bne x3, x6, csr_fail
	li x3, 0x2fd36a30
	csrrs x6, 773, x3
	li x3, 0xffffff01
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 773, x3
	li x3, 0xffffff01
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 773, x3
	li x3, 0x5a5a5a01
	bne x3, x6, csr_fail
	li x3, 0xd9e42a5f
	csrrc x6, 773, x3
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrwi x6, 773, 0b00101
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrwi x6, 773, 0b11010
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrwi x6, 773, 0b01011
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrsi x6, 773, 0b00101
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrsi x6, 773, 0b11010
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrsi x6, 773, 0b01010
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrci x6, 773, 0b00101
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrci x6, 773, 0b11010
	li x3, 0x00000001
	bne x3, x6, csr_fail
	csrrci x6, 773, 0b01110
	li x3, 0x00000001
	bne x3, x6, csr_fail
	# secureseed
	li x3, 0xa5a5a5a5
	csrrw x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrw x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xaee48a41
	csrrw x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrs x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrs x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xdf3e435b
	csrrs x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0xa5a5a5a5
	csrrc x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x5a5a5a5a
	csrrc x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	li x3, 0x1a06cf6d
	csrrc x6, 1985, x3
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 1985, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 1985, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrwi x6, 1985, 0b01000
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 1985, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 1985, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrsi x6, 1985, 0b10100
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 1985, 0b00101
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 1985, 0b11010
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrrci x6, 1985, 0b11001
	li x3, 0x00000000
	bne x3, x6, csr_fail
	csrr x6, 1985
	li x3, 0x00000000
	bne x3, x6, csr_fail
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
