[bits 32]

;;;;;;;;;;;;;;
; 64-bit GDT ;
;;;;;;;;;;;;;;
;
; This is a very basic GDT if you plan to rework this bootloader for your own kernel.
; Please make sure your kernel loads a more relevant to your kernels set up or you 
; replace the GDT here with a different one that you want for your kernel 
;
; NOTE: I don't reccomend the second option as the bootloader should be as independant
; from the OS as possible in my personal opinion.
;

gdt64_start: ;Label to start memory address

gdt64_null: 
    dq 0x0 ;Null = 8 bytes of zero

gdt64_code:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10011010b ;access byte 
    db 10101111b ;flags + limit high
    db 0x00 ;base high

gdt64_data:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10010010b ;access byte 
    db 10101111b ;flags + limit high
    db 0x00 ;base high

gdt64_end: ;Label to then end memory address


gdt64_pointer: ;Pointer to the GDT 
    dw gdt64_end - gdt64_start - 1 ;Size of the GDT - 1 
    dq gdt64_start ;GDT offset 64 bit datatype 

code64 equ gdt64_code - gdt64_null ;can reference code segement with code64
data64 equ gdt64_data - gdt64_null ;same as above 

