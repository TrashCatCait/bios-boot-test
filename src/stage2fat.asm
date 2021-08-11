;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   FAT STAGE 2 BOOT CODE:                           ;
;   1) Get to 32 bit mode
;   2) Check if long mode is supported
;   3a) if not check kernel is 32bit compatiable
;   4a) if not error else load kernel
;   3b) Set up paging 
;   4) Load new gdt
;   5) to long mode 
;   4) Load kernel executeable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[org 0x8000]
[bits 16]


stage2_start:
    cli 
    
    ;;Stack below stage 1
    mov bp, 0x7c00
    mov sp, bp
     
    push dx ;save dl
    
    sti
    
    call enableA20
    jmp load_protected
    jmp $
    

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

%include './inc/a20.asm'
%include './inc/gdt32.asm'

[bits 32]

protected_start:
    mov ax, data32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ;stack here so it grows away from VGA video memory 
    mov esp, ebp
    
    call checkcpuid
    call enable_paging
    jmp load_long
    jmp hltloop

%include './inc/cpuid.asm'
%include './inc/gdt64.asm'
%include './inc/paging.asm'

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

[bits 64]
long_start:
    mov ax, data64
    mov ds, ax
    mov es, ax 
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov rbp, 0x90000
    mov rsp, rbp

    mov edi, 0xB8000              ; Set the destination index to 0xB8000.
    mov rax, 0x1F201F201F201F20   ; Set the A-register to 0x1F201F201F201F20.
    mov ecx, 500                  ; Set the C-register to 500.
    rep stosq                     ; Clear the screen.
    
    mov rsi, longinit
    call print_lm

    jmp hltloop

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


hltloop:
    hlt
    jmp hltloop


;
;Data
;
longinit: db "Long Mode Started... Next goal load a kernel", 0x00
a20error: db "Error Enabling A20 Line", 0x00 
longerror: db "No Long mode support detected", 0x00 
cpuiderr: db "Error checking CPU", 0x00

db 0x55, 0xaa
