
	.file "ic_util_asm.s"
	.section .text
	.globl ic_rdtsc

ic_rdtsc:
	// rdtsc places its results in %eax and %edx.  The least
	// significant bits go in %eax; which happens to be the
	// convential locaiton for return values.
	rdtsc
	ret
	
