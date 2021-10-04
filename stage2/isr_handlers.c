#include <stage2/isr_handlers.h>
#include <stage2/framebuffer.h>
#include <stage2/pic.h>
#include <stage2/io.h>

void exception_handler(uint8_t irq){
    set_colors(0x0f, 0x04);
    clear_scr();
    draw_str8x16("Exception Occurred: ", 0, 0);
    kernel_hang();
}

void isr32_handler(){
    out_byte(0x20, 0x20);
    out_byte(0xa0, 0x20);
}
void isr33_handler(){
    uint8_t scancode = in_byte(0x60);

    out_byte(0x20, 0x20);
    out_byte(0xa0, 0x20);

}