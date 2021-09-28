[bits 16]

;;
; Input Parameters
; edi = LBA
; ax = segement to load data
; dl = disk no
; cl = sectors count to read 
; bx = where to load data
;;
read_disk:
    push ax
    push dx
    push cx
    push bx
    push edi 
check_disk_ext:
    mov ah, 0x41 ;Function number for check extentions
    mov bx, 0x55aa ;Should be reversed if extentions exist
    mov dl, byte[disk] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
    
disk_read_ext:
    call disk_reset 
    pop edi 
    pop bx
    pop cx
    pop dx
    pop ax


    push dword 0 ;push upper 32LBA bits
    push dword edi ;push lower 32LBA bits
    push word ax ;segement to load
    push word bx ;location to read
    push word cx ;sectors to read
    push word 0x0010 ;DAP size
   
    
    mov ah,0x42
    mov dl,byte[disk]
    
    mov si,sp

    int 0x13

    jc read_error 

    add sp, 0x10

    ret

;
; Not implemented yet
;
disk_read_no_ext:
    call disk_reset
    pop edi 
    pop bx
    pop cx
    pop dx
    pop ax    
    
    jmp read_error

    ret

read_error:
    mov si,disk_error 
    call print_str ;call print string function 
    jmp loop_end ;jump endlessly 


disk_reset:   
    mov ah, 0x00 ;mov BIOS disk reset number into ah 
    mov dl, byte[disk] ;BP should have been overwritten with BIOS disk No
    int 0x13 ;call interupt 
    jc disk_reset ;if an error happended reset the disk again 
    ret ;return 

disk_error: db "Disk Err", 0x00 ;4 

