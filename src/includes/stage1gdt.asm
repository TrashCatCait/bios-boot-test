[bits 16]
;;Very simple gdt to get to 
gdt_start:
gdt_null:
    dq 0
gdt_code:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10011010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high

gdt_data:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10010010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high
gdt_end:

gdt_pointer:
    dw gdt_end - gdt_null - 1
    dd gdt_start

codeseg equ gdt_code - gdt_null
dataseg equ gdt_data - gdt_null

toprotected:
    lgdt [gdt_pointer]
    mov eax, cr0 
    or eax, 1
    mov cr0, eax
    jmp codeseg:protectedmode

