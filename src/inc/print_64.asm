;;
;	64bit print function
;	Inputs rsi is set to the strings memory location
;	returns nothing
;;
print_lm:
    push rbx
    mov ebx, 0xb8000
	
    .loop:
        lodsb
	mov ah, 0x1f 

	cmp al, 0x00
	je print_lm.done

	mov [ebx], ax

	add ebx, 2
	
	call set_cur

	jmp print_lm.loop

    .done:
	pop rbx
	ret

;
; Set the cursor location
;
set_cur:
    ;mov cursor
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
