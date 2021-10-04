#ifndef STAGE2_IO_H
#define STAGE2_IO_H 

#include <stage2/typedefs.h>

/* 
 * These functions prototypes are here but they 
 * are defined in io.asm in the src code folder
 */

extern void out_byte(uint16_t port, uint8_t data);
extern void out_word(uint16_t port, uint16_t data);
extern void out_dword(uint16_t port, uint32_t data);

extern uint8_t in_byte(uint16_t port);
extern uint16_t in_word(uint16_t port);
extern uint32_t in_dword(uint32_t port);

extern void hlt_c();
extern void clear_interupts();
extern void set_interupts();
extern void wait_io();

extern void kernel_hang();

#endif 

