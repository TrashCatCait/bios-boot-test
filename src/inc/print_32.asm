;;
;	Input: esi set to the string memory location
;	Return: Nothing
;;
[bits 32]
print_pm:
    pushad
    mov ebx, 0xb8000

    .loop:
	lodsb
	mov ah, 0x3f

	cmp al, 0 
	je print_pm.exit
	
	mov [ebx],ax


	add ebx, 2 ;next char index

	jmp print_pm.loop
    
    .exit:
	popad
	ret
