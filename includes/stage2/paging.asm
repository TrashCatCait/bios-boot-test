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
    
    mov al,byte[vesa_on]
    cmp al,0x01 ;check if the enable bit is set 
    je map_vesa_bfr ;jmp 

.return:
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

;If vesa was successful we will likely need to use a different framebuffer address
map_vesa_bfr:
    mov ebx,[mode_info.baseptr]
    mov ebx,0xfd000000
    cmp ebx,0x00200000 ;check if it's not already in the area we've identity_paged
    jb .done


    mov dword[0x3008],0x5003 ;set page tables to create a second table at 0x5000 
    mov edi,0x5000 ;move edi to this location.

    mov ebx,[mode_info.baseptr]
    and ebx,0xfffff000 ;and out the first 24 bits as they are not part of the address 
    or ebx,3 ;present and read bits 
    mov ecx,0x200

.mapfb:
    mov [edi],ebx 
    add edi,8
    add ebx,0x1000 
    loop .mapfb 

.setfbaddr:
    mov eax,0x200000
    mov ebx,dword[bufferptr]
    mov dword[ebx],eax

.done:
    jmp enablepaging.return
