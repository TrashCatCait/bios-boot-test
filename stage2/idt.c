#include <stage2/idt.h>
#include <stage2/typedefs.h>
#include <stage2/pic.h>
#include <stage2/io.h>

 
void idt_set_isr(idt32_entry_t *entry, void *isr, uint8_t flags) {
    entry->reserved = 0;
    entry->offset_low = (uint32_t)isr & 0xffff;
    entry->offset_mid = (uint32_t)isr >> 16;
    entry->kernel_cs = 0x08;
    entry->type_attr = flags;

}

void init_idt() {
    static idt32_entry_t idt[256]; //256 entries in IDT
    static idtr32_t idtDesc;

    //fill the IDT 
    for(int vectors=0; vectors <= 256; vectors++) {
        idt_set_isr(&idt[vectors], 0x0000, 0x00);
    }
    for(int vectors=0; vectors <= 33; vectors++) 
    {
	    idt_set_isr(&idt[vectors], isr_table[vectors], 0x8e);
    }

    idtDesc.size = sizeof(idt) - 1;
    idtDesc.offset = (uint32_t)&idt[0];

    remap_pic(0x20, 0x28);
    mask_pic(0xfd,0xff);
    load_idt(&idtDesc);
}

