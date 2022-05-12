	.global main
	.text
main:
	/* function prologue */
	addi sp, sp, -4
	sw   ra, 0(sp)

	li   t1, 0x1c4 /* load preactivation 452 */
	li   t2, 0x006702c0 /* load thresholds 103 & 704 */
	.word 0x087362B3 /* hard-coded thrc -> result is stored in t0 */
	li   t2, 0x01f80386 /* load thresholds 504 & 902 */
	.word 0x087362B3 /* hard-coded thrc -> result is stored in t0 */
	li   t2, 0x003300c8 /* load thresholds 51 & 200 */
	.word 0x087362B3 /* hard-coded thrc -> result is stored in t0 */

	/* epilogue */
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 0 /* a0 is return value (RISC-V standard ABI) */
	ret
