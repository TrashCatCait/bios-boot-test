[bits 16]
%define map_ptr 0x2000
%define charmap 0x1000
;16bit x86 code plan is we start he do VBE to try and initlize actually colors not just a color pallet and a decent size screen. (this will obvisually be relative the monitor but anything is better than 320x200 tbh)
section .text
global _start

_start:
    xor ax,ax
    mov ds,ax
    ;mov ss,ax ;wait no this will mess the stack up. stack is still at 0x7c00
    mov fs,ax
    mov es,ax
    mov gs,ax ;use gs to refer to things in segement 0 

rip_vga_fonts: 
    push ds ;save original ds 
    push es ;save es = 0 onto stack
    mov bh, 0x06 ;offset pointer to get VGA fonts
    mov ax, 0x1130 ;bios VGA font interupt 
    int 0x10 ;call interupt 
    push es ;save segement of video font 
    pop ds ;ds = segement of video font 
    pop es ;restore es to zero 
    mov si,bp ;move offset of segement into si
    mov di,charmap ;move destination index here
    mov	cx,256*16/4 ;number of times to copy
    rep movsd ;move all fonts from ds:si to es:di
    pop ds ;restore ds 
 
    mov ax, 0x0013
    int 0x10 ;we'll try setting up Vesa later.
    call get_memmap
    call enableA20
    call setup_vesa

load_gdt:
    cli
    lgdt [gdtr32]
    mov eax,cr0
    or eax,1
    mov cr0,eax
    jmp 0x08:init_pm

hltloop:
    cli 
    hlt
    jmp hltloop    

%include './stage2/a20.asm'
%include './stage2/e820.asm'
%include './stage1/print16.asm'
%include './stage2/vbe.asm'
;
; 16 bit data 
;
section .data
%include './stage2/gdt32.asm'

section .text
[bits 32]
extern cmain

init_pm:
    ;seem to have enabled themselves when I jump up mode it's very strange
    mov ax,0x10
    mov es,ax
    mov ds,ax
    mov gs,ax
    mov ss,ax
    mov fs,ax
    mov esp,0x90000
    
    

    push mmap_struc
    push frmbfr
    call cmain

endless:
    cli
    hlt 
    jmp endless

frmbfr:
    dd 0xa0000 ;default buffer base for VGA but this may be swapped out through VESA or some other mode 
    dw 200 ;default 320x200 mode height 
    dw 320 ;default 
    dd (320*200)*1 ;size of buffer = height * width * bytes per pixel
    dw 320
    dd charmap 
     
mmap_struc:
    dw 0x00 ;number for type of memory map used
    dd map_ptr ;pointer to where data is stored.
    ;It'll be up to the kenrel to actually choose how to parse the different kinds of maps either e820 or e801
