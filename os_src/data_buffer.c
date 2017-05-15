#include "data_buffer.h"


/* According to wiki.osdev.org/Memory_Map_(x86), the Extended BIOS
   Data Area (EBDA) begins somewhere around 0x9fc00.  The correct way
   to find the beginning of the EBDA is to access the word at address
   0x040e.  The smallest value I've seen thus far is 0x9d800, so we'll
   use that for now.
*/
   // TODO:  Look up the correct value for a given machine.
static const char* max_address = (char*)(0x9d800);


/* These values are initialized so (1) They are placed in the .data
   section; and (2) We can easily see where in memory they are placed
   when examining the hexdump of the image. */
static char*    dd_buffer    = (char*) 0x57575757; // WWWW
static unsigned dd_place     = 0x54515253;         // SQRT
static unsigned dd_max_place = 0x41424142;         // ABAB


// Used for debugging.  (Every time I think I don't need it anymore
// and delete it, another bug pops up.)
static char* last;
char* last_loc() {
  return last;
}


char data_charat(size_t p) {
  return dd_buffer[p];
}

void data_initialize(char *buffer_in) {
  dd_buffer = buffer_in;
  dd_place = 0;

  // The 6 gives us room to place the 'Full' 
  // message at the end.
  dd_max_place = max_address - dd_buffer - 6;

  #ifdef DEBUG
  dd_max_place = 1048576 - 6;
  #endif

}

void data_putchar(char c) {
  if (dd_place < dd_max_place) {
    last = dd_buffer + dd_place;
    dd_buffer[dd_place++] = c;
  } else {
    dd_buffer[dd_max_place + 1] = 'F';
    dd_buffer[dd_max_place + 2] = 'u';
    dd_buffer[dd_max_place + 3] = 'l';
    dd_buffer[dd_max_place + 4] = 'l';
    dd_buffer[dd_max_place + 5] = '\0';
    last = dd_buffer + dd_max_place + 5;
  }
}

void data_write_string(const char* string) {
  while (*string != '\0') {
    data_putchar(*string);
    ++string;
  }
}

#define WRITEINT_BUFFER 100
void data_write_unsigned(unsigned long value, const char* data) {
  static char lbuffer[WRITEINT_BUFFER];
  int lplace = WRITEINT_BUFFER;

  if (value == 0) {
    data_putchar('0');
  } else {
    while (value > 0) {
      lbuffer[--lplace] = (value % 10) + '0';
      value /= 10;
    }

    for(; lplace < WRITEINT_BUFFER; lplace++) {
      data_putchar(lbuffer[lplace]);
    }
  } // end else

  if (data != NULL && data[0] != 0) {
    data_write_string(data);
  }
}


void data_write_unsigned_hex(unsigned long value, const char* data) {
  static char lbuffer[WRITEINT_BUFFER];
  int lplace = WRITEINT_BUFFER;

  if (value == 0) {
    data_write_string("0x0");
  } else {
    data_write_string( "0x");
    while (value > 0) {
      if ((value % 16) < 10) {
	       lbuffer[--lplace] = (value % 16) + '0';
      } else {
	lbuffer[--lplace] = (value % 16) + 'a' - 10;
      }
      value /= 16;
    }

    for(; lplace < WRITEINT_BUFFER; lplace++) {
      data_putchar(lbuffer[lplace]);
    }
  } // end else

  if (data != NULL && data[0] != 0) {
    data_write_string(data);
  }
}


void data_write_signed(signed long value, const char* data) {
  if (value < 0) {
    data_putchar('-');
    value = -value;
  }
  data_write_unsigned((unsigned long)value, data);
}

unsigned data_size() {
  return dd_place;
}

int data_buffer_is_full() {
  return dd_place >= dd_max_place;
}
