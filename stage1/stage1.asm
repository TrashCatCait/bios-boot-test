[bits 16]
[org 0x600]

%define charmap 0x1000
;
; 16-bit code
;
stage1_start:
    cli 
    xor ax,ax ;reinitlize all these to
    mov es,ax ;zero in case someone is
    mov ds,ax ;using this code from a
    mov ss,ax ;different MBR that hasn't
    mov fs,ax ;done this for us already
    mov gs,ax
    
    jmp 0x0000:init_cs ;reinitlize code seg

init_cs:
    mov sp,0x7c00 ;reinitlize the stack here
    push dx ;save bios boot disk
    
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
    mov di,0x1000 ;move destination index here
    mov	cx,256*16/4 ;number of times to copy
    rep movsd ;move all fonts from ds:si to es:di
    pop ds ;restore ds 


init_video:
    mov ax,0x0013 ;bios mode 0x13 later if I have 
    ;the space free i may use VESA for bigger res
    int 0x10 ;call interupt to set video mode

load_gdt:
    lgdt [gdtr32]
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp code32:pmode_start ;jumpt to 32bit code 


; 
; include code
;

%include './stage1/a20.asm'

;
; 16-bit Data
;

;
; include data
;
%include './stage1/gdt32.asm'


[bits 32]
;
; 32-bit code section 
;
pmode_start:
    mov ax,data32 ;load in the kernel gdt data segement 
    mov ds,ax ;set all the segement register to this value
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    
    mov byte[0xa0000],0x01
    jmp $

;
; 32-bit code includes
;


;
; 32-bit data section 
;

times 1022 - ($-$$) db 0x00
db 0x55, 0xaa
