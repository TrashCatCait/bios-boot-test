[bits 16]

;
; GDT
;
gdt32_start:

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

gdt32_end:


gdt_pointer:
    dw gdt32_end - gdt32_start - 1
    dd gdt32_start

code32 equ gdt32_code - gdt32_null
data32 equ gdt32_data - gdt32_null

load_protected: 
    lgdt [gdt_pointer]
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp code32:protected_start


