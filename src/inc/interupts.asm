[bits 64]

%define BASE 0x8000

%macro pushaq 0
  	push rax
  	push rcx
  	push rdx
	push rbx
%endmacro

%macro popaq 0
	pop rbx
  	pop rdx
  	pop rcx
  	pop rax
%endmacro 

;Not 100% sure but I think the IDT needs to be filled in at runtime
idt_start:
    times (33*16) db 0x00
    dw (BASE + isr1 - $$)
    dw 0x0008
    db 0x00
    db 0x8e
    dw (BASE + isr1 - $$) >> 16 
    dd (BASE + isr1 - $$) >> 32 
    dd 0x00000000
idt_end:

idt_info:
    dw idt_end - idt_start - 1
    dq idt_start

isr1: 
    in al, 0x64 ;read in byte from keyboard status register
    test al, 0x01 ;test if buffer full bit is set 
    jz keyboard_locked ;if not set don't proced 
    test al, 0x20 ;keyboard locked bit set 
    jnz keyboard_locked ;if it is don't proced

    in al,0x60 ;read in scan code 
 
    cmp al, 0x3a
    jl keyboard_print 
    jmp keyboard_locked 
    keyboard_print:

    mov [rbx],al
    add rbx,2

    keyboard_locked:
    ;send end of interupt to the PIC so it knows a new interupt may be processed
    mov al,0x20
    out PIC1_Com,al
    out PIC2_Com,al
    iretq


load_idt:
    xor rax,rax
    mov bx,0x2028
    call remap_pic
    lidt [idt_info]

    sti
    ret

keyset1: db 0x00,0x00,'1234567890-=',0x00,0x00,'qwertyuiop[]',0,0,"asdfghjkl;'`",0x00,'\zxcvbnm,./',0x00,'*',0x00,' '

