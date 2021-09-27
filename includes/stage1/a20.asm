[bits 16]
checkA20:
    pushf ;push the flags to the site
    push ds ;Save current value of ds
    push es ;Save current value of es 
    pusha ;using pusha as it uses one less byte.
  
    
    xor ax, ax ; ax = 0
    mov es, ax ; can't set segment register directly

    not ax ; ax = 0xffff
    mov ds, ax ;ds = 0xffff 
    
    mov di, 0x0500 ;set ds and si to be
    mov si, 0x0510 ;exactly 1mb apart when combinded with es,ds

    mov al, byte [es:di] ;save the current bytes at these memory
    mov ah, byte [ds:si] ;locations may not be needed but also might be
    push ax ;If the BIOS or firmware place some data here though it's unlikely
    ;as it should be above the BIOS data area 

    mov byte [es:di], 0x00 ;Place our values in and then
    mov byte [ds:si], 0xFF ;compare to see if they are the same 
    cmp byte [es:di], 0xFF

    pop ax ;pop the original values off the stack
    mov byte [ds:si], ah ;put them back
    mov byte [es:di], al
    
    mov ax, 0 ;we use move to avoid setting the flags from xor 
    je checkA20.exit ;if the bytes are the same i.e. memory wrapped around we return 0
    
    mov ax, 1 ;If not we return one 

    .exit: ;pop all the registers and returm
        popa
        pop es 
        pop ds
        popf
        ret
    
enableA20:
    pusha 
    ;attempt the bios int a20
    mov ax, 0x2401
    int 0x15 
    
    cli ;;Done with interupts for now

    call checkA20 ;check a20 again to see if bios interupt worked 
    cmp ax, 0 ;check if ax is 0 
    jne enableA20.done ;if it's not got the end a20 is on 
    
    ;
    ;Next we try enabling it through the keyboard controller IO port
    ;This is legacy from when the port used to be on the keyboard controller 
    ;IO port as there was a pin spare
    ;

    call a20wait
    mov al, 0xAD
    out 0x64,al

    call a20wait
    mov al, 0xD0
    out 0x64,al
    
    call a20wait2
    in al, 0x60
    push eax
    
    call a20wait 
    mov al, 0xD1
    out 0x64, al

    call a20wait
    pop eax 
    or al, 2
    out 0x60, al

    call a20wait 
    mov al, 0xAE
    out 0x64, al
    

    ;
    ;Check the status of a20 again if it's on goto the end if not
    ;try the "fast" a20 gate
    ;
    call checkA20
    cmp ax, 0 
    jne enableA20.done

    ;;
    ;if a20 still isn't on after this disable an error
    ;Either the system doesn't support it or it uses some other 
    ;a20 setting method I don't know about
    ;;
    in al, 0x92
    or al, 2
    out 0x92, al
    call checkA20
    cmp ax, 0 
    jne enableA20.done
    
    hlt
    jmp $

    .done:
        popa
        ret

;Wait for input ports to be ready before attempting to input data 
a20wait:
    in al, 0x64
    test al,2
    jnz a20wait
    ret

a20wait2: 
    in al,0x64
    test al,1 
    jz a20wait2
    ret
