	.global main
	.text
main:
	/* function prologue */
	addi sp, sp, -4
	sw   ra, 0(sp)

	li   t0, 0x64c821a0
	li   t1, 0xa10c5477
	pv.smlsdotsp.h t0, t1, 0
	pv.smlsdotsp.b t0, t1, 0
	pv.smlsdotsp.n t0, t1, 1
	pv.smlsdotsp.c t0, t1, 2

	pv.smlsdotusp.h t0, t1, 3
	pv.smlsdotusp.b t0, t1, 4
	pv.smlsdotusp.n t0, t1, 1
	pv.smlsdotusp.c t0, t1, 0

	pv.smlsdotup.h t0, t1, 2
	pv.smlsdotup.b t0, t1, 1
	pv.smlsdotup.n t0, t1, 1
	pv.smlsdotup.c t0, t1, 4

	pv.smlsdotsup.h t0, t1, 1
	pv.smlsdotsup.b t0, t1, 4
	pv.smlsdotsup.n t0, t1, 1
	pv.smlsdotsup.c t0, t1, 3

	/* epilogue */
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 0 /* a0 is return value (RISC-V standard ABI) */
	ret
