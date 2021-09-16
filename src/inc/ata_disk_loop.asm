;
; Basic function to loop through disk and look for the same qword in the mbr
;
read_ata_disks:
    xor rdx,rdx
    mov dx, word[ATA_REGS+rbx]
    push rbx
    mov bl, 01000000b ;master drive read 
    xor rax,rax
    mov cx, 0x0001
    mov rdi, 0x0a00
    call ata_read
    jc next_dev
    
    mov rax,qword[0x0600]
    mov rbx,qword[0x0a00]
    cmp rax,rbx
    je found_mbr
    
next_dev:
    pop rbx ;pop the current ATA reg counter off the stack 
    add bx, 0x02
    cmp bx, 0x08
    jne read_ata_disks

verification_error:
    mov rsi,verifyerror
    mov rdi,0xa0000 
    call print_gui64 
    add rbx, 0x22
    push rbx

;    xor rcx,rcx
;    xor rax,rax
;    mov al,0x06
;    mov ecx,0x04 
;
;ata_statuses:
;    mov rsi,ata_bus
;    mov byte[rsi+4],cl 
;    add byte[rsi+4],0x30 ;print bus number 
;    
;    push rax ;save rax as print_lm modifies it
;    push rcx
;    call print_lm
;    
;    pop rcx
;    pop rax ;restore rax
;    
;    push rbx ;annoying I have to use bx for this buffer 
;    mov rbx,rax ;move rax into rbx  
;    mov rdx,[ATA_REGS+rbx] ;get the ATA Bus we want to read 
;    pop rbx ;restore video memory position 
;    
;    push rax ;save rax as we mess with it below 
;    add dx,7 ;point dx to the status register
;    in al,dx ;read in the status register 
;    mov rdi,rax
;    push rcx
;    call print_reg
;
;    pop rcx ;restore rcx as print_reg modifies it 
;    pop rax ;restore rax as print_reg modifies it 
;    sub al,2 ;mov onto the next ata port
;    add rbx, 0x74
;
;    loop ata_statuses

    jmp hltloop

