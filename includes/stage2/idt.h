#ifndef STAGE2_IDT_H
#define STAGE2_IDT_H

#include <stage2/typedefs.h>

extern void *isr_table[]; //table of interupts defined in asm

typedef struct idt64_entry {
    uint16_t offset_low; //isr offset low 
    uint16_t kernel_cs; //kernel code selector in gdt
    uint8_t ist; //ist in the TSS no used yet 
    uint8_t type_attr; //IDT gate type 
    uint16_t offset_mid; //isr offset mid 
    uint32_t offset_high; //isr offset high
    uint32_t reserved; //always zero 
}__attribute__((packed)) idt64_entry_t;

typedef struct idtr64 {
    uint16_t size;
    uint64_t offset;
}__attribute__((packed)) idtr64_t; 


extern void load_idt(idtr64_t* idtDesc);
void idt_set_isr(idt64_entry_t *entry, void *isr, uint8_t flags);
void init_idt();




#endif 
