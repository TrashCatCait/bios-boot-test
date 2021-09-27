print_str:
    mov ah, 0x0e ;interupt for bios print
    
str_loop:
    lodsb ;load single byte into al
    cmp al, 0x00 ;check if al = 0 
    je str_end ;goto string end 
    int 0x10 ;call interupt
    jmp str_loop ;loop again 
str_end:
    ret ;return 
