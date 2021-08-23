[bits 64]


find_acpi: 
    xor rsi,rsi
    mov esi,0x000e0000 ;Searches BIOS memory for the RSD PTR string
    mov rbx,"RSD PTR " ;Look for this
next_qword:
    lodsq	;Load single qword from RSI then add one qword (8 bytes)
    cmp rax,rbx ;
    je found_acpi ;Go here if we found what we wanted
    cmp esi,0x000fffff 
    jge noacpi

found_acpi:
    push rsi ;Save RSI to the stack and now the stack should contain a qword address to RSD PTR
    
    ;one byte cheaper than directly moving
    ;0x14 into rbx
    xor rbx, rbx
    xor rcx, rcx
    mov cl, 0x14 ;rcx = 0x0000 0000 0000 0014
    
    sub rsi, 0x08 ;Take one qword off of RSI to point to RSD PTR string again  

checksum: 
    lodsb ;load byte into al
    add bl,al ;the first 20 bytes should
    dec cl
    cmp cl, 0x00
    jne checksum
    
    pop rsi 
    cmp bl, 0
    jne next_qword ;Check sum incorrect continue looking 

    ret

;For now this just errors but is left open should we start supporting PRE ACPI systems
noacpi:
    xor rbx,rbx
    mov rsi, acpi_err 
    mov ebx, 0x000b8000
    call print_lm
    jmp hltloop

rsd_ptr: dq 0

acpi_err: db "ACPI Unsupported", 0x00
