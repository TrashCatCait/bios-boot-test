[bits 16]

get_memmap:
    mov di,map_ptr+4 ;where we want to store our entries
    xor ebx,ebx ;ebx starts off as 0 
    xor bp,bp ;entry count stored in bp
    mov edx,0x0534D4150 ;Place SMAP into edx 
    mov eax,0xe820 ;interrupt function number e820 memory map
    mov [es:di + 20],dword 1 ;force valid acpi 3.x entry even if function doesn't return one 
    mov ecx,24 ;ask for 24 bits from the interrupt 
    int 0x15 ;call interrupt
    jc e801
    
    mov edx,0x0534D4150 
    cmp eax,edx
    jne e801
    
    test ebx,ebx ;list length 
    je e801 
    jmp .getmap
.loop:
    mov eax,0xe820 ;trashed by call reset to function no 
    mov [es:di+20], dword 1 
    mov ecx, 24 ;trashed in call
    int 0x15 
    jc .done ;if carry is set here it's due to an the list already being finshed when we ask for more entries
    mov edx,0x0534D4150 ;trashed in call so restore it
.getmap:
    jcxz .skip ;skip any entries length of 0
    cmp cl,20
    jbe .notext 
    test byte[es:di+20], 1 ;check if ignore bit is set 
    je .skip ;if it is skip
.notext:
    mov ecx,[es:di+8] 
    or ecx,[es:di+12] ;or lower bytes with up to test for zero 
    jz .skip ;if it is skip it 
    inc bp
    add di, 24 ;move pointer forword one entry 
.skip:
    test ebx,ebx ;if ebx resets to 0 list is complete and we can stop reading 
    jne .loop ;else loop back and grab another entry
.done:
    mov word[es:di],bp ;store entry count at start of map 
    ret 

;;
; On the off chance this function isn't support or is just broken 
; we will revert to getting a basic e801 map. Then on the RARE chance
; that e801 doesn't work we will revert to ah=88 memory map 
;;
e801:
;;xor out all the general purpose registers 
    xor cx,cx
    xor dx,dx 
    xor bx,bx

    mov ax,0xE801 ;mov function call number into ax
    int 0x15
    jc  memmap_err ;if this function isn't supported just print an error 


    cmp ax,0x0000 ;if ax also equals zero or e801 then we can't trust these values either 
    je .usecx 

    mov word[es:di],ax
    mov word[es:di+2],bx

.usecx:
    jcxz memmap_err ;if cx is zero just error out 

    mov word[es:di],cx
    mov word[es:di+2],dx

.done:
    pop es 
    ret ;return to main functions

memmap_err:
mov esi,memory_err
call print_str
jmp hltloop

section .data
memory_err: db "Unable to get valid memory map", 0x00 


section .text
