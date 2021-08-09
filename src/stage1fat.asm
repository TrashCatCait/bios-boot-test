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
    ;Stack technically will grow towards our mbr code.
    ;This isn't an issue as we won't be pushing a lot to stack 
    ;so we should never go that low
    
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

    mov ah,0x0e
    pop dx
    shr dl, 4 
    add dl,48
    mov al,dl 

    int 0x10
    
    jmp $

    times 510-($-$$) db 0x00

db 0x55, 0xaa
