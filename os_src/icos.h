#ifndef ISEE_H
#define ISEE_H

#include <stddef.h>
#include <stdint.h>

#if DEBUG
#include <stdio.h>
#include <stdlib.h>
#endif


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



#endif // ISEE_H
