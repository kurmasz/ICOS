#include "icos.h"
#include "vga_text.h"
#include "data_buffer.h"

unsigned use_all(unsigned);
unsigned expected_output(unsigned);

// Kernel entry point
void large_code_test() {

  // Sets up two areas of the screen.  The first 5 lines are the
  // "head", and the remainder of the screen is the "body".  When a
  // section gets full, the text wraps back to the top of the section.
  // Sections wrap seprately, so you can write important data to head 
  // without it being overwriten by body.
  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 10);

  // This string should appear with the vowels capitalized.
  char hw[] = "Testing large code:\nExpected: ";
  vgat_write_string(&head, hw);


  unsigned seed = 7;
  unsigned expected = expected_output(seed);
  unsigned observed = use_all(seed);
  vgat_write_unsigned(&head, expected, "\nObserved: ");
  vgat_write_unsigned(&head, observed, "\n");

  data_write_string("Expected: ");
  data_write_unsigned(expected, "\nObserved: ");
  data_write_unsigned(observed, "\n");
  if (expected == observed) {
    vgat_write_string(&head, "Success!\n");
    data_write_string("Success!\n---------------\n\n");
  } else {
    vgat_write_string(&head, "Fail!\n");
    data_write_string("Fail!\n---------------\n\n");
  }

  vgat_write_string(&head, "\nDone!");  
}


