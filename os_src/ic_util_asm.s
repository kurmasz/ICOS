
	.file "ic_util_asm.s"
	.section .text
	.globl ic_rdtsc

ic_rdtsc:
	rdtsc
	ret
	
