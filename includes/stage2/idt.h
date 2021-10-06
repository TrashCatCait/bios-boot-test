#ifndef STAGE2_IDT_H
#define STAGE2_IDT_H

#include <stage2/typedefs.h>

extern void *isr_table[]; //table of interupts defined in asm

typedef struct idt32_entry {
    uint16_t offset_low; //isr offset low 
    uint16_t kernel_cs; //kernel code selector in gdt
    uint8_t reserved;
    uint8_t type_attr; //IDT gate type 
    uint16_t offset_mid; //isr offset mid 
}__attribute__((packed)) idt32_entry_t;

typedef struct idtr32 {
    uint16_t size;
    uint32_t offset;
}__attribute__((packed)) idtr32_t; 


extern void load_idt(idtr32_t* idtDesc);
void idt_set_isr(idt32_entry_t *entry, void *isr, uint8_t flags);
void init_idt();




#endif 
