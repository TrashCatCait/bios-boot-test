[bits 32]

checkcpuid:

	pushfd 
	pop eax

	mov ecx, eax

	xor eax, 1 << 21

	push eax
	popfd

	pushfd 
	pop eax

	push ecx 
	popfd

	xor eax,ecx
	jz nolong
	
    mov eax, 0x80000001
	cpuid
	test edx, 1 << 29
	jz nolong 
	ret

nolong:
	mov esi, longerror
    call print_32
    hlt

