[bits 32]

;
; GUI printing functions 
;

print_gui32:
    .char_loop:
    add byte[cur_char], 1 ;add one to char count
    mov al, [cur_char] ;mov char count into al 
    cmp al,41 ; if it's 41 or greater 
    jge .next_row ;move to the next row
    jmp .next_row_ret ;else continue printing  

    .next_row:
    add edi, 320 * 15 ;move down one row of characters 
    mov byte[cur_char], 0x00 ;move zero into cur char 
    
    .next_row_ret:
    xor eax,eax ;xor out eax 
    lodsb ;load single byte from [esi] to al
    cmp al, 0x00 ;check if it's null 
    je .done  ; if it's null end printing 
    mov ecx, 16 ;else move 16 into ecx 
    mul ecx ;eax = eax * ecx
    mov ebx, eax ;mov result into ebx 
    add ebx, charmap ;add charmap offset to result 
    ;ebx now points to character font for that letter
    
    push dword 16 ;push 16 to stack as thats the character height

    .row_loop:
    mov ecx,8 ;move 8 into ecx as that's the char width 
    mov al,byte[ebx] ;mov char byte row into al 
    inc ebx ;increment ebx

    .bit_loop:
    dec ecx ;decrement ecx 
    bt ax,cx ;test cx bit of ax register 
    jnc .next_bit ;if it's not jump to the next bit 

    .write_pixel:
    push ax ;save ax 
    mov byte al, [guifg] ;move foreground color into al 
    mov [edi], al ;print foreground color 
    pop ax ;pop the original ax value 

    .next_bit:
    add edi, 1 ;add one byte to edi to move to next pixel 
    cmp ecx, 0x00 ;check if we on bit zero 
    jnz .bit_loop ;if it's not begin again 

    pop ecx ;pop current character row off the stack  
    dec ecx ;dec ecx by one 
    jz .next_char_setup ;if zero begin again 
    push ecx ;if not push it back on the stack 
    add edi,320 ;jmp back
    sub edi,8 ;take away one characters width 
    jmp .row_loop ;go back to row loop
    
    .next_char_setup:
    sub edi,320 * 15 ;set back to top scan line for printing next char 
    jmp .char_loop ;jmp back to char loop 

    .done: 
    ret 

;fg and bg color set here so we don't have to set a register when calling 
;printing functions 
guibg: db 0x00 
guifg: db 0x0f
cur_char: db 0x00

