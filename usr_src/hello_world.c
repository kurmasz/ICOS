#include "icos.h"
#include "vga_text.h"
#include "data_buffer.h"


// Convert all vowels in string to upper case
void upcase_vowels(char* string) {

  char* s = string;
  while (*s != '\0') {
    if (*s == 'a' || *s == 'e' || *s == 'i' || *s == 'o' || *s == 'u') {
      *s += 'A' - 'a';
    }
    ++s;
  }
}


// Kernel entry point
void hello_world() {

  // Sets up two areas of the screen.  The first 5 lines are the
  // "head", and the remainder of the screen is the "body".  When a
  // section gets full, the text wraps back to the top of the section.
  // Sections wrap seprately, so you can write important data to head 
  // without it being overwriten by body.
  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 5);


  // This string should appear with the vowels capitalized.
  char hw[] = "Hello, World!\n";
  upcase_vowels(hw);
  vgat_write_string(&head, hw);

  vgat_write_string(&head, "Filling data buffer ...");  

  // We use 7-digit numbers so that the output looks nice in hexdump
  for (unsigned i = 2000000; data_buffer_is_full() == 0 ; i++) {
    data_write_unsigned(i, " ");
    if (i % 1000 == 0) {
      vgat_write_unsigned(&body, i, " ");
    }
  }

  vgat_write_string(&body, "\nData Buffer is full");  
  vgat_write_string(&head, " Done!");  
  vgat_write_string(&head, " \n But I want the text to be a bit longer.");  
}


