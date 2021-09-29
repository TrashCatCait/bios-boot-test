
typedef unsigned char uint8_t;
typedef char int8_t;

typedef unsigned short uint16_t;
typedef short int16_t;

typedef unsigned int uint32_t;
typedef int int32_t;

typedef struct {
    void *buffer_base;
    uint16_t height;
    uint16_t width;
    uint32_t size;
    uint32_t ppsl;
}__attribute__((packed))framebuffer_t;

void stage2_start(framebuffer_t * frmbfr) {
    unsigned char *vram = (unsigned char*) frmbfr->buffer_base;
    while(1) {
        for(int i = 0; i<frmbfr->size; i++)
        {
            vram[i] = 0x01;
        }
    }
}
