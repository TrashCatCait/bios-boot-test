#ifndef STAGE2_FRAMEBUFFER_H
#define STAGE2_FRAMEBUFFER_H
#include <stage2/typedefs.h>

void setup_bfr(framebuffer_t *fb);
void set_colors(uint8_t fg, uint8_t bg);
void clear_scr();
void draw_vline(uint32_t x);
void draw_hline(uint32_t y);
void draw_rect(uint32_t sx, uint32_t ex, uint32_t sy, uint32_t ey);
void putpixel(uint32_t x, uint32_t y, uint8_t color);
void load_font(memptr_t *bi);
void draw_str8x16(char *string, uint32_t x, uint32_t y);
void draw_char8x16(char c, uint32_t x, uint32_t y); 


#endif

