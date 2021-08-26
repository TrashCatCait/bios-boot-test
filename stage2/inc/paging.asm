[bits 32]

enable_paging:
    mov eax, p3_table ;load the first entry of page table 3 into eax
    or eax, 0b11 ;make sure present and writeable bit as set for this page  
    mov dword[p4_table + 0], eax ;map page table 3 into page table 4

    mov eax, p2_table ;load first entry of table 2 into eax 
    or eax, 0b11 ;present and writeable bit 
    mov dword[p3_table + 0], eax ;map table 2 into table 4 

    mov ecx, 0x00 ;counter 

map_table_2:
    mov eax, 0x200000 
    mul ecx 
    or eax, 0b10000011
    mov [p2_table + ecx * 8], eax

    inc ecx 
    cmp ecx, 512
    jne map_table_2

    mov edi, p4_table ; Set the destination index to 0x1000.
    mov cr3, edi ; mov edi into cr3

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax

    ret 
