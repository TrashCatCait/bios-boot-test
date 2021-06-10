org 0x7C00 ;Load program here    
bits 16 ;define 16 bit code

section .text: 
    global _start: ;define _start global so the linker can see it and use it.

_start: ;start execution here 
    mov bp, 0x7c00 
    mov bp, sp ;set up stack base and pointer
    
    mov si, msg
    call printr
    jmp hltloop


printr:
    pusha
    mov ah, 0x0e
    
    .str_loop:
        lodsb ;load single byte from si into al
        cmp al, 0x00
        je printr.done ;if null term char found end
        int 0x10 ;call interupt
        jmp printr.str_loop ;loop to next char

    .done:
        popa
        ret

; This is where we land if an error occurs. We disable interupts, htl the processor then if a NMI interupt occurs a interupt we can't stop we go back to hltloop to ensure we don't continue execution
hltloop:
    cli
    hlt
    jmp hltloop

;Data
msg: db "Hello World!", 0x00

times 510-($-$$) db 0x00


db 0x55, 0xaa
