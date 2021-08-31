[bits 64]

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
    times (1*16) db 0x00
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
    pushaq
    call keyboard_main_handler
    ;send end of interupt to the PIC so it knows a new interupt may be processed
    mov al,0x20
    out PIC1_Com,al
    out PIC2_Com,al
    popaq
    iretq


load_idt:
    call remap_pic
    lidt [idt_info]

    sti
    ret



