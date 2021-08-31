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
    in al, 0x64 ;read in byte from keyboard status register
    test al, 0x01 ;test if buffer full bit is set 
    jz skip_printing ;if not set don't proced 
    test al, 0x20 ;keyboard locked bit set 
    jnz skip_printing ;if it is don't proced

    in al,0x60 ;read in scan code 
    push rax ;save scan code 
    and al, 0x80 ;and the 8 bit as this should only be set on released characters 
    cmp al, 0x80 ;check if the scan code now = 80 
    pop rax ;restore code 
    je skip_printing 
    
    keyboard_print:
    push rbx ;save video memory location
    xor rbx,rbx ;clean out high bytes of rbx
    mov bl,al ;mov scan code into bl
    mov al, [keyset1+rbx] ;look up the ascii value in the scan code table 
    pop rbx ;restore video memory 
    
    cmp al,0x00 ;check if the key is speacial key ctrl, alt, tab, etc...
    je skip_printing ;if it is don't print it 

    mov [rbx],al ;mov character into video memory if it's not special char 
    add rbx,2 ;add 2 to the video memory value 

    skip_printing:
    ;send end of interupt to the PIC so it knows a new interupt may be processed
    mov al,0x20
    out PIC1_Com,al
    out PIC2_Com,al
    iretq


load_idt:
    call remap_pic
    lidt [idt_info]

    sti
    ret

keyset1: db 0x00,0x00,'1234567890-=',0x00,0x00,'qwertyuiop[]',0x00,0x00,"asdfghjkl;'`",0x00,'\zxcvbnm,./',0x00,'*',0x00,' ',0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,'789-456+1230.',0x00,0x00,0x00,0x00,0x00,0x00


