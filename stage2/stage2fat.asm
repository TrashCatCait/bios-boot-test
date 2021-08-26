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
[bits 16]

section .text

stage2_start:
    cli 
    
    ;;Stack below stage 1
    mov bp, 0x7c00
    mov sp, bp
     
    push dx ;save dl
    
    sti
    
    xor edi,edi
    mov ax,0xb101 
    int 0x1a

    mov byte[pciah], ah
    mov byte[pcial], al
    mov byte[pcimajver], bh
    mov byte[pciminver], bl
    mov byte[pcimaxbus], cl
    mov dword[pcientry], edi
    mov dword[pcistring], edx

    call enableA20
    jmp load_protected
    
%include './inc/a20.asm'
%include './inc/gdt32.asm'
%include './inc/print.asm'

[bits 32]

protected_start:
    ;reload the data segement registers to 32 gdt data entry
    mov ax, data32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ebp, 0x90000 ;stack here so it grows away from VGA video memory 
    mov esp, ebp ;stack = base pointer 
    
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
    ;reload the data segement registers with out new gdt data entry.
    mov ax, data64 
    mov ds, ax
    mov es, ax 
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    mov rbp, 0x90000 ;stack placed just beloe video memory
    mov rsp, rbp ;stack = base pointer
    
    ;Disable PIC
    mov al, 0xff
    out 0xa1, al
    out 0x21, al

    call clear_screen
    call init_acpi


    mov rsi, acpi_on 
    call print_lm

hltloop:
    cli
    hlt
    jmp hltloop 

%include './inc/ACPI.asm'
%include './inc/print_64.asm'
%include './inc/ata_read64.asm'

;
;Data
;
section .bss 
align 4096

p4_table:
    resb 4096 ;reseve space for 1024 entries 
p3_table: 
    resb 4096 ;ditto as above 
p2_table:
    resb 4096 ;ditto as above
p1_table: 
    resb 4096 ;ditto

;
;Data
;
section .data
acpi_on: db "ACPI Exists", 0x00 
buffer1: db "BUF1:", 0x00
buffer2: db "BUF2:", 0x00 
same: db "Disk Confirmed", 0x00
readerr: db "Disk read error", 0x00
diskerror: db "Unable to confirm disk ports please report to dev", 0x00
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
