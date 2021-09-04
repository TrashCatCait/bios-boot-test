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
    
    mov eax,0x000b8000
    call set_cur
    call clear_screen ;clear the screen
    call load_idt ;load and enable our IDT this is useless rn. I hope in the future
    ;I can add interupts for reading from disks.
    
    xor rbx,rbx
    jmp read_ata_disks

;at the moment we assume that the first byte(s) of the MBR being the same 
;mean we've found the same disk I'll work on making this more robust
;but this is nice and simply for testing. 
found_mbr:
    mov rsi,same 
    mov rbx,0xb8000
    call print_lm ;print disk found string

;we assume FAT root sector is loaded at 0x800 
;need to clean this up so that it's more intellegient in future but
;hard coding it a good way to test if something works.
pop rbx
mov rdi,0x800 ;Where we loaded root dir in stage 1 loader
mov cx, 0x08 ;root directory entries to be read.	
find_kernel:
    xor rax,rax;clear out rax register for calculating the LBA into
    push rcx ;save the counter for root directorty entries  
    mov ax, word[rdi + 0x003a] ;read in the disk start cluster of file 
    
    call calc_lba ;call lba calculation function 
    push rax ;save LBA in EAX 
    xor edx,edx ;clear dx for division

    mov ax, word[rdi + 0x003c]
    mov cx, 0x0200
    div cx
    mov cx,ax

    cmp dx,0x00
    je no_round 

round:
    inc cx ;round cx up by one  

no_round:
    pop rax
    push rax
    mov dx,[rbx+ATA_REGS]
    push rdi ;save rdi 
    push rbx
    mov bl, 11100000b
    mov rdi, 0x10000 ;where to begin loading the kernel.
    call ata_read
    
    pop rbx
    
    ;	TODO:
    ;	Add a method to verify the kernel executeable. 
    ;	Either using the multiboot 2 standard or my own 
    ;	signature though I'm leaning towards MB2 standard
    ;	as that allows users to use grub and other
    ; 	multiboot compatiable bootloaders by default with 
    ;	no extra work needed

    mov rax,qword[0x10000]
    mov rdi,rax
    mov rbx,0xb8000
    call print_reg
    jmp $
;
;
;
next_entry:
    pop rbx ;restore rbx
    pop rdi ;restore rdi 
    pop rcx ;restore rcx
    add di, 0x40
    dec cx 
    cmp cx, 0x00 
    jnz find_kernel
 
hltloop:
    hlt
    jmp hltloop

%include './inc/ata_disk_loop.asm'
%include './inc/keyboard.asm'
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
