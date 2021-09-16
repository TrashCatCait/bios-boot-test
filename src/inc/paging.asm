[bits 32]

page_sizes equ 0x1000 ;4kib pages

enable_paging:
    mov edi,page_sizes
    mov cr3,edi

    mov dword[edi],0x2003
    add edi,0x1000
    mov dword[edi],0x3003
    add edi,0x1000
    mov dword[edi],0x4003
    add edi,0x1000

    mov ebx, 0x00000003
    mov ecx, 0x200

.identity_paging:
    mov dword [edi], ebx
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
