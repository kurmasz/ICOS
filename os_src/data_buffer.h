#ifndef IC_DATA_BUFFER_H
#define IC_DATA_BUFFER_H

#include "icos.h"


void data_initialize();

void data_putchar(char c);
void data_write_string(const char* string);
void data_write_unsigned(unsigned long  value, const char* data);
void data_write_unsigned_hex(unsigned long value, const char* data);
void data_write_signed(signed long value, const char* data);

unsigned data_size();
int data_buffer_is_full();

#endif 
