[bits 64]

%define PIC1 0x20 ;Master Pic
%define PIC2 0xa0 ;Slave Pic 
%define PIC1_Com PIC1 
%define PIC2_Com PIC2
%define PIC1_Data PIC1+1
%define PIC2_Data PIC2+1

remap_pic:
    mov al, 0x11 
    out PIC1_Com, al
    out PIC2_Com, al

    mov al, 0x20
    out PIC1_Data, al
    mov al,0x28
    out PIC2_Data, al
    
    mov al, 0x04 
    out PIC1_Data, al
    mov al, 0x02
    out PIC2_Data, al
    
    mov al, 0x01 
    out PIC1_Data, al
    out PIC2_Data, al
    
    mov al,0xff
    out PIC2_Data, al
    mov al,0xfd
    out PIC1_Data, al

    ret
