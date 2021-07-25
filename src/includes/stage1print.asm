[bits 32]
print_32:
    pusha
    mov ebx, 0xb8000 
    .loop:
        lodsb
        or al,al
        jz print_32.done
        or eax, 0x1f00
        mov word [ebx], ax
        add ebx, 2
        jmp print_32.loop
    .done:
        popa 
        ret

