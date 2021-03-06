###############################################################################
#
# Makefile for ICOS
#
# (C) 2017 Zachary Kurmas
#
# This Makefile requires that i686-elf-gcc, and other necessary 
# toolchain compnents, be in the PATH.
#
# User code goes in usr_src.  All code in os_src and usr_src will be
# built into the OS image.  A image with the name my_os.img is assumed
# to begin at a function named void my_os(void).  Thus, to create a
# new, custom image named my_custom_os.img, simply
#
# (1) Create a function somewhere in usr_src named void my_custom_os(void)
#
# (2) run make my_custom_os.img
#
# Note:  Because both the .o and .img files are generated by implicit rules,
# make considers the .o files "intermediate" and autmoatically deletes them.
# At the moment, the compiliation process is fast enough that the repeated 
# rebuilds aren't a problem.  If the rebuilding becomes annoying, see this 
# article:  
# https://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
#
###############################################################################

#
# Directories
#
OS_SRC   = os_src
USR_SRC  = usr_src
OS_OBJ   = obj/os
BOOT_OBJ = obj/boot
USR_OBJ  = obj/usr
TEST     = test


# Elf compiler
elfCC    = i686-elf-gcc

# The -fno-asynchronous-unwind-tables tells gcc not to include the
# .eh_frame in the object files.  This data is primarily used for
# exception handling, which is not currently supported by ICOS. 
# (See https://stackoverflow.com/questions/26300819)
CFLAGS    = -std=c99 -ffreestanding -fno-asynchronous-unwind-tables -Wall -Wextra -I $(OS_SRC)


