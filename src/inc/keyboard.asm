[bits 64]
;
;Keyboard interrupt handler to print key press to the VGA memory buffer
;
keyboard_main_handler:
    ;clear out the registers 
    xor rax,rax
    xor rbx,rbx
    xor rdx,rdx
    xor rcx,rcx 

    in al,0x64 ;read in byte from keyboard status register
    test al,0x01 ;test if buffer full bit set
    jz .skip_printing ;if not set don't proceed

    in al,0x60 ;read in scan code from buffer
    test al,0x80 ;check if the 8th bit is set in the scan code 
    jnz .skip_printing ;if it is skip printing 

    cmp al,0x0e ;if backspace is pressed 
    jz .backspace ;go here
    
    cmp al,0x1c ;if enter is pressed
    jz .newline ;print new line 

    .continue_print:
    mov bl,al ;move al into bl too search the buffer with 
    mov al,[keyset1+rbx] ;load ascii char into al 

    cmp al,0x00 ;check if the key is speacial key ctrl, alt, tab, etc...
    jne .print ;if it is don't print it 
    jmp .skip_printing 
    
    .newline:
    add dword[current_buffer],0xa0;new line 
    mov eax,dword[current_buffer] ;mov current VGA mem location into eax
    push rax ;save unmodified rax saved 10 bytes by this :)

    sub ax,0x8000 ;sub 0x8000 from ax
    mov cx,0xa0 ;mov 0xa0 into cx
    div cx ;divide ax by cx 
    sub dword[current_buffer],edx ;take the remainder or modulo from buffer
    
    pop rax ;restore rax
    cmp eax,0xb8fa0 ;compair video memory to the max possible
    jge .handle_overflow ;if equal or greater jump to overflow handler 
    jmp .skip_printing ;if not skip printing 

    .backspace:
    mov ebx,dword[current_buffer] ;move buffer into ebx
    cmp ebx,0xb8000 ;check if the buffer is at it's minimum 
    je .skip_printing ;if minimum buffer is set skip printing 
    sub dword[current_buffer],2 ;go back one space in the saved buffer 
    sub rbx,2 ;go back one memory space 
    mov byte[rbx], ' ' ;print blank space
    jmp .skip_printing ;jump to skip printing 

    .print:
    mov ebx,dword[current_buffer]
    cmp ebx,0xb8fa0 ;compair buffer to the maximum possible 
    jge .handle_overflow ;if greater than or equal goto handle overflow

    mov byte[rbx],al ;mov character into video memory if it's not special char 
    add dword[current_buffer],2 ;add 2 to the video memory value 
     
    .skip_printing:
    mov eax,dword[current_buffer] ;set eax to video memory 
    call set_cur ;set the cursor to one after the current char 
    ret ;return from keyboard controller 

.handle_overflow:
    mov dword[current_buffer],0xb8fa0 ;set buffer to the maximum
    jmp .skip_printing

;
; Set the cursor location
;
set_cur:
    ;mov cursor
    xor dx,dx ;clean dx for divide operation 
    sub ax, 0x8000 ;sub higher bytes of video memory
    mov cx,0x0002 ;mov 2 in cx 
    div cx ;divide ax by cx(2)
    mov bx,ax ;move the cursor pos into bx

    mov dx, 0x03d4 
    mov al, 0x0f
    out dx, al

    inc dl
    mov al, bl
    out dx, al
    
    dec dl
    mov al, 0x0e
    out dx, al
    
    inc dl
    mov al, bh 
    out dx, al
    ret ;return 

keyset1: db 0x00,0x00,'1234567890-=',0x00,0x00,'qwertyuiop[]',0x00,0x00,"asdfghjkl;'`",0x00,'\zxcvbnm,./',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,'789-456+1230.',0x00,0x00,0x00,0x00,0x00,0x00

current_buffer: dd 0x000b8000
