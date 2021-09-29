[bits 32]

checkcpuid:

    pushfd ;push flags double register 
    pop eax ;pop it into eax 
    mov ecx, eax ;copy it into eax
    xor eax, 1 << 21 ; set the CPU id bit. 
    push eax ;push  eax
    popfd ;pop it back into flags 
    pushfd ;push flags back onto stack 
    pop eax ;pop it back onto eax 

    push ecx ;push original flags back 
    popfd ;pop them back in place 

    xor eax,ecx ;xor original flags with changed one 
    jz nocpuid ;if they equal zero then the ID bit is not modifiable 
    ;and CPUID is not supported  

    mov eax, 0x80000001 ;If it is supported 
    cpuid ;call it  
    test edx, 1 << 29 ;test the long mode bit 
    jz nolong ;if unset print long mode error 
    ret ;return 


nocpuid:
    xor edi,edi 
    call clear_scr

    mov esi, cpuiderr 
    mov edi, 0x000a0000
    call print_gui32
    jmp hltloop


nolong:
    xor edi,edi 
    call clear_scr

    mov esi, longerror
    mov edi, 0x000a0000
    call print_gui32
    jmp hltloop

