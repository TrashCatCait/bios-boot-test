[bits 16]

;;;;;;;;;;;;;;
; 32 bit GDT ;
;;;;;;;;;;;;;;
;
; This is a very basic GDT if you plan to rework this bootloader for your own kernel.
; Please make sure your kernel loads a more relevant to your kernels set up or you 
; replace the GDT here with a different one that you want for your kernel 
;
; NOTE: I don't reccomend the second option as the bootloader should be as independant
; from the OS as possible in my personal opinion.
;

gdt32_start: ;label to the start memory offset

gdt32_null:
    dq 0x0 ;Null = 8 bytes of zero

gdt32_code:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10011010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high

gdt32_data:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10010010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high

gdt32_end: ;label to the end memory offset


gdt32_pointer:
    dw gdt32_end - gdt32_start - 1 ;GDT size - 1 byte 
    dd gdt32_start ;GDT offset location  

code32 equ gdt32_code - gdt32_null ;we can now reference the code segement with code32 label
data32 equ gdt32_data - gdt32_null ;same as above for data 

load_protected: 
    lgdt [gdt32_pointer] ;load the pointer to the GDT into the GDT register
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp code32:protected_start ;perform far jump to protected mode code


