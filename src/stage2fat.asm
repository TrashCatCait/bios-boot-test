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
    xor rbx,rbx
    mov bx, 0x08
    read_ata_disks:
    xor rdx,rdx
    mov dx, word[ATA_REGS+rbx] 
    mov rdi, 0x0a00 ;Data buffer to read into
    xor rax, rax ;LBA to read 
    mov cx, 0x0001 ;Sectors to read 
    push rbx
    mov bl, 00000000b ;head and drive selectors heads is not used in lba I think
    
    call ata_read_lba
    add dx, 0x01 
    in ax, dx
    
    ;;Tried this and the error bit doesn't seem to be set.
    test ax, 0
    jz no_err

err:
    mov rsi, readerr
    mov rbx, 0xb8000
    call print_lm
    jmp next_disk 

no_err:
    mov rax, qword[0x0600]
    mov rbx, qword[0x0a00]
    cmp rax,rbx
    je equal 
    jne not_equal

equal:
    call clear_screen
    mov rsi, same
    mov rbx, 0xb8000
    call print_lm


hltloop:
    hlt
    jmp hltloop

not_equal:
    mov rbx, 0xb8000
    mov rsi, diskverifyerror
    call print_lm
    xor rax,rax
    xor rbx,rbx

    mov rdx, qword[0x0a00]
    mov rdi, rdx
    add rbx,0x3e
    
    call print_reg
    mov rax, qword[0x0600]    
    add rbx, 2
    mov rdi,rax
    call print_reg

next_disk:
    pop rbx
    cmp bx, 0x00
    sub bx, 0x02 
    je hltloop
    jmp read_ata_disks

calc_lba:
    sub eax, 0x0002 ;clusters start at 2 so zero out the number
    xor cx,cx 
    mov cl, byte[0x7c0d] ;mov sectors per cluster to cl
    mul cx ;ax now equal previous value * cx
    add eax, dword[0x7df8] ;ax now equals previous + FATDATA sector
    add ax, word[0x7dfc]
    ret

%include './inc/acpi.asm'
%include './inc/pci.asm'
%include './inc/print_64.asm'
%include './inc/ata_read64.asm';
;Data
;
ATA_REGS:
dw 0x01f0
dw 0x0170
dw 0x01e8
dw 0x0168

same: db "Disk Confirmed", 0x00
readerr: db "Disk read error", 0x00
diskverifyerror: db "unable to confirm disk ports please report to dev", 0x00
readdone: db "Reading finished no error bits set", 0x00
a20error: db "Error Enabling A20 Line", 0x00 
longerror: db "No Long mode support detected", 0x00 
cpuiderr: db "Error checking CPU", 0x00
hex_ascii: db "0123456789abcdef", 0x00
pciah: db 0x00 
pcial: db 0x00
pcimajver: db 0x00 
pciminver: db 0x00
pcimaxbus: db 0x00
pcistring: dd 0x00
pcientry: dd 0x00


;NO LONGER NEEDED
;At the moment the bootloader has to be divsiable by 512
;So my solution 512*number of sectors minus 2
;times (512*4)-($-$$)-2 db 0x00

SIGNATURE: db 0x55, 0xaa ;This is here as sort of signature

section .bss
align 4096 

p4_table:
    resb 4096
p3_table: 
    resb 4096
p2_table:
    resb 4096
