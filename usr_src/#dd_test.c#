#include "icos.h"
#include "ic_util.h"
#include "data_buffer.h"
#include "vga_text.h"

void dd_test() { 

  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 5);
  vgat_write_string(&head, "\n");


  vgat_write_string(&body, "Sta ");
  for (unsigned i = 2000000; data_buffer_is_full() == 0 ; i++) {
    data_write_unsigned(i, " ");
    vgat_write_unsigned(&body, i, " ");
  }
  vgat_write_unsigned_hex(&body, data_buffer_is_full(), "\nFull!\n");
}
