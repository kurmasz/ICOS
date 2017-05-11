#include "vga_text.h"
#include "ic_util.h"


uint8_t make_color(enum vga_color fg, enum vga_color bg) {
	return fg | bg << 4;
}

uint16_t make_vgaentry(char c, uint8_t color) {
	uint16_t c16 = c;
	uint16_t color16 = color;
	return c16 | color16 << 8;
}

const size_t VGA_WIDTH = 80;
const size_t VGA_HEIGHT = 25;
static uint16_t* vgat_buffer = (uint16_t*)0x62414756; // VGAb
static char vgat_initialized= '\0';

static void vgat_initialize() {
  uint8_t terminal_color = make_color(COLOR_LIGHT_GREY, COLOR_BLACK);
#if DEBUG
  vgat_buffer = (uint16_t*) malloc(VGA_HEIGHT*VGA_WIDTH*sizeof(uint16_t));
#else
  vgat_buffer = (uint16_t*) 0xB8000;
#endif 

  for (size_t y = 0; y < VGA_HEIGHT; y++) {
    for (size_t x = 0; x < VGA_WIDTH; x++) {
      const size_t index = y * VGA_WIDTH + x;
      vgat_buffer[index] = make_vgaentry(' ', terminal_color);
    }
  }
  vgat_initialized = 'y';
}

void vgat_initialize_section(vga_text_section_t* section, 
				 size_t start_row, size_t bottom_row, 
				 size_t start_column, size_t right_column) {

  if (vgat_initialized == '\0') { vgat_initialize();} 

  section->top_row = start_row;
  section->bottom_row = bottom_row;
  section->left_column = start_column;
  section->right_column = right_column;

  section->current_row = start_row;
  section->current_column = start_column;

  section->current_color = make_color(COLOR_LIGHT_GREY, COLOR_BLACK);
}


void vgat_initialize_full_screen(vga_text_section_t* section) {
  if (vgat_initialized == '\0') { vgat_initialize();}
  vgat_initialize_section(section, 0, VGA_HEIGHT-1, 0, VGA_WIDTH-1);
}

void vgat_initialize_head_body(vga_text_section_t* head, 
			       vga_text_section_t* body, 
			       int lines_in_head) {
  char orig = vgat_initialized;

  if (vgat_initialized == '\0') { vgat_initialize();}

  // Leave a blank line at the top for the startup/shutdown debugging info
  vgat_initialize_section(head, 1, lines_in_head, 0, VGA_WIDTH-1);
  vgat_initialize_section(body, lines_in_head, VGA_HEIGHT-1, 0, VGA_WIDTH-1);

  vgat_write_unsigned(body, (unsigned)orig, "<== orig\n");

}


void vgat_setcolor(vga_text_section_t* section, uint8_t color) {
	section->current_color = color;
}

// Place globally
void vgat_putentryat(char c, uint8_t color, size_t x, size_t y) {
	const size_t index = y * VGA_WIDTH + x;
	vgat_buffer[index] = make_vgaentry(c, color);
}


void vgat_putchar(vga_text_section_t* section, char c) {
  if (c == '\n') {
    for (;section->current_column <= section->right_column; ++(section->current_column)) {
        vgat_putentryat(' ', section->current_color, 
			    section->current_column, section->current_row);
    }
    section->current_column = section->left_column;
    ++(section->current_row);
    if (section->current_row > section->bottom_row) {
      section->current_row = section->top_row;
    }
    return;
  }
  vgat_putentryat(c, section->current_color, 
		      section->current_column, section->current_row );
  ++(section->current_column);
  if (section->current_column > section->right_column) {
    section->current_column = section->left_column;
    ++(section->current_row);
    if (section->current_row > section->bottom_row ) {
      section->current_row = section->top_row;
    }
  }
}

void vgat_write_string(vga_text_section_t* section, const char* data) {
	size_t datalen = ic_strlen(data);
	for (size_t i = 0; i < datalen; i++)
	  vgat_putchar(section, data[i]);
}

#define WRITEINT_BUFFER 100
void vgat_write_unsigned(vga_text_section_t* section, unsigned long value, const char* data) {
  static char buffer[WRITEINT_BUFFER];
  int place = WRITEINT_BUFFER;

  if (value == 0) {
    vgat_putchar(section, '0');
  } else {
    while (value > 0) {
      buffer[--place] = (value % 10) + '0';
      value /= 10;
    }

    for(; place < WRITEINT_BUFFER; place++) {
      vgat_putchar(section, buffer[place]);
    }
  } // end else

  if (data != NULL && data[0] != 0) {
    vgat_write_string(section, data);
  }
}


void vgat_write_unsigned_hex(vga_text_section_t* section, unsigned long value, const char* data) {
  static char buffer[WRITEINT_BUFFER];
  int place = WRITEINT_BUFFER;

  /*
  if (data != NULL) {
    vgat_write_unsigned_hex(section, (unsigned)data, NULL);
  }
  */

  if (value == 0) {
    vgat_write_string(section, "0x0");
  } else {
    vgat_write_string(section, "0x");
    while (value > 0) {
      if ((value % 16) < 10) {
	       buffer[--place] = (value % 16) + '0';
      } else {
	buffer[--place] = (value % 16) + 'a' - 10;
      }
      value /= 16;
    }

    for(; place < WRITEINT_BUFFER; place++) {
      vgat_putchar(section, buffer[place]);
    }
  } // end else

  if (data != NULL && data[0] != 0) {
    vgat_write_string(section, data);
  }
}



void vgat_write_signed(vga_text_section_t* section, signed long value, const char* data) {
  if (value < 0) {
    vgat_putchar(section, '-');
    value = -value;
  }
  vgat_write_unsigned(section, (unsigned long)value, data);
}


#if DEBUG
void vgat_dump() {
  char buffer[VGA_WIDTH*VGA_HEIGHT];
  for (size_t i = 0; i < VGA_WIDTH*VGA_HEIGHT; i++) {
    buffer[i] = (char) vgat_buffer[i];
  }
  for (size_t row = 0; row < VGA_HEIGHT; row++) {
    buffer[row*VGA_WIDTH + VGA_WIDTH -1] = '\0';
    puts(buffer + row*VGA_WIDTH);
  }
}
#endif
