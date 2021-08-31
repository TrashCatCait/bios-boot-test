;;
;	64bit print function
;	Inputs rsi is set to the strings memory location
;	returns nothing
;;
print_lm:
	
    .loop:
        lodsb
	mov ah, 0x1f 

	cmp al, 0x00
	je print_lm.done

	mov [ebx], ax

	add ebx, 2
	

	jmp print_lm.loop

    .done:
	ret

;
; Set the cursor location
;
set_cur:
    ;mov cursor
    xor edx,edx
    sub eax,0xb8000
    mov cx,0x02
    div cx
    mov bx,ax

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
    ret

;
; 
;

print_reg:
    
    xor rax,rax
    mov ecx,16
    lea rdx, [hex_ascii]

    .loop:
	rol rdi, 4 
	mov al, dil
	and al, 0x0f
	mov al, byte[hex_ascii+rax]
	
	mov [ebx], al
	add ebx, 2 
	dec ecx
	jnz .loop

    .exit:
	ret

clear_screen:
    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
    mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
    mov ecx, 500                  ; Set the C-register to 500.
    rep stosq                     ; Clear the screen.
    ret 

