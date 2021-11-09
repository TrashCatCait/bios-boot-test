#include "stage2/framebuffer.h"
#include "stage2/idt.h"
#include <stage2/typedefs.h>


void cmain(framebuffer_t *framebfr, memptr_t *memory) {
    setup_bfr(framebfr);
    set_colors(0x0f, 0x01);
    clear_scr();
    init_idt();
    draw_str8x16("Hello World!", 0, 0);
    while(1){
     
    }
}
