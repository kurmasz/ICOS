.code16
.section .boot
/*******************************************************************
 *	
 * Initial set up (including the stack)
 *
 ******************************************************************/

	// disable interrupts
	cli
	
	/* Set %cs to 0. (If I understand correctly, in real mode, the
	ljmp instruction sets both %cs (the code segment register) as
	well as the %eip (the instruction pointer). $1f is the next
	label with a value of "1", which appens to be on the next
	line. Thus, this instrucion doesn't actually change the flow
	of the program, but assures that %cs is correctly set to the
	segment containing the code we are currently running */
	ljmp $0, $1f
1:

	/* Sets %ax to 0.  (I'm not sure why we're not using mov.) */
	xor %ax, %ax

	/* Set all the segment registers to 0, just so we know for sure
	what's going on. */
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	mov %ax, %bp
	mov %ax, %ss
	mov %bp, %sp

	
	/* The BIOS sets %dl to the value of the boot device.  We
	store it so we can use it later to load sectors beyond the
	MBR. */
	mov %dl, initial_dl
	jmp after_locals  // jump over the byte used to store %dl
initial_dl: .byte 0
after_locals:
	
	mov initial_dl, %dl

	// Write a short message to help with debugging
	mov $0x0E, %ah
	mov $0x48, %al // 'H'
	int $0x10

	mov $0x69, %al // 'i'
	int $0x10

	mov $0x20, %al // ' '
	int $0x10
	
/*
	// (Left over from debugging)
	// test write back to boot device
	mov $0x03, %ah
	mov $1, %al
	mov $end_of_s1, %bx
	mov $0, %ch
	mov $0xf, %cl
	mov $0x00, %dh
	int $0x13
*/

/*******************************************************************
 *	
 * Stage 2 load (loading data beyond initial 512 bytes)
 *
 ******************************************************************/

	/* __stage2_nsectors defined in the linker script. */
	mov $0x02, %ah	            // magic number to request a read
	mov $__stage2_nsectors, %al // number of sectors to read

	/* The linker script specifies that code marked with
	   .section .stage2 be placed exactly 512 bytes from the beginning
	   of the image.  As a result, the label 1: will be exactly 512 bytes
	   from the beginning of the image. This is where we want to place
	   the data we're reading from disk.
	*/
	mov $1f, %bx

	/* ch is the starting cylinder number (0 in this case)
	   cl is the starting sector number (2 in this case, because
	   sector 1 was loaded by the BIOS
	*/
	mov $0x0002, %cx    
	mov $0x00, %dh      // specify head number
	mov initial_dl, %dl // specify drive number
	int $0x13

	//
	// Print debugging message indicating that the S2 load was attempted
	//
	
	mov $0x0E, %ah
	mov $0x51, %al // 'S'
	int $0x10

	mov $0x32, %al // '2'
	int $0x10

	mov $0x20, %al // ' '
	int $0x10



/*******************************************************************
 *	
 * enable A20
 *	
 * code from http://wiki.osdev.org/A20_Line
 *
 ******************************************************************/
	mov     $0x2403, %ax            //--- A20-Gate Support ---
	int     $0x15
	jb      a20_ns                  //INT 15h is not supported
	cmp     $0, %ah
	jnz     a20_ns                  //INT 15h is not supported
	 
	mov     $0x2402, %ax            //--- A20-Gate Status ---
	int     $0x15
	jb      a20_failed              //couldn't get status
	cmp     $0, %ah
	jnz     a20_failed              //couldn't get status
	 
	cmp     $1, %al
	jz      a20_activated           // A20 is already activated
	 
	mov     $0x2401, %ax            // --- A20-Gate Activate ---
	int     $0x15
	jb      a20_failed              // couldn't activate the gate
	cmp     $0, %ah
	jnz     a20_failed              // couldn't activate the gate

	jmp     a20_activated	
	
a20_failed:
a20_ns:

	///////////////////////////////////////////////////////////////////
	//
	// WARNING! This is not foolproof.
	//
	// More work should be done
	//
	/////////////////////////////////////////////////////////////////

	in $0x92, %al
	or $2, %al
	out %al, $0x92 
	jmp a20_activated
	
	
	//
	// Print message indicating the failure to set A20 and halt
	//
	
	mov $0x0E, %ah
	mov $0x6e, %al // 'n'
	int $0x10

	mov $0x6f, %al // 'o'
	int $0x10

	mov $0x20, %al // ' '
	int $0x10


	mov $0x41, %al // 'A'
	int $0x10

	mov $0x32, %al // '2'
	int $0x10

	mov $0x30, %al // '0'
	int $0x10

	hlt   // halt here.
	jmp . // loop infinitely incase halt doesn't work

a20_activated:                          // continue


