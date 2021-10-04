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
    pusha
    push edi 
check_disk_ext:
    mov ah, 0x41 ;Function number for check extentions
    mov bx, 0x55aa ;Should be reversed if extentions exist
    mov dl, byte[disk] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jnc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
    
disk_read_ext:
    call disk_reset 
    pop edi 
    popa

    push dword 0 ;push upper 32LBA bits
    push dword edi ;push lower 32LBA bits
    push word ax ;segement to load
    push word bx ;location to read
    push word cx ;sectors to read
    push word 0x0010 ;DAP size
   
    mov dl,byte[disk] 
    mov ah,0x42
    
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
    
convertLBA:
    xor ecx,ecx
    xor di,di 
    mov byte[abs_sec],0
    mov ah,0x08 ;get drive parameter interupt no 
    mov dl,byte[disk] ;disk to get parameters for 
    int 0x13 ;call interupt 
    jc disk_error ;if carry flag set report read error 
    pop edi
    xor eax,eax ;clean eax register for use below
    ;LBA to CHS conversion formula take from here 
    ;https://www.viralpatel.net/taj/tutorial/chs_translation.php

    and cx,0x003f ;and out bytes we don't want/need (cyliander bytes)
    mov al,cl ;mov sector number into al 
    inc dh ;add one to drive per track count as function return (drive per track - 1)
    
    mul dh ;number of sectors per track * heads per track result
    mov ebx,eax ;move result into bx
    mov eax,edi ;move LBA into eax 
    xor edx,edx ;clear dx register to ovide errors 
    div ebx ;divide eax by ebx LBA / (heads_per_cyl * sects_per_track) 


    mov byte[abs_cyl],al ;move the lower 8bits into cyl count 
    shl ah, 6 ;shift the lower bits to take the highest 2 bits of the sector count
    mov byte[abs_sec],ah ;move the higher two bits into sec
    
    
    mov eax,edx ;move the remainder into eax
    xor edx,edx ;clear out dx register again 
    div ecx ;divide by the sectors per track  
    mov byte[abs_had],al ;store the result as head 
    inc dl ;add one to the sector count 
    or byte[abs_sec],dl ;store the sector count 

    xor bx,bx
    mov es,bx ;es can be modified when this function is run on a floopy disk we want to make sure it's back at zero as this can effect where we load our data in

    popa
    push es ;push original es 
    mov es,ax ;segement to load file into 
    mov al,cl ;mov sectors to count into al
    mov dl, [disk] ;where we saved the BIOS disk number 
    mov dh, [abs_had] ;Partition head number 
    mov cl, [abs_sec] ;Partition sector number 
    mov ch, [abs_cyl] ;Partition cyliander number 
    mov ah, 0x02 ;disk read and al is sectors to read 
    int 0x13 ;call interupt 
    jc read_error ;if carry flag is set jump to read error

    pop es ;restore es to original value 
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

abs_sec: db 0x00
abs_had: db 0x00 
abs_cyl: db 0x00 
disk_error: db "Disk Err", 0x00 ;4 

