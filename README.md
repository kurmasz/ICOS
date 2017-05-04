A small, not-quite-an-OS that can be used to

1. Show students a few key aspects of writing an OS, or

2. Carefully time code without worrying about interrupts, page faults,
context switches, etc.

This is not, by any means, a full OS.  It doesn't have device drivers,
processes, virtual memory, or anything like that.  Instead, it does
the following:

* Loads itself.
* Switches to protected mode
* Runs user-supplied 32-bit code.
* Switches back to real mode
* Dumps a data buffer back to the boot device

This setup serves two purposes:

1. It is simple enough for OS students to understand from beginning to
end.  This tool can serve as a first step before digging into
something more full-featured like minix, nanvix, or xinu.

2. It provides a mechansim for students to write carefully timed code.
The timing data can be saved in a data buffer.  ICOS automatically
dumps that data buffer back to the boot medium (typically a USB drive)
for off-line analysis.