/*******************************************************************
 *	
 * Enter protected mode
 *
 ******************************************************************/
	
	/* Must come before they are used. */
	.equ CODE_SEG, 8   
	.equ DATA_SEG, gdt_data - gdt_start
	.equ CODE_SEG_16, 8
	.equ DATA_SEG_16, gdt16_data - gdt16_start
	
		
	/* Tell the processor where our Global Descriptor Table is in memory. */
	lgdt gdt_descriptor
		
	/* Set PE (Protection Enable) bit in CR0 (Control Register 0),
	   effectively entering protected mode. */
	cli
	mov %cr0, %eax
	orl $0x1, %eax
	mov %eax, %cr0

	ljmp $CODE_SEG,  $protected_mode

/*
Our GDT contains:
- a null entry to fill the unusable entry 0:
  http://stackoverflow.com/questions/33198282/why-have-the-first-segment-descriptor-of-the-global-descriptor-table-contain-onl
- a code and data. Both are necessary, because:
  - it is impossible to write to the code segment
  - it is impossible execute the data segment
  Both start at 0 and span the entire memory,
  allowing us to access anything without problems.
A real OS might have 2 extra segments: user data and code.
This is the case for the Linux kernel.
This is better than modifying the privilege bit of the GDT
as we'd have to reload it several times, losing cache.
*/
gdt_start:
gdt_null:
    .long 0x0
    .long 0x0
gdt_code:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10011010
    .byte 0b11001111
    .byte 0x0
gdt_data:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010010
    .byte 0b11001111
    .byte 0x0
gdt_end:
gdt_descriptor:
    .word gdt_end - gdt_start
    .long gdt_start
vga_current_line:
    .long 0xcd

gdt16_start:
gdt16_null:
    .long 0x0
    .long 0x0
gdt16_code:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10011010
    .byte 0b00001111
    .byte 0x0
gdt16_data:
    .word 0xffff
    .word 0x0
    .byte 0x0
    .byte 0b10010010
    .byte 0b00001111
    .byte 0x0
gdt16_end:
gdt16_descriptor:
    .word gdt16_end - gdt16_start
    .long gdt16_start

.code32
protected_mode:

	/* Setup the other segments.
	   Those movs are mandatory because they update the descriptor cache:
	   http://wiki.osdev.org/Descriptor_Cache */
	mov $DATA_SEG, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss

	mov $0X7000, %ebp   // Place the stack below the code
	mov %ebp, %esp	

	jmp 1f

/*******************************************************************
 *	
 * Run the OS.
 * 
 * Now that we are in protected mode, we can run the OS.
 *
 ******************************************************************/
.section .stage2
1:
	call initialize_gdd

	leal data_buffer, %eax
	push %eax
	call data_initialize
	popl %eax
	
	call KERNEL_MAIN
	
/*******************************************************************
 *	
 * Return to real mode and dump the output data
 *
 * Code for return to real mode obtained here:
 *http://www.rohitab.com/discuss/topic/35103-switch-between-real-mode-and-protected-mode/
 ******************************************************************/
	
move_to_real:

	cli
	lgdt gdt16_descriptor
	ljmp $CODE_SEG_16, $p_mode16
	
.code16	
p_mode16:	 
	mov $DATA_SEG_16, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	mov %ax, %di
	
	mov %cr0, %eax
	and $~1, %al
	mov %eax, %cr0
	
	ljmp $0, $real

real:	

	/* Sets %ax to 0.  (I'm not sure why we're not using mov.) */
	xor %ax, %ax

	/* Set all the segment registers to 0, just so we know for sure
	what's going on. */
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs

	mov %ax, %ss

	mov $0x7bfc, %bp // $0x7c00 - $4
	mov %bp, %sp 
	
	// Print debugging message indicating we are back in real mode.
	mov $0x0E, %ah
	mov $0x52, %al // 'R'
	int $0x10

	mov $0x4D, %al // 'M'
	int $0x10

	mov $0x20, %al // ' '
	int $0x10
	

/*******************************************************************
 *	
 * Dump the data buffer to the boot device.
 *
 ******************************************************************/

