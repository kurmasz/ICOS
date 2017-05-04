#ifndef ISEE_UTIL_H
#define ISEE_UTIL_H

#include "icos.h"

unsigned long ic_rdtsc();  // defined in ic_util_asm.s

size_t ic_strlen(const char* str);
uint32_t ic_random();
void ic_randomize(uint32_t seed);

typedef struct {
  int vga_has_failed;
} global_debug_data_t;
extern global_debug_data_t gdd;
void initialize_gdd();

#endif
