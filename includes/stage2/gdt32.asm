[bits 16]
;
; GDT layout 
; NULL - 8 bytes, offset 0x00
; KERNEL CODE - 8 bytes offset 0x08
; KERNEL DATA - 8 bytes offset 0x10
;
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

gdtr32:
    dw gdt.end - gdt.start - 1 ;gdt size - 1 byte
    dd gdt.start ;gdt's start offset

code32 equ gdt.kercode - gdt.null ;we can now reference the code segement with code32 label
data32 equ gdt.kerdata - gdt.null ;same as above for data 

