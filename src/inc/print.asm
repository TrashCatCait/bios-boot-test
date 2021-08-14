;;
;
;	Input: set the si register to the strings location before calling
;	Return: None
;
;;
[bits 16]
print: 
    mov ah,0x0e

    .loop:
	lodsb
	cmp al, 0x00 
	je print.done 
	int 0x10 
	jmp print.loop

    .done:
	ret


