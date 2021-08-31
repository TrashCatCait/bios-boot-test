[bits 64]
;
;Keyboard interupt handler to print key press to the VGA memory buffer
;
keyboard_main_handler:
    in al, 0x64 ;read in byte from keyboard status register
    test al, 0x01 ;test if buffer full bit is set 
    jz .skip_printing ;if not set don't proced 
    test al, 0x20 ;keyboard locked bit set 
    jnz .skip_printing ;if it is don't proced

    in al,0x60 ;read in scan code 
    push rax ;save scan code 
    and al, 0x80 ;and the 8 bit as this should only be set on released characters 
    cmp al, 0x80 ;check if the scan code now = 80 
    pop rax ;restore code 
    je .skip_printing 
    
    .keyboard_print:
    push rbx ;save video memory location
    xor rbx,rbx ;clean out high bytes of rbx
    mov bl,al ;mov scan code into bl
    mov al, [keyset1+rbx] ;look up the ascii value in the scan code table 
    pop rbx ;restore video memory 
    
    cmp al,0x0e
    je .backspace   
    
    cmp al,0x1c
    je .newline

    cmp al,0x00 ;check if the key is speacial key ctrl, alt, tab, etc...
    jne .print ;if it is don't print it 
    jmp .skip_printing
    
    .newline:
    add dword[current_buffer],0xa0 
    mov ebx,dword[current_buffer]
    cmp ebx,0xb8fa0
    jge .handle_overflow
    
    jmp .skip_printing

    .backspace:
    mov ebx,dword[current_buffer]
    cmp ebx,0xb8000
    je .skip_printing
    sub dword[current_buffer],2
    sub ebx,2
    mov byte[rbx], ' '
    jmp .skip_printing

    .print:
    mov ebx,dword[current_buffer]
    cmp ebx,0xb8fa0
    jge .handle_overflow
    mov byte[ebx],al ;mov character into video memory if it's not special char 
    add dword[current_buffer],2 ;add 2 to the video memory value 
     
    .skip_printing:
    ret

.handle_overflow:
    mov dword[current_buffer],0xb8fa0 ;set buffer to the maximum
    jmp .skip_printing



keyset1: db 0x00,0x00,'1234567890-=',0x0e,0x00,'qwertyuiop[]',0x1c,0x00,"asdfghjkl;'`",0x00,'\zxcvbnm,./',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,'789-456+1230.',0x00,0x00,0x00,0x00,0x00,0x00

shiftset1: db 0x00,0x00,'1234567890-=',0x0e,0x00,'qwertyuiop[]',0x00,0x00,"asdfghjkl;'`",0x00,'\zxcvbnm,./',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,'789-456+1230.',0x00,0x00,0x00,0x00,0x00,0x00

current_buffer: dd 0x000b8000
