/******************************************************************
 * time_branches.c
 *
 * Time loops containing various branch patterns.
 *
 * (C) 2016 Zachary Kurmas
 ******************************************************************/

#include "icos.h"
#include "ic_util.h"
#include "vga_text.h"
#include "data_buffer.h"

// The length of the branch pattern. 
// This program can use at most 64K of stack space.)
// We choose 4096 because it produces more consistent results.
// I suspect we need a size < L1 cache size
#define SIZE (4096)

static const int WARM_UP = 0; // Number of "warm up" iterations
static const int ITERS = 5000;  // The number of sample measurements taken

typedef enum {
  ALWAYS, NEVER, RANDOM
} pattern_type;

vga_text_section_t debug;

///////////////////////////////////////////////////////////////////
//
// Time a loop containing the given branch pattern
//
///////////////////////////////////////////////////////////////////
static unsigned long time_branch(char pattern[], int pattern_length) {
  
  // Intel CPUs count the cycles as they go by.
  // rdtsc() returns the "number" of the current cycle.
  unsigned long start = ic_rdtsc(); 

  // We need to give the if/else statement something "useful"
  // to do so that the compiler doesn't optimize the branch away.
  // Make sure both the "if" and "else" parts of the code 
  // take the same number of cycles.
  long sum = 433;
  for (int i = 0; i < pattern_length; i++) {
    if (pattern[i]) {
      sum *= 5910;
      sum += 17;
    } else {
      sum *= 4317;
      sum += 19;
    }
  }
  uint32_t end = ic_rdtsc();

  // Returns the # of cycles elapsed since the first call to rdtsc()
  // The counter may wrap around during the test; but, fortunately,
  // the math works out such that the difference is still the elapsed
  // time.
  return end - start; 
} // end time_branch



///////////////////////////////////////////////////////////////////
//
// Repeat time_branches ITERS times and report the results
//
/////////////////////////////////////////////////////////////////

static void repeat_measurements (pattern_type pattern_id, 
				 vga_text_section_t* head, 
				 vga_text_section_t* body) {

  // TODO: Set up an array to hold the branch pattern.
  // (Notice that we aren't timing this part.)
  char pattern[SIZE];
  //ifelse(`  Remove this from "starter" code
  for (int j = 0; j < SIZE; j++) {
    char value = ic_random() % 2;
    switch (pattern_id) {
    case ALWAYS: pattern[j] = 0; break;
    case NEVER: pattern[j] = 1; break;
    case RANDOM: pattern[j] = value; break;
    }
  } // end j      
  //')dnl end starter code removal


  // TODO: "Warm up" the branch table ifelse(` Remove this from "starter" code
  for (int i = 0; i < WARM_UP; i++) {
    time_branch(pattern, SIZE);
  }
  //end starter code removal ')

  // Repeatedly time the loop and keep statistics

  unsigned long sum = 0;
  unsigned long sum_sq = 0;
  unsigned long max = 0;
  unsigned long min = (unsigned long) -1;
  unsigned long variance = 0;
  for (int i = 1; i <= ITERS; i++) {

    // Generate a data piont
    unsigned long value = time_branch(pattern, SIZE);

    // Do the "recordkeeping" (update sum, min, max, etc.) ifelse('
    sum += value;
    sum_sq += value*value;
    if (value > max) {
      max = value;
    }
    if (value < min) {
      min = value;
    }
    // Take care not to divide by 0 if i < 2
    variance = i>=2 ? (i*sum_sq - sum*sum)/(i*(i-1)) : 0;
    //end starter code removal ')


    // Put the last line of output in the head
    vga_text_section_t* output = (i == ITERS) ? head : body;

    vgat_write_unsigned(output, i, ": cur=");
    vgat_write_unsigned(output, value, ", avg=");
    vgat_write_unsigned(output, (sum/i), ", min=");
    vgat_write_unsigned(output, min, ", max=");
    vgat_write_unsigned(output, max, ", var=");
    vgat_write_unsigned(output, variance, "\n");

    data_write_unsigned( i, ": cur=");
    data_write_unsigned( value, ", avg=");
    data_write_unsigned( (sum/i), ", min=");
    data_write_unsigned( min, ", max=");
    data_write_unsigned( max, ", var=");
    data_write_unsigned( variance, ";\n ");

  } // end for
} // end time_many_branches
  


/////////////////////////////////////////////////////////////////
//
// This is the entry point for ICOS
//
///////////////////////////////////////////////////////////////////
void time_branches() {
  ic_randomize(0);

  vga_text_section_t head, body;
  vgat_initialize_head_body(&head, &body, 5);
  
  vgat_write_string(&head, "Branch Timing:\n");
  vgat_write_string(&body, "Data Section:\n");

  vgat_write_string(&head, "Always: ");
  repeat_measurements(ALWAYS, &head, &body);

  vgat_write_string(&head, " Never: ");
  repeat_measurements(NEVER, &head, &body);

  vgat_write_string(&head, "Random: ");
  repeat_measurements(RANDOM, &head, &body);
  
}

