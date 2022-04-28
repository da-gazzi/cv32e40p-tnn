	.global example_add
	.text
example_add:
	add a0, a0, a1
	ret

	.global main
	.text
main:
	/* function prologue */
	addi sp, sp, -4
	sw   ra, 0(sp)

	li   a0, 5
	li   a1, 10
	call example_add

	la a0, message /* a0 is first (and only) argument to puts */
	jal puts /* hello world */

	/* epilogue */
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 0 /* a0 is return value (RISC-V standard ABI) */
	ret

message:
	.ascii "hello world assembly\n"
