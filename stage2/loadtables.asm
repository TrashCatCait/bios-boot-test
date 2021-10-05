[bits 32]
section .text 
    global load_gdt
    global load_idt

load_gdt:
    lgdt [rdi] ;called from C compiled on linux gdt pointer should be in RDI
    mov rax, 0x08 ;move the kernel code segement into rax 
    push rax ;push qword 0x08 to stack 
    mov rsi, segement_flush ;mov the segement address flush function to rsi
    push rsi ;push address to stack 
    retfq ;far qword return to flush function CS=0x08 and *S=0x10.

;Not global only called in here
segement_flush:
    mov ax,0x10 ;set to kernel data segement of GDT
    mov ds, ax
    mov es, ax 
    mov fs, ax 
    mov gs, ax
    mov ss, ax   
    retq


load_idt:
    lidt [rdi]
    sti
    retq

