#include "stage2/idt.h"
#include <stage2/typedefs.h>
#include <stage2/framebuffer.h>

void stage2_start(framebuffer_t *framebfr, memptr_t *memory) {
    //basic just clear the screen to blue
    set_colors(0x0f, 0x01);
    setup_bfr(framebfr);
    init_idt();
    clear_scr();
    draw_str8x16("Hello", 0, 0);
    while(1) {
        asm("hlt");
    }
}
