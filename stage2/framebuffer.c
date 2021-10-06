#include <stage2/framebuffer.h>
#include <stage2/typedefs.h>

static uint8_t *buffer_base;
static uint32_t size; 
static uint32_t width;
static uint32_t height;
static uint32_t ppsl;
static uint8_t *font;
static uint8_t fg_color;
static uint8_t bg_color;

void setup_bfr(framebuffer_t *fb) {
    buffer_base = fb->buffer_base;
    size = fb->size;
    width = fb->width;
    height = fb->height;
    ppsl = fb->ppsl;
    font =(uint8_t*) fb->fontmap;
}

void set_colors(uint8_t fg, uint8_t bg){
        fg_color = fg;
        bg_color = bg;
}

void clear_scr() {
    for(uint32_t index = 0; index < size; index++) {
	    buffer_base[index] = bg_color;
    }
}


void draw_vline(uint32_t x) {
    for(int i = 0; i < size; i += 320) {
	    buffer_base[i+x] = fg_color;
    }
}

void draw_hline(uint32_t y) {
    for(int i = 0; i < width; i++) {
	    buffer_base[i+(y*width)] = fg_color;
    }
}

void draw_rect(uint32_t sx, uint32_t ex, uint32_t sy, uint32_t ey){
    draw_hline(sy);
    draw_hline(ey);
    draw_vline(sx);
    draw_vline(ex);
}

void putpixel(uint32_t x, uint32_t y, uint8_t color) {
    buffer_base[x+y*width] = color;
}

void draw_char8x16(char c, uint32_t x, uint32_t y) {
    uint32_t cx,cy;
    static const int bitmask[8] = {128,64,32,16,8,4,2,1}; //masks for checking if bits set 
    uint8_t *glyph = font+(int)c*16;

    for(cy = 0; cy < 16; cy++) {
        for(cx = 0; cx < 8; cx++) {
            putpixel(x+cx, y+cy, glyph[cy]&bitmask[cx]?fg_color:bg_color);
        }
    }
}

void draw_str8x16(char *string, uint32_t x, uint32_t y) {
    while(*string != 0) {
	draw_char8x16(*string, x, y);
	x += 8;
	if(x >= width) {
	    x = 0;
	    y += 16;
	}
	string++;
    }
}


