#include <stage2/typedefs.h>

void stage2_start(framebuffer_t * frmbfr, memptr_t *memory) {
    //basic just clear the screen to blue
    unsigned char *vram = (unsigned char*) frmbfr->buffer_base;
    while(1) {
        for(int i = 0; i<frmbfr->size; i++)
        {
            vram[i] = 0x01;
        }
        asm("hlt");
    }
}
