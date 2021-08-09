;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   A20 functions.    
;   Check a20
;   enable it if needed
;   return to code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 16]

; CHECK a20
;
;checkA20 line function based on os-dev wiki function
;used pusha instead of push si and push di.
;as pusha uses one less byte and using popa uses 
;another one less byte small gains but useful when 
;limited to 512
;returns 0 in ax if a20 is disabled or not(0) if enabled
;

checkA20:
    pushf
    push ds
    push es
    pusha ;using pusha as it uses one less byte.
  
    
    xor ax, ax ; ax = 0
    mov es, ax ; can't set segment register directly

    not ax ; ax = 0xffff
    mov ds, ax
    
    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    mov ah, byte [ds:si]
    push ax
    
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], ah
    mov byte [es:di], al
    
    mov ax, 0
    je checkA20.exit
    
    mov ax, 1
    .exit:
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

    call checkA20 ;check a20 again
    cmp ax, 0
    jne enableA20.done

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
    
    call checkA20
    cmp ax, 0 
    jne enableA20.done

    in al, 0x92
    or al, 2
    out 0x92, al
    cmp ax, 0 
    jne enableA20.done
    
    mov si, a20error
    call print
    hlt

    .done:
        popa
        ret

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


