#ifndef ISEE_UTIL_H
#define ISEE_UTIL_H

#include "icos.h"

///////////////////////////////////////////////////////////////////
//
// Functions defined in ic_util_asm.s
//
/////////////////////////////////////////////////////////////////
uint32_t ic_rdtsc();  




///////////////////////////////////////////////////////////////////
//
// Functions defined in ic_util.c
//
/////////////////////////////////////////////////////////////////
size_t ic_strlen(const char* str);
uint32_t ic_random();
void ic_randomize(uint32_t seed);


// This may be helpful for debugging.  The members of this struct are
// very generic, because the needs will vary depending on the specific
// problem being investigated.
typedef struct {
  unsigned int d1;
  unsigned int d2;
  unsigned int d3;
  char* p1;
  char* p2;
  char* p3;
} global_debug_data_t;
extern global_debug_data_t gdd;
void initialize_gdd();

#endif
