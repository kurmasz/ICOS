#include "icos.h"
#include "vga_text.h"
#include "data_buffer.h"

global_debug_data_t gdd;
void initialize_gdd() {
  gdd.d1 = 0;
  gdd.d2 = 0;
  gdd.d3 = 0;
  gdd.p1 = NULL;
  gdd.p2 = NULL;
  gdd.p3 = NULL;
}

#ifdef DEBUG
void KERNEL_MAIN();
int main(int argc, char* argv[]) {
  const size_t buf_size = 1048576;
  char* buffer = (char*) malloc(buf_size);
  data_initialize(buffer);

  KERNEL_MAIN();
  vgat_dump();

  if (argc < 2) {
    fprintf(stderr, "To export the data buffer, "
	    "provide a filename on the command line.\n");
  } else {
    FILE* opt = fopen(argv[1], "w+");
    if (!opt) {
      perror("Canot open file for writing.");
    } else {
      fwrite(buffer, sizeof(char), buf_size, opt);
      fclose(opt);
    }
  }
  
  free(buffer);
  return 0;
}
#endif


