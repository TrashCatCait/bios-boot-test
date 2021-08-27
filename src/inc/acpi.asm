[bits 64]


init_acpi:
    xor rsi,rsi
    mov esi,0x000e0000 ;Base memory region to search 

find_acpi: 
    mov rbx,"RSD PTR " ;move this string into RBX 

next_qword:
    lodsq ;Load single qword from RSI then add one qword (8 bytes)
    cmp rax,rbx ;cmp what we loaded from memory to what we have in rbx
    je found_acpi ;Go here if we found what we wanted
    cmp esi,0x000fffff ;if we get this high in memory stop searching 
    jge noacpi
    jmp next_qword

found_acpi:
    push rsi
    xor rbx, rbx ;clean DX register 
    xor rcx, rcx ;clean CX register
    mov cl, 0x14 ;rcx = 0x0000 0000 0000 0014 we are only checksumming ACPI ver 1.0 bytes here
    
    sub rsi, 0x08 ;rsi now points back to the start of the RSD PTR string

checksum:
    lodsb ;load byte into al
    add bl,al ;the first 20 bytes should = 0 when added
    dec cl ;decreament the counter
    cmp cl, 0x00 ;cmp counter to zero
    jne checksum ;if counter does not equal 0 jump to checksum

    pop rsi ;we restore RSI to the pre sub 8 value so a if this is incorrect and this is
    ;not our RSDP structure or the checksum is just incorrect we continue searching memory 
    ;and don't get suck in an infinate loop as if we did not restore this value we wouldn't
    ;check the bytes just after the string and if we did sub rsi, 0x14 we would just read the same value

    cmp dl, 0x00 ;checksum + all bytes of Table should = 0 in the lowest byte of the rdx register.
    ;This serves two purposes, security and making sure we don't just grab random data
    jne find_acpi ;Check sum incorrect continue looking 
    
    

    ;rsi = base of RSDP structure + 8 bytes aka = the checksum.
    add rsi, 0x07 
    lodsb ;load the ACPI revision into the al register.
    ;RSI should now point to the base RSDT address.

    cmp al, 0x00 ;check the revision version 
    je acpi_v1 ;if this byte equals zero ACPI version 1 is used 
    jmp acpi_v2 ;if it doesn't equal zero that means ACPI version 2 or greater 

acpi_v1:
    push rsi 
    mov rsi, acpi_v1_str
    mov rbx, 0xb8000
    call print_lm
    pop rsi
    
    xor rax,rax ;clean out rax just in case higher bytes are set as RSDT is 32bit pointer. We cast it to 64 bit as this a 64 bit bootloader and we don't want the higher bytes to be set as that would change the pointer.
    lodsd ;load a double word into eax register 
    
    mov qword[acpi_table_ptr], rax ;save the RSDT pointer for easy to access later use.
    mov rsi, rax
    
    lodsd ;
    cmp eax, 'RSDT';check the ACPI table signature.
    jne noacpi
    mov rdi, rax
    add rbx, 0x8c
    mov rsi, rsdt_found
    call print_lm
    add rbx, 0x80
    ret

acpi_v2:
    mov rsi, acpi_v2_str
    mov rbx, 0x00000000000b8000
    call print_lm
    ret

;For now this just errors but is left open should we start supporting PRE ACPI systems
noacpi:
    xor rbx,rbx
    mov rsi, acpi_err 
    mov ebx, 0x000b8000
    call print_lm
    jmp hltloop

rsd_ptr: dq 0 ;Most likely useless but saved for easy access for now
acpi_table_ptr: dq 0 ;This should be assgined at runtime to either the RSDT or the XSDT depending on acpi version 
rsdt_found: db "Found RSDT table", 0x00
xsdt_found: db "Found XSDT table", 0x00
acpi_v1_str: db "ACPI Ver 1", 0x00 
acpi_v2_str: db "ACPI Ver 2", 0x00
acpi_err: db "ACPI Unsupported", 0x00

