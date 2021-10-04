[bits 16]

;function to dump 16 bit registers to screen
printreg_16:
    mov ch, 4 ;print 4 nibbles
    mov cl, 4 ;roll 4 bits
    mov bl,0x0f 
    .loop:
        rol dx,cl 
        mov ax,0x0e0f ;tty print interupt and mask nib
        and al, dl ;al = copy of the low nibble 
        add al,0x90
        daa 

        adc al,0x40

        daa 
        int 0x10
        dec ch 
        jnz .loop
        ret
;
