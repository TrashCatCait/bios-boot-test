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
;Currently assumes fat table is at 0x0800
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
    
    call clear_screen

    mov rdi, 0x0a00 ;Data buffer to read into
    xor rax, rax ;LBA to read 
    mov cx, 0x0001 ;Sectors to read 
    mov bl, 00000000b ;head and drive selectors heads is not used in lba I think
    mov dx, 0x01f0
    call ata_read_lba
    mov dx, 0x01f1
    in ax, dx
    
    ;;Tried this and the error bit doesn't seem to be set.
    test ax, 0
    jz no_err

err:
    mov rsi, readerr
    call print_lm
    jmp hltloop 

no_err:
    mov bx, word[0x07fe]
    mov ax, word[0x0bfe]
    cmp ax,bx
    je equal
    jne notequal

%include './inc/print_64.asm'
%include './inc/ata_read64.asm'

equal:
    mov rbx, 0xb8000
    mov rsi, same
    call print_lm
    ;Wanted to use RDI but needed it for the future so used rsi
    ;For simplicity
    mov rsi, 0x0800 

    next_entry:
	xor rax,rax
	mov ax, word[0x0800 + 0x003a]
	call calc_lba
	mov rdi, 0x10000 ;load kernel at offset 0x10000
	mov cx, 0x0012
	mov bl, 00000000b 
	mov dx, 0x01f0
	call ata_read_lba

	xor rax,rax
	mov rax, qword[0x10000]
	mov rdi,rax
	mov ebx, 0xb8000
	call print_reg
    jmp hltloop 
    
notequal:
    mov rbx, 0xb8000
    mov rsi, diskverifyerror
    call print_lm
    push rbx
    xor rax,rax
    xor rbx,rbx

    mov bx, word[0x07fe]
    mov rdi, rbx
    pop rbx
    add rbx,0x3e
    
    call print_reg
    mov ax, word[0x0bfe]    
    add rbx, 2
    mov rdi,rax
    call print_reg
    jmp hltloop

hltloop:
    hlt
    jmp hltloop


calc_lba:
    sub eax, 0x0002 ;clusters start at 2 so zero out the number
    xor cx,cx 
    mov cl, byte[0x7c0d] ;mov sectors per cluster to cl
    mul cx ;ax now equal previous value * cx
    add eax, dword[0x7df8] ;ax now equals previous + FATDATA sector
    add ax, word[0x7dfc]
    ret

;
;Data
;
same: db "Disk Confirmed", 0x00
readerr: db "Disk read error", 0x00
diskverifyerror: db "unable to confirm disk ports please report to dev", 0x00
readdone: db "Reading finished no error bits set", 0x00
a20error: db "Error Enabling A20 Line", 0x00 
longerror: db "No Long mode support detected", 0x00 
cpuiderr: db "Error checking CPU", 0x00
hex_ascii: db "0123456789abcdef", 0x00

times 1534-($-$$) db 0x00
SIGNATURE: db 0x55, 0xaa ;This is here as sort of signature
