;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   BIOS MBR sector 0.                               ;
;   1) Job read Partition table on the disk          ;
;   2) Find bootable partitions (if any exist)       ;
;   3) Display all valid bootable partitions         ;
;   4) Allow the users to pick one.                  ;
;   5√a) boot to the selected disk                   ;
;   6√a) if an error occurs while boot goto root 5√b ;
;   5√b) If read error occurs inform the user.       ;
;   This project is simply a chain loader it does    ;
;   nothing to ensure A20, GDT or anything else is   ;
;   set up it assumes the bootloader will do that    ;
;   The purpose of this is to allow multiboot on MBR ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 16]
[org 0x7c00]


; $$ - section start = org 0x7c00
; $ - current pos
; ($ - $$)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Definations        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR code         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
    jmp after_bpb
    nop

    ;So according the Limine bootloader comments
    ;Some bioses will overwrite the section where the fat BPB would be.
    ;Potentially overwriting code if code is placed here. 
    ;So we are now zeroing this out and jumping after the bpb
    ;Slighlty annoying as I need to rework this bootloader.
    ;as it previous code was to big to fit now we can't use the bpb
    ;bytes - Cait.
    times 87 db 0x00 

after_bpb:
    cli ;clear interupts while we set up segement registers
    jmp 0x0000:set_cs ;far jump to set cs setting the code segement to 0

set_cs:
    xor ax,ax ;xor out ax and set all other segement 
    mov es,ax ;registers equal to zero
    mov ss,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
    
    cld ;clear the direction flag so *i registers grow upwards
    mov sp,0x7c00 ;stack grows down from here
    sti ;renable interupts


jmp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR data         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gdt:
.start:

.null:
    dq 0 ;declear the null segement

.kercode:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10011010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high


.kerdata:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10010010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high

.end:

gdt32_pointer:
    dw gdt.end - gdt.start - 1 ;gdt size - 1 byte
    dd gdt.start ;gdt's start offset

times 510-($-$$) db 0x00
db 0x55, 0xaa
