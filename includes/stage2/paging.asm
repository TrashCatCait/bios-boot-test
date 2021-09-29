[bits 32]

enablepaging:
    mov edi,0x1000 ;pml4 table located at 0x1000 
    mov cr3,edi ;load that table into cr3 

    mov dword[edi],0x2003 ;mov a pointer to page directory pointers 
    add edi,0x1000 ;move edi to 2000 the first level 3 page table 
    mov dword[edi],0x3003 ;set entry one to point to 0x3003 the page directory
    add edi,0x1000 ;add 1000 edi is now 0x3000 
    mov dword[edi],0x4003 ;set the first entry of the page directory to point to the page table
    add edi,0x1000

    mov ebx, 0x00000003
    mov ecx, 0x200

.identity_paging:
    mov dword [edi], ebx ;mark all the pages as present
    add ebx, 0x1000
    add edi, 8
    loop .identity_paging


    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

