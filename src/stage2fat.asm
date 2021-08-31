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
%define BASE 0x8000 ;org defined as base so we can easily use it in
;IDT as we do BASE + isr_label - $$ to convert it to scalar value.
[org BASE]
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
    
    call set_cur 
    call clear_screen
    call load_idt
    mov rbx,0xb8000
    jmp hltloop
    xor rbx,rbx
    add bx,2
read_ata_disks:
    xor rdx,rdx
    mov dx, word[ATA_REGS+rbx]
    push rbx
    mov bl, 11100000b ;master drive read 
    xor rax,rax
    mov cx, 0x0001
    mov rdi, 0x0a00
    call ata_read
    jc next_dev
    
    mov rax,qword[0x0600]
    mov rbx,qword[0x0a00]
    cmp rax,rbx
    je found_mbr
    
next_dev:
    pop rbx ;pop the current ATA reg counter off the stack 
    add bx, 0x02
    cmp bx, 0x08
    jne read_ata_disks

verification_error:
    mov rsi,verifyerror
    mov rbx, 0xb8000
    call print_lm 
    add rbx, 0x22
    push rbx

    xor rcx,rcx
    xor rax,rax
    mov al,0x06
    mov ecx,0x04 

ata_statuses:
    mov rsi,ata_bus
    mov byte[rsi+4],cl 
    add byte[rsi+4],0x30 ;print bus number 
    push rax ;save rax as print_lm modifies it
    call print_lm
    
    pop rax ;restore rax
    push rbx ;annoying I have to use bx for this buffer 
    mov rbx,rax ;move rax into rbx  
    mov rdx,[ATA_REGS+rbx] ;get the ATA Bus we want to read 
    pop rbx ;restore video memory position 
    
    push rax ;save rax as we mess with it below 
    add dx,7 ;point dx to the status register
    in al,dx ;read in the status register 
    mov rdi,rax
    push rcx ;save RCX 
    call print_reg

    pop rcx ;restore rcx as print_reg modifies it 
    pop rax ;restore rax as print_reg modifies it 
    sub al,2 ;mov onto the next ata port
    add rbx, 0x74

    loop ata_statuses

    jmp hltloop

;at the moment we assume that the first byte(s) of the MBR being the same 
;mean we've found the same disk I'll work on making this more robust
;but this is nice and simply for testing. 
found_mbr:

hltloop:
    hlt
    jmp hltloop

%include './inc/pic.asm'
%include './inc/interupts.asm'
%include './inc/acpi.asm'
%include './inc/pci.asm'
%include './inc/print_64.asm'
%include './inc/ata_read64.asm';

;
;Data
;
ATA_REGS:
dw 0x01f0
dw 0x0170
dw 0x01e8
dw 0x0168

same: db "Disk Confirmed", 0x00
readerr: db "Disk read error", 0x00
verifyerror: db "Unable to find ATA devices or data, please report to developer.", 0x00
ata_bus: db "BUS *:", 0x00
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
