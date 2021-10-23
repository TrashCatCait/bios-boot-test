#ifndef STAGE2_VA_LIST_H
#define STAGE2_VA_LIST_H

typedef __builtin_va_list va_list;

#define va_start(list, start) __builtin_va_start(list, start)
#define va_end(list) __builtin_va_end(list) 
#define va_arg(list, type) __builtin_va_arg(list, type)
#define va_copy(dest, src) __builtin_va_copy(dest, src)

#endif 


