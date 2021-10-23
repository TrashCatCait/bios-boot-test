#include <stage2/isr_handlers.h>
#include <stage2/framebuffer.h>
#include <stage2/pic.h>
#include <stage2/io.h>

void exception_handler(uint32_t exception, uint32_t error_code, uint32_t ebp, uint32_t eip){
    set_colors(0x0f, 0x04);
    clear_scr();
    draw_str8x16("Kernel Panic Exception:", 0, 0);
    kernel_hang();
}

void isr32_handler(){
    out_byte(0x20, 0x20);
    wait_io();
    out_byte(0xa0, 0x20);
    wait_io();
}


void isr33_handler(){
    uint8_t scancode = in_byte(0x60);

    out_byte(0x20, 0x20);
    wait_io();
    out_byte(0xa0, 0x20);
    wait_io();

}