#
# Files
#
os_headers = $(wildcard $(OS_SRC)/*.h)      # all *.h files in the os_src dir
os_c_sources = $(wildcard $(OS_SRC)/*.c)    # all *.c files in the os_src dir
os_s_sources = $(wildcard $(OS_SRC)/*.s)    # all *.s files in the os_src dir
os_sources = $(os_c_sources) $(os_s_sources)

usr_headers = $(wildcard $(USR_SRC)/*.h)    # all *.h files in the usr_src dir
usr_c_sources = $(wildcard $(USR_SRC)/*.c)  # all *.c files in the usr_src dir
usr_s_sources = $(wildcard $(USR_SRC)/*.s)  # all *.s files in the usr_src dir
usr_sources = $(usr_c_sources) $(usr_s_sources)

# Convert each .c/.s file name into the corresponding .o file name
# (change .c/.s to .o, then change the directory name)
os_objs =  $(subst $(OS_SRC), $(OS_OBJ), $(os_c_sources:.c=.o) $(os_s_sources:.s=.o))
usr_objs = $(subst $(USR_SRC), $(USR_OBJ), $(usr_c_sources:.c=.o) $(usr_s_sources:.s=.o))

all: setup hello_world.img

#
# Create the obj directories, if they don't already exist.
#
$(OS_OBJ):
	mkdir -p $@

$(USR_OBJ):
	mkdir -p $@

$(BOOT_OBJ):
	mkdir -p $@


setup: $(OS_OBJ) $(USR_OBJ) $(BOOT_OBJ)


clean:
	rm -f $(OS_OBJ)/*.[os] $(USR_OBJ)/*.[os] $(BOOT_OBJ)/*.[os] 
	rm -f $(USR_SRC)/ag*.c
	rm -f *.img *.debug

#############################################################################
#
# Compile "core" OS
#
#############################################################################

COMPILE = $(elfCC) $(CFLAGS) -c $< -o $@ -O2 -I $(OS_SRC)

# Headers shouldn't change much.  If they do, then just re-build all
# the .o files
$(OS_OBJ)/%.o: $(OS_SRC)/%.c $(os_headers) | $(OS_OBJ)
	$(COMPILE)
        # generate the assembly file, in case we want to look at it later.
	$(elfCC) $(CFLAGS) -S $< -o $(@:.o=.s) -O2 

# A few OS-supplied routines are better implemented in assembly
#$(OS_OBJ)/ic_util_asm.o: $(OS_SRC)/ic_util_asm.s | $(OS_OBJ)
#	$(elfCC) $(CFLAGS) -c $< -o $@ -O2
$(OS_OBJ)/%.o: $(OS_SRC)/%.s $(os_headers) | $(OS_OBJ)
	$(COMPILE)

# By naming the file boot.S (instead of boot.s), gcc will run the 
# pre-processor and substitute KERNEL_MAIN with the pattern stem, which 
# is the user-chosen function serving as the kernel entry point.
$(BOOT_OBJ)/%.o: $(OS_SRC)/boot.S
	$(elfCC) $(CFLAGS) -DKERNEL_MAIN=$* -c $< -o $@ -O2


############################################################################
#
# Compile "user provided" parts of OS
#
###########################################################################

# Headers shouldn't change much.  If they do, then just re-build all the 
# .o files
$(USR_OBJ)/%.o: $(USR_SRC)/%.c $(os_headers) $(usr_headers) | $(USR_OBJ)
	$(COMPILE)
        # generate the assembly file, in case we want to look at it later.
	$(elfCC) $(CFLAGS) -S $< -o $(@:.o=.s) -I $(OS_SRC) 

$(USR_OBJ)/%.o: $(USR_SRC)/%.s $(os_headers) $(usr_headers) | $(USR_OBJ)
	$(COMPILE)

############################################################################
#
# Bootable image
#
###########################################################################

%.img: $(BOOT_OBJ)/%.o $(os_objs) $(usr_objs) | linker.ld setup
	i686-elf-ld --oformat binary -o $@ $^ -T linker.ld --print-map > /tmp/icos_map.txt


############################################################################
#
# Debug (user space)
#
###########################################################################

# Produces a version of the OS that can run as a normal user process.
# Potentially helpful for debugging.
#
# Note the -m32 flag below.  This causes pointers to be 32 bits
# instead of 64, and therefore allows us to convert pointers to
# unsigned integers and print them out
%.debug: $(os_sources) $(usr_sources) | $(os_headers) $(usr_headers) setup
	gcc $(CFLAGS) -m32 -DDEBUG -g -DKERNEL_MAIN=$* -o $@ $^





#############################################################################
#############################################################################
##
## Test
##
## To run tests
## (1) bochs must be in the path
## (2) The BXSHARE environment variable must be set
############################################################################
#############################################################################

## TODO: Write a ruby script that automatically verifies that
  ##  large_code_10 requires < 1 full cylinder (i.e, at most 18 sectors) 
  ##	(hint: Look in the map file generated by the linker)
  ##  large_code_500 requires between 1 and 2 cylinders (i.e, 19 - 35 sectors)

#
# large_code_10 fits in one track.
# large_code_500 requires several tracks (and crossing a 64KiB boundary)
# large_code_5000 is bigger yet.
# large_code_25000 is about as much code as we can fit on a floppy 
#         (but, we don't include in test, because it takes so long to compile)

test: clean test_hello_world test_large_code_10 test_large_code_500 test_large_code_5000

test_hello_world:  hello_world.img $(TEST)/debug_steps $(TEST)/bochsrc
	cp hello_world.img $(TEST)/tmp/hello_world_tmp.img
	bochs -q -rc $(TEST)/debug_steps -f $(TEST)/bochsrc "floppya: 1_44=$(TEST)/tmp/hello_world_tmp.img, status=inserted"
	head -c 553728 $(TEST)/tmp/hello_world_tmp.img | diff $(TEST)/expected_output/hello_world_expected -
	@echo "Hello World Success"





############################################################################
#
# Large Code Test
#
# The rules here build an image that can be used to test ICOS's boot loader
# Specifically, using larger numbers verifies that the boot loader 
# correctly loads calls when the code takes up more than one track.
#
# For the most part, the rules below are very similar to the general 
# rules above; however, I didn't want the large auto-generated files
# to mess up or complicate the general student-centered build process.
# Yes, there are some "DRY" violations here, but they are done to keep 
# the makefile above simpler.
#
#
###########################################################################

LC_TEST=$(TEST)/tmp

test_clean:
	rm -rf $(LC_TEST)/*

#
# Uses a ruby script to generate a lot of C code.
#
$(LC_TEST)/ag_large_code_%.c: $(TEST)/generate_large_code.rb
	ruby $(TEST)/generate_large_code.rb $* > $@

$(LC_TEST)/%.o: $(LC_TEST)/%.c
	$(elfCC) $(CFLAGS) -c $< -o $@ -O2

$(LC_TEST)/%.o: $(TEST)/%.c
	$(elfCC) $(CFLAGS) -c $< -o $@ -O2


$(LC_TEST)/large_code_test_boot.o: $(OS_SRC)/boot.S
	$(elfCC) $(CFLAGS) -DKERNEL_MAIN=large_code_test -c $< -o $@ -O2

# This rule only includes specific objects in usr_objs, because we
# don't want other user code (or previously augo-generated large files)
# to influence the image size.
large_code_test_%.img: $(LC_TEST)/ag_large_code_%.o $(LC_TEST)/large_code_test.o  $(LC_TEST)/large_code_test_boot.o $(os_objs) $(OS_OBJ)/ic_util_asm.o | linker.ld setup
	i686-elf-ld --oformat binary -o $@ $^ -T linker.ld --print-map > /tmp/icos_map_lc_$*.txt



test_large_code_%:  large_code_test_%.img $(TEST)/debug_steps $(TEST)/bochsrc
	cp large_code_test_$*.img $(LC_TEST)/large_code_test_$*_tmp.img
	bochs -q -rc $(TEST)/debug_steps -f $(TEST)/bochsrc "floppya: 1_44=$(LC_TEST)/large_code_test_$*_tmp.img, status=inserted"
	head -c 152 $(LC_TEST)/large_code_test_$*_tmp.img | diff $(TEST)/expected_output/large_code_test_$* -
	@echo "Large Code $* Success"


