[bits 64]

;
; 64 bit GUI functions 
;

;RDI = offset pixel to set in linear buffer 
;al = color to set it to
put_pixel64:
    mov byte[0xa0000+rdi],al 
    ret

; INPUTS
; al = color to draw 
; rcx = width of res 
; rdi = offset 
draw64_vline:
    call put_pixel64 
    add rdi,rcx 
    cmp rdi,64000
    jnge draw64_vline 
    ret 

; INPUTS
; al = color to set 
; rdx = width 
; rdi = offset 
draw64_hline:
    call put_pixel64 
    add rdi,0x01 
    cmp rdi,rdx 
    jnge draw64_hline
    ret 

; INPUTS
; al = color code 
; rdi = offset to clear from 
clear_scr64:
    mov al, [guibg]
    call put_pixel64
    add rdi, 0x01
    cmp rdi, 64000 
    jnge clear_scr64 
    ret 

; INPUTS
; RDI=offset to print to 
; 320*15 to skip character rows
; rsi = string to read
print_gui64:
    .char_loop:
    add byte[cur_char],1 ;add one to the cur char counter
    mov al,byte[cur_char] ;mov it into al 
    cmp al,41 ;compair to 41
    jge .next_row ;if greater than equal next rwo 
    jmp .next_row_ret ;else goto .next_row_ret 

    .next_row:
    add rdi,320*15 ;move to next row of chars
    mov byte[cur_char],0x00 ;set cur char to 0 

    .next_row_ret:
    xor rax,rax ;clear out rax register
    lodsb ;load single byte into al 
    cmp al, 0x00 ;check if it's null 
    je .done  ; if it's null end printing 
    mov rcx, 16 ;else move 16 into rcx 
    mul rcx ;rax = rax * rcx
    mov rbx, rax ;mov result into rbx 
    add rbx, charmap ;add charmap offset to result 
    ;ebx now points to character font for that letter
    
    push qword 16 ;push 16 to stack 

    .row_loop:
    mov rcx,8 ;mov 8 into rcx
    mov al,byte[rbx] ;move byte from [rbx] into al 
    inc rbx ;increase rbx 

    .bit_loop:
    dec rcx ;decrease rcx by one 
    bt ax,cx ;text cx bit of ax 
    jnc .next_bit ;if it's not set jump to next bit 

    .write_pixel: 
    push ax ;save ax 
    mov byte al,[guifg] ;move fg color to al 
    mov [rdi], al ;print fg color 
    pop ax ;restore ax 
    
    .next_bit: 
    add rdi, 1 ;add one byte to frambuffer pointer 
    cmp rcx, 0x00 ;check if we are on bit zero 
    jnz .bit_loop ;if it's not begin again 

    pop rcx ;restore counter from stack 
    dec rcx ;decrease rcx by one 
    jz .next_char_setup ;if zero begin again 
    
    push rcx ;if not save rcx onto stack again 
    add rdi,320 ;go down a row 
    sub rdi,8 ;take away one char width 
    jmp .row_loop

    .next_char_setup:
    sub edi,320 * 15 ;set up to print next char by returning to first scan line 
    jmp .char_loop

    .done: 
    retq
