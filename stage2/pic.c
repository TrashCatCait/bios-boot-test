#include <stage2/io.h>
#include <stage2/pic.h> 

//at the moment we only use a PIC for interupts but I plan to add support IOAPIC and APIC in time.
void remap_pic(uint8_t moffset, uint8_t soffset) {
    out_byte(PIC1_COM, 0x11);
    wait_io();

    out_byte(PIC2_COM, 0x11);
    wait_io();

    out_byte(PIC1_DATA,moffset);
    wait_io();

    out_byte(PIC2_DATA,soffset);
    wait_io();

    out_byte(PIC1_DATA,0x04);
    wait_io();

    out_byte(PIC2_DATA,0x02);
    wait_io();

    out_byte(PIC1_DATA,0x01);
    wait_io();

    out_byte(PIC2_DATA,0x01);
    wait_io();
}

//function to disable and enable
//PIC interupts
void mask_pic(uint8_t mmask, uint8_t smask) {
    out_byte(PIC1_DATA,mmask);
    wait_io();

    out_byte(PIC2_DATA,smask);
    wait_io();
}


