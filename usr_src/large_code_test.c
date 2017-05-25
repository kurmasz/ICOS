#include "icos.h"
#include "vga_text.h"
#include "data_buffer.h"

unsigned use_all(unsigned);

// Kernel entry point
void large_code_test() {

  // Sets up two areas of the screen.  The first 5 lines are the
  // "head", and the remainder of the screen is the "body".  When a
  // section gets full, the text wraps back to the top of the section.
  // Sections wrap seprately, so you can write important data to head 
  // without it being overwriten by body.
  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 5);

  // This string should appear with the vowels capitalized.
  char hw[] = "Testing large code: ";
  vgat_write_string(&head, hw);

  unsigned answer = use_all(7);
  vgat_write_unsigned(&head, answer, "\n");


  vgat_write_string(&head, "Filling data buffer ...");  

  // We use 7-digit numbers so that the output looks nice in hexdump
    for (unsigned i = 2000000; data_buffer_is_full() == 0 ; i++) {
      //for (unsigned i = 2000000; i < 2000000 + 76000  ; i++) {
    data_write_unsigned(i, " ");
    if (i % 1000 == 0) {
      vgat_write_unsigned(&body, i, " ");
    }
  }

  vgat_write_string(&body, "\nData Buffer is full (");  
  vgat_write_unsigned(&body, data_size(), ").\n");  
  vgat_write_string(&head, " Done!");  
}


