[bits 32]

;
; GDT
;
gdt64_start:

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

gdt64_end:


gdt64_pointer:
    dw gdt64_end - gdt64_start - 1
    dq gdt64_start

code64 equ gdt64_code - gdt64_null
data64 equ gdt64_data - gdt64_null

load_long:
    cli
    lgdt [gdt64_pointer]
    jmp code64:long_start

