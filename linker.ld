SECTIONS
{

  /* When BIOS loads this image into memory, it will place the first
     512 bytes at memory address 0x7c00.  This line tells the linker
     to set it's internal pointer to this address so that the values
     for labels are set accordingly.  */ 
  . = 0x7c00; 
  __start = .;

  /* First place the code (aka "text") in the image */
  .text :
  {

    /* We need to make sure the first 512 bytes of code to be run are
       placed at the very beginning of the image.  If you look in
       boot.S, you will see that the second line is ".section .boot".
       The line below tells the linker to place this code first (i.e.,
       code annotated with ".section .boot").

       (It is the programmer's job to make sure the code in this
       section doesn't exceed 512 bytes. If it does, some of the code
       won't get loaded.)  */ 
    *(.boot)

     /* Place the machine code for the instruction 'jmp .' at memory
        location 0x7dfc.

        The hex value 0xfeeb is the machine code for the assembly
        instruction 'jmp .'  Executing this instruction enters an
        infinite loop, effectively terminating the execution of the
        CPU. Placing this code at location 0x1FC in the image causes
        it to be placed at memory address 0x7dfc.  Placing this final
        instruction at a known memory location allows us to write
        bochs debug scripts that break when the OS terminates (i.e.,
        when it is directed to address 0x7dfc).  */

      . = 0x1FC;
      SHORT(0xfeeb)


    /* Place the "magic" word 0x55AA at the end of the boot sector.

       BIOS can tell if a device is bootable by looking at the last
       two bytes of the first 512 byte sector.  If they happen to be
       0xAA55, then BIOS assumes the sector contains bootable code.
       The line . = 0x1FE moves the internal pointer up to 0x1FE =
       510; thus, assuring that the "magic word" is placed correctly.
     */ 

     . = 0x1FE; 
     SHORT(0xAA55)

     /* The code in the ".boot" section (the first 512 bytes) is
        responsible for issuing the BIOS calls to load the next
        sections of code.  If you look in boot.S, you will see that
        the code for this second stage of booting is placed in
        ".section .stage2".  The line below places this startup code
        immediately following the boot sector.  "stage2" contains code
        that moves the processor from "real" mode to "protected" mode,
        then calls the function that represents the entry point of the
        OS. */
    *(.stage2) 

    /* All other code (i.e., code that is not part of the boot loader)
       is placed in ".section .text".  The line below instructs the
       linker to place this remaining code next in the image. */
    *(.text)
  }


  /* Read-only data.  When generating assembly code, gcc places
     hard-coded strings (among other things) in .section .rodata */
  .rodata : ALIGN(512)
  {
    *(.rodata*)  /* using .rodata* includes .rodata.str1.1 */
    LONG(0x68686868) /* hhhh marks end of .rodata*/
  }

  /* Read-write data.  When generating assembly code, gcc places
     global and static data in .section .data. */
  .data : ALIGN(512)
  {
    LONG(0x69696969) /* iiii marks beginning of data*/
    *(.data)
  }

  /* C compilers create a .bss section for staticly allocated
     variables that are initialized to 0.  (These static variables can 
     either have file scope or function scope.) */
  .bss : ALIGN(512)
  {
    LONG(0x31737362)  /* "bss1" */
    *(.bss*)
    LONG(0x32737362)  /* "bss2" */
  }   


  /* Data for the disk dump.  To keep the OS as simple as possible,
  the only way to export data (other than writing to the screen) is to
  dump a memory buffer back to the boot media. If you look in boot.S,
  you will see that this memory buffer is placed in ".section .data2".
  We gave it its own section so we could assure that it would be
  placed last in the image (i.e., after all the other code and data.)
  */

  .data2 :  ALIGN(512)
  {
    *(.data2)
    /* jjjj (Marker so we can find location in the image.)
       This marker comes at the end so that the variables in .data2
       are aligned on 512 byte boundaries */
    LONG(0x6a6a6a6a) 
  }

  /* Calculate the total number of sectors used by the code and data.
      Normally, the "." gives the value of the linker's internal
      pointer relative to the current section.  Surrounding the
      calculation with ABSOLUTE assures that the values used are
      relative to the entire image.  This value is used in boot.S to
      specify the number of sectors that must be loaded
  */
   __stage2_nsectors = ABSOLUTE((. - __start) / 512) + 1;

   /* Ensure that the generated image is a multiple of 512 bytes
   long. (Some machines and VMs freak out if the boot image is not a
   multiple of 512 bytes. */
   __end = .;
   __end_align_4k = ALIGN(4k);




   /* This OS exports data by dumping a memory buffer back to the boot
      image.  When running on a VM, you can't dump data beyond the
      original size of the image. This "fake" section below
      artificially increases the size of the boot image.  

      Because the image is padded to a multiple of 512 above, and the
      section below is exactly 1MB, we know the resulting image will
      be a multiple of 512 bytes long.*/
	
  .data3 : ALIGN(1024) { 


    /* Places 'DATA' in the image to mark where
       in memory the data will be dumped. */
    LONG(0x41544144)   

    /* Make sure that the disk image is a multiple of 512 bytes.  */   
    . = 0x100000 - 4;  

    /* Mark the end of the disk image with 'END'. */
    LONG(0x444E4500);  
  }
}

