#include "icos.h"
#include "vga_text.h"


unsigned d1 = 0x57575757;  // initialized and put in .data section
unsigned not_initialized;  // uninitialized and put in .bss section

void a20_test() { 

  not_initialized = 0x11223344;


  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 5);

  vgat_write_unsigned_hex(&body, (unsigned)&d1, " <= &d1\n");
  vgat_write_unsigned_hex(&body, (unsigned)&not_initialized, " <= &ni\n");
  vgat_write_unsigned_hex(&body, not_initialized, " <= Original ni value\n");

  unsigned* pni = &not_initialized;
  unsigned* pni2 = (unsigned*) ((unsigned) pni &0xffff);
  vgat_write_unsigned_hex(&body, (unsigned) pni2, " <='fake' pointer\n");
  *pni2 = 0x55667788;
  vgat_write_unsigned_hex(&body, not_initialized, " <= updated ni value\n");
  
}
