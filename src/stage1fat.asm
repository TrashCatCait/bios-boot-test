;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   FAT VBR BOOT CODE.                               ;
;   1) Get to 32 bit mode                            ;
;   2) Load Stage 2                                  ;
;   3) clean up                                      ;
;   size 420 bytes to achieve this in.               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[org 0x7c00]
[bits 16]

fake_start:
    jmp short real_start
    nop 
    
    times 90-($-$$) db 0x00

real_start:
    cli 
    ;Set up stack 
    
    ;Clear segement regs
    xor ax, ax
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov ds, ax

    mov bp, 0x7c00
    mov sp, bp
       
    push dx ;save dl
    
    sti
    
    call enableA20
    jmp load_protected
    jmp $
    

print: 
    mov ah,0x0e

    .loop:
	lodsb
	cmp al, 0x00 
	je print.done 
	int 0x10 
	jmp print.loop

    .done:
	ret

%include './inc/a20.asm'
%include './inc/gdt32.asm'

[bits 32]

protected:
    mov ax, data32
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000 ;stack here so it grows away from VGA video memory 
    mov esp, ebp
    
    mov edi, 0xb8000
    mov eax, 0x2f202f20
    mov ecx, 1000
    rep stosd

    jmp hltloop


hltloop:
    hlt
    jmp hltloop

;
;Data
;
a20error: db "a20 Err", 0x00 


db 0x55, 0xaa
