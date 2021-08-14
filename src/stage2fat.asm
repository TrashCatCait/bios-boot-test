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
    
%include './inc/a20.asm'
%include './inc/gdt32.asm'
%include './inc/print.asm'

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
%include './inc/print_32.asm'

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
    
    mov rdi, 0x1000
    xor rax, rax 
    mov cx, 0x01 
    mov bl, 00000000b

    call ata_read_lba
    
    mov dx, 0x01f1
    in ax, dx
    
    ;;Tried this and the error bit doesn't seem to be set.
    test ax, 0
    jz no_err

    err:
    jmp hltloop 
    no_err:

    ;Print Register Label
    mov rsi, reg1
    mov rbx, 0xb8000
    call print_lm

    ;Print Register Value
    xor rax,rax 
    mov ax, word[0x1ffe]
    mov rdi,rax

    mov rsi,0xb8008
    call print_reg
    
    ;Print Register Label
    mov rbx, rsi 
    add rbx, 2
    mov rsi, reg2
    
    call print_lm
    
    mov rsi,rbx
    xor rbx,rbx
    mov bx, word[0x07fe]
    mov rdi, rbx

    call print_reg

    jmp hltloop

%include './inc/print_64.asm'
%include './inc/ata_read64.asm'

print_reg:
    
    xor rax,rax
    mov ecx,16
    lea rdx, [hex_ascii]

    .loop:
	rol rdi, 4 
	mov al, dil
	and al, 0x0f
	mov al, byte[hex_ascii+rax]
	
	mov [rsi], al
	add rsi, 2 
	dec ecx
	jnz .loop

    .exit:
	ret

hltloop:
    hlt
    jmp hltloop


;
;Data
;
reg1: db "RAX:", 0x00 
reg2: db "RBX:", 0x00
readdone: db "Reading finished no error bits set", 0x00
a20error: db "Error Enabling A20 Line", 0x00 
longerror: db "No Long mode support detected", 0x00 
cpuiderr: db "Error checking CPU", 0x00
hex_ascii: db "0123456789abcdef", 0x00

times 1022-($-$$) db 0x00
SIGNATURE: db 0x55, 0xaa ;This is here as sort of signature
