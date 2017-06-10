#include "icos.h"
#include "vga_text.h"
#include "data_buffer.h"

unsigned use_all(unsigned);
unsigned expected_output(unsigned);

// This function is declared here because it should be used for
// testing and debugging only.  Placing it in data_buffer.h might
// encourage use by end users. (See note in data_buffer.h.)
char data_charat(size_t p);

// Kernel entry point
void large_code_test() {

  // Sets up two areas of the screen.  The first 10 lines are the
  // "head", and the remainder of the screen is the "body".  When a
  // section gets full, the text wraps back to the top of the section.
  // Sections wrap seprately, so you can write important data to head 
  // without it being overwriten by body.
  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 10);
  vgat_write_string(&head, "Testing large code:\n");

  // Copy the initial contents of the data buffer into
  // initial_contents.  Specifically, copy up to the first newline,
  // but stop after 50 characters.  


  // boot.S places a hard-coded string into the data buffer.  This
  // data buffer header is the last thing that the boot loader should
  // place in memory.  Thus, by verifying that this header is loaded
  // into memory, we know that the boot loader is working properly.
  const size_t MAX = 50;
  char initial_contents[MAX];
  size_t i = 0;
  for (i = 0; i < MAX-1; i++) {
    initial_contents[i] = data_charat(i);
    if (initial_contents[i] == '\0') {
      initial_contents[i] = '.';
    } else if (initial_contents[i] == '\n') {
        // Notice that this terminating newline will be overwritten
        // below by the '\0';thus, it won't appear in the output.
      break;
    }
  }
  initial_contents[i] = '\0';

  vgat_write_string(&head, "Initial data buffer contents: =>");
  vgat_write_string(&head, initial_contents);
  vgat_write_string(&head, "<=\n");

  data_write_string("Initial data buffer contents: ");
  data_write_string(initial_contents);

  unsigned seed = 7;
  unsigned expected = expected_output(seed);
  unsigned observed = use_all(seed);
  vgat_write_string(&head, "Expected: ");
  vgat_write_unsigned(&head, expected, "\nObserved: ");
  vgat_write_unsigned(&head, observed, "\n");

  data_write_string("\nExpected: ");
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


