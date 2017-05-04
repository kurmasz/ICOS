	.file	"main.c"
	.section	.text.unlikely,"ax",@progbits
.LCOLDB0:
	.text
.LHOTB0:
	.align 16
	.globl	make_vgaentry
	.type	make_vgaentry, @function
make_vgaentry:
.LFB0:
	.cfi_startproc
	movzbl	8(%esp), %eax
	movsbw	4(%esp), %dx
	sall	$8, %eax
	orl	%edx, %eax
	ret
	.cfi_endproc
.LFE0:
	.size	make_vgaentry, .-make_vgaentry
	.section	.text.unlikely
.LCOLDE0:
	.text
.LHOTE0:
	.section	.text.unlikely
.LCOLDB1:
	.text
.LHOTB1:
	.align 16
	.globl	dummy
	.type	dummy, @function
dummy:
.LFB1:
	.cfi_startproc
	movl	$1857, %eax
	movw	%ax, 753664
	ret
	.cfi_endproc
.LFE1:
	.size	dummy, .-dummy
	.section	.text.unlikely
.LCOLDE1:
	.text
.LHOTE1:
	.section	.text.unlikely
.LCOLDB2:
	.text
.LHOTB2:
	.align 16
	.globl	hello_world
	.type	hello_world, @function
hello_world:
.LFB2:
	.cfi_startproc
	pushl	%ebx
	.cfi_def_cfa_offset 8
	.cfi_offset 3, -8
	movl	$33, %eax
	subl	$32, %esp
	.cfi_def_cfa_offset 40
	movl	40(%esp), %ecx
	leal	18(%esp), %ebx
	movw	%ax, 30(%esp)
	movl	$1819043144, 18(%esp)
	movl	$1461726319, 22(%esp)
	movl	$72, %eax
	movl	$1684828783, 26(%esp)
	leal	(%ecx,%ecx,4), %edx
	sall	$6, %edx
	.align 16
.L7:
	orb	$7, %ah
	addl	$1, %ebx
	addl	$2, %edx
	movw	%ax, 753662(%edx)
	movsbw	(%ebx), %ax
	testb	%al, %al
	jne	.L7
	leal	(%ecx,%ecx,4), %edx
	leal	9(%esp), %ecx
	movl	$1667462483, 9(%esp)
	movl	$561214309, 13(%esp)
	movb	$0, 17(%esp)
	movl	$83, %eax
	sall	$6, %edx
	.align 16
.L9:
	orb	$7, %ah
	addl	$1, %ecx
	addl	$2, %edx
	movw	%ax, 753822(%edx)
	movsbw	(%ecx), %ax
	testb	%al, %al
	jne	.L9
	addl	$32, %esp
	.cfi_def_cfa_offset 8
	popl	%ebx
	.cfi_restore 3
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE2:
	.size	hello_world, .-hello_world
	.section	.text.unlikely
.LCOLDE2:
	.text
.LHOTE2:
	.section	.text.unlikely
.LCOLDB3:
	.text
.LHOTB3:
	.align 16
	.globl	sample
	.type	sample, @function
sample:
.LFB3:
	.cfi_startproc
	pushl	$0
	.cfi_def_cfa_offset 8
	call	hello_world
	pushl	$2
	.cfi_def_cfa_offset 12
	call	hello_world
	popl	%eax
	.cfi_def_cfa_offset 8
	popl	%edx
	.cfi_def_cfa_offset 4
	ret
	.cfi_endproc
.LFE3:
	.size	sample, .-sample
	.section	.text.unlikely
.LCOLDE3:
	.text
.LHOTE3:
	.ident	"GCC: (GNU) 4.9.2"
