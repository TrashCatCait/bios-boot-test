#ifndef STAGE2_IO_H
#define STAGE2_IO_H 

#include <stage2/typedefs.h>

/* 
 * These functions prototypes are here but they 
 * are defined in io.asm in the src code folder
 */

extern void out_byte(uint16_t port, uint8_t val);
extern uint8_t in_byte(uint16_t port);
extern void kernel_hang();
extern void wait_io();

#endif 

