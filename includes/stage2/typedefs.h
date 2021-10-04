#ifndef STAGE2_TYPE_DEFS_H
#define STAGE2_TYPE_DEFS_H 

typedef unsigned char uint8_t;
typedef char int8_t;

typedef unsigned short uint16_t;
typedef short int16_t;

typedef unsigned int uint32_t;
typedef int int32_t;

typedef unsigned long long uint64_t;
typedef long long int64_t;
typedef uint64_t size_t;

typedef enum {
    VA_8bit_color, //Note this is pallet color regular 256 color https://www.fountainware.com/EXPL/vgapalette.png
} pixel_formats;

typedef struct {
    void *buffer_base; //base address of video pixel buffer 
    uint16_t height; //height of resolution 
    uint16_t width; //width of resolution 
    uint32_t size; //size of the buffer in bytes 
    uint16_t ppsl; // pixels per scan line
    pixel_formats color_depth;
    void *fontmap;
}__attribute__((packed))framebuffer_t;

typedef struct {
    uint16_t entry_count; //number of entries
    uint8_t entry_size; //Size of each entry 
    char mapsig[4]; //type of memory map used hard coded to e820 but left open for expansion
    void *bufferbase; //base address of where entries are 
}__attribute__((packed))memptr_t;


#endif 
