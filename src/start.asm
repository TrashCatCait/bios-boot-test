org 0x7C00 ;Load program here    
bits 16 ;define 16 bit code

section .text: 
    global _start: ;define _start global so the linker can see it and use it.

_start: ;start execution here 

hltloop:
    hlt
    jmp hltloop

;Data
;times 510-($-$$) db 0x00

db 0xAA, 0x55