.set drive_type,              -4
.set max_sector_num,          -8
.set max_cylinder_num,       -12
.set max_head_num,           -16
.set num_drives,             -20
.set total_sectors_written,   -24

	// Make room on the stack for some local variables.
	add total_sectors_written, %sp  
	movw $0, total_sectors_written(%bp)

	
	/////////////////////////////////////
	//
	// First, gather data about the drive
	//
	/////////////////////////////////////
	mov $0x08, %ah
	mov initial_dl, %dl
	// %es and %di should still be 0 at this point.
	// (www.ctyme.com/intr/rb-0621.html recommends that %es:%di be 0:0)
	int $0x13 

	// Save the returned values before we mess them up.  (These
	// values probably need only be 16-bit; but, better safe than
	// sorry.)	
	mov %bx, drive_type(%bp)       // Drive type
	mov %cx, max_sector_num(%bp)   // max sector number
	mov %cx, max_cylinder_num(%bp) // max cylinder number
	mov %dx, max_head_num(%bp)     // max head number
	mov %dx, num_drives(%bp)       // num drives
	
	// isolate max sector number
	andw $0x003F, max_sector_num(%bp) // max sector number is bits 0-5 only

	// isolate max cylinder number
	shrw $8, max_cylinder_num(%bp)       // move %ch into low 8 bits
	andw $0x00FF, max_cylinder_num(%bp)  // remove other bits
	shlw $2, %cx	      // move %cl bits 6 and 7 to bits 8 and 9
	andw $0x0300, %cx     // remove extra bits.
	orw %cx, max_cylinder_num(%bp)

	// isolate max head number
	shrw $8, max_head_num(%bp)

	// isolate num drives
	andw $0x00ff, num_drives(%bp)
	

	/////////////////////////////////////
	//
	// Now, actually dump the data
	//
	/////////////////////////////////////

	
	// When using BIOS to write data, source address goes in %es:%bx.
	//
	// Because the data buffer takes up multiple segments, we will
	// (1) Make sure the data buffer is aligned on a 16-byte 
	// boundary (this is done in by the linker script), and (2) move
	// the segment pointer only.  (Adding 1 to %es will effectively
	// move the pointer forward by 16 bytes.)

	// After loading the data_buffer address into bx, we can view the
	// source address as 0:%bx (e.g., 0:64).  We then divide %bx by
	// 16 to compute the segment at which the buffer begins.
	// (In other words, we're converting 0:64 into 16:0.)
	mov $data_buffer_section, %bx
	shr $4, %bx
	mov %bx, %es
	mov $0, %bx

	
	mov $0, %ch                      // Cylinder number
	mov $0x1, %cl                    // Target sector (indexed from 1)
	mov $0x00, %dh		         // Disk head
	mov initial_dl, %dl              // Drive head (saved earlier)

	//
	// Write an entire track
	//
write_track:	
	mov $0x03, %ah     // BIOS command to write to disk
	mov $1, %al        // Write one sector at a time (for simplicity)
	int $0x13
	jc write_error

	/*
	push %ecx
	mov total_sectors_written, %ecx
	call print_word_hex
	pop %ecx
*/

	
	// Move the data pointer.  Remember, instead of moving the base
	// address, we move the segment (%es) only.  Advancing the segment
	// by 1 moves 16 bytes forward in memory.  Thus, to point at the
	// next 512 byte segment, we advance %es by 512/16 = 32.
	mov %es, %bx
	add $32, %bx
	mov %bx, %es
	mov $0, %bx
	
	add $1, total_sectors_written(%bp)

	// We are completely done writing when we've written
	// max_buffer_sectors sectors
	mov total_sectors_written(%bp), %ax
	cmp max_buffer_sectors, %ax
	je write_done

	
	// If we just wrote the max_sector_num,
	// then we need to move to a new track
	cmp max_sector_num(%bp), %cl
	je track_done
	
	add $1, %cl       // Increment the sector number
	
	jmp write_track   // go back and write the next sector

track_done:

	mov $0x0E, %ah
	mov $0x2e, %al // '.'
	int $0x10

	/* For debugging
	push %ecx
	mov total_sectors_written(%bp), %ecx
	call print_word_hex
	pop %ecx
	*/
	
	mov $1, %cl             // Reset to sector 1.

	// Check whether we are using the last head
	cmp max_head_num(%bp), %dh
	je next_cylinder

	// If we aren't using the last head, increment
	// and move on
	add $1, %dh             // move to the next head.
	jmp write_track

	// Otherwise, re-set head to 0 and increment the cylinder number
next_cylinder:	

	mov $0, %dh
	add $1, %ch // Move to the next cylinder
	jmp write_track
	
write_done:	
	jmp os_halt


write_error:
	// Print a debug message that we are about to halt.
	mov $0x0E, %ah
	mov $0x45, %al // 'E'
	int $0x10
	
	mov $0x72, %al // 'r'
	int $0x10
	
	mov $0x72, %al // 'r'
	int $0x10

	mov $0x20, %al // ' '
	int $0x10

	// display the error code
	mov %eax, %ecx
	call print_word_hex
	
	
/*******************************************************************
 *	
 * halt
 *
 ******************************************************************/


os_halt:	
	// Print a debug message that we are about to halt.
	mov $0x0E, %ah
	mov $0x48, %al // 'H'
	int $0x10
	
	mov $0x6C, %al // 'l'
	int $0x10
	
	mov $0x74, %al // 't'
	int $0x10

	// Done
	hlt
	jmp .


