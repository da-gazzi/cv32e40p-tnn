	.global main
	.text
main:
	/* function prologue */
	addi sp, sp, -4
	sw   ra, 0(sp)

	li   t0, 0x64c821a0
	li   t1, 0xa10c5477
	/*.word 0xe80342f7*/
	pv.mlsdotusp.t.0 t0, t1, t2

	/* epilogue */
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 0 /* a0 is return value (RISC-V standard ABI) */
	ret