/********************************************************************/
/********************************************************************
 **	
 ** Debug functions
 **
 *******************************************************************/
/*******************************************************************/

	
/////////////////////////////////////////////////////////////////
//	
// Used for debugging
//
// Place word to print in %ecx before calling.
// (Yes, I know that's not the standard calling convention.)
//
/////////////////////////////////////////////////////////////////
print_word_hex:	
	push %eax
	push %ebx
	push %edx
	
	mov %ecx, %eax
	shr $12, %eax
	and $0x0f, %al
	cmp $10, %al
	jae letter3
	add $'0, %al
	jmp pend3
letter3: 
	add $0x37, %al /* 0x37 == 'A' - 10 */
pend3:
	mov $0x0E, %ah
	int $0x10

	mov %ecx, %eax
	shr $8, %eax
	and $0x0f, %al
	cmp $10, %al
	jae letter4
	add $'0, %al
	jmp pend4
letter4:
	add $0x37, %al /* 0x37 == 'A' - 10 */
pend4:
	mov $0x0E, %ah
	int $0x10

	mov %ecx, %eax
	shr $4, %al
	cmp $10, %al
	jae letter
	add $'0, %al
	jmp pend
letter:
	add $0x37, %al /* 0x37 == 'A' - 10 */
pend:
	mov $0x0E, %ah
	int $0x10

	mov %ecx, %eax
	and $0x0f, %al
	cmp $10, %al
	jae letter2
	add $'0, %al
	jmp pend2
letter2:
	add $0x37, %al /* 0x37 == 'A' - 10 */
pend2:
	mov $0x0E, %ah
	int $0x10

	mov $0x20, %al
	int $0x10
	
	pop %edx
	pop %ebx
	pop %eax
	
	ret

/////////////////////////////////////////////////////////////////
//	
// Used for debugging
//
// Print the string in %si
//
/////////////////////////////////////////////////////////////////
print_string:	
	mov $0x0e, %ah
	cld
ps_loop:
	lodsb
	or %al, %al
	jz ps_end
	int $0x10
	jmp ps_loop
ps_end:
	ret


/////////////////////////////////////////////////////////////////
//	
// Used for debugging
//
// Print a newline
//
/////////////////////////////////////////////////////////////////
	
print_newline:
	mov $0x0E, %ah
	mov $'\n, %al 
	int $0x10

	mov $'\r, %al 
	int $0x10
	ret
	
	
/////////////////////////////////////////////////////////////////
//	
// Used for debugging
//
// Print the string in %si
//
/////////////////////////////////////////////////////////////////
	
print_drive_parameters:
	call print_newline

	mov $max_sector_size_str, %si
	call print_string
	mov max_sector_num(%bp), %ecx
	call print_word_hex
	call print_newline

	mov $max_cylinder_str, %si
	call print_string
	mov max_cylinder_num(%bp), %ecx
	call print_word_hex
	call print_newline

	mov $max_head_num_str, %si
	call print_string
	mov max_head_num(%bp), %ecx
	call print_word_hex
	call print_newline

	mov $num_drives_str, %si
	call print_string
	mov num_drives(%bp), %ecx
	call print_word_hex
	call print_newline
	
	ret



/********************************************************************/
/********************************************************************
 **	
 ** data section!!!
 **
 *******************************************************************/
/*******************************************************************/

	
.section .data
max_sector_size_str:	.asciz "Max sector num: "
max_cylinder_str:	.asciz "Max cylinder: "
max_head_num_str:	.asciz "Max head num: "
num_drives_str:	        .asciz "Num drives: "

	// A 1.44MB floppy disk has 18*80*2 = 0xb40 sectors.
	// However, we can't have a 1.44 MB buffer.
	// (1) Real mode can only access 1MB of RAM, and
	// (2) There less space than that between where the
	// linker will place data_buffer and the end of
	// "useable" RAM (i.e., RAM that isn't reserved for another
	// purpose.)
//max_buffer_sectors:	.word ((0x9fc00 - data_buffer) / 512)
max_buffer_sectors:	 .word 0x4b2 // Actually +1 for loop purposes

	
.section .data2
	// data_buffer_section is where we begin dumping the buffer back
	// to the boot disk.  This means we can scan the boot disk for
	// the "magic words" here.
	//
	// data_buffer is the address used to initialize the data_buffer
	// this is where the user-genered data will start to appear.

	// data_buffer_section is set to be exactly 32 bytes long
	// (including he newline).  This way, it fits nicely in the
	// hexdump output, and also prints as expected if the raw data is
	// sent directly to the screen.
data_buffer_section:   .ascii "********* Output Data *********\n" 
data_buffer:           .ascii "<The actual data will overwrite this>"

