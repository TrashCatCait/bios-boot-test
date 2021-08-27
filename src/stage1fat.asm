;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   FAT VBR BOOT CODE.                               ;
;   1) Read file from FAT data                       ;
;   2) Load Stage 2
;   3) clean up                                      ;
;   size 420 bytes to achieve this in.               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[org 0x7c00]
[bits 16]

fake_start:
    jmp short real_start
    nop 
    
    ;My BPB isn't written to the disk but the labels provide memory addresses which means.
    ;To refer to reserved sectors I can just do [Reserved_Sectors] instead of 0x7c**
    OEM_ID db "mkfs.fat"
    Bytes_Per_Sector dw 0x0000
    Sectors_Per_Cluster db 0x00
    Reserved_Sectors dw 0x0000
    FAT_count db 0x00 
    Root_Entries dw 0x0000 
    Number_Of_Sectors dw 0x0000 
    Media_Desc db 0x00
    Sectors_Per_Fat dw 0x0000 
    Sectors_Per_Track dw 0x0000
    Sectors_Per_Head dw 0x0000
    Hidden_Sectors dd 0x00000000 
    Total_Sectors dd 0x00000000 
    Big_Sectors_Per_Fat dd 0x00000000
    Flags dw 0x0000
    FAT_Version dw 0x0000
    RootDirStart dd 0x00000000
    FSInfoSector dw 0x0000
    BackUpSector dw 0x0000
    ;reserved bytes 
    times 12 db 0x00
    DriveNum db 0x00
    Reserved_Byte db 0x00
    Signature db 0x00
    VolID dd 0x00000000
    VolLab db "Boot loader" ;Needs to be 11
    SystemID db "FAT32   " 

real_start:
    cli 
     
    ;Clear segement regs
    xor eax, eax ;clean out whole of EAX as we use it later and need it to be clear 
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov ds, ax
    
    ;stack below code 
    mov bp, 0x7c00
    mov sp, bp
       
    sti
    ;;currently we assume the MBR gives us the partition offset in bx
    ;;and the bios disk id in dl
    mov [partition_offset], bx ;Store partition offset for later use.
    mov [DriveNum], dl ;Save the value of dl

    ;
    ;	Step one work out data segement of FAT
    ;
    mov cx, word[Sectors_Per_Cluster]
    ;first_data_sector = fat_boot->reserved_sector_count + 
    ;(fat_boot->table_count * fat_size) + root_dir_sectors;
    ;Taken from OSdev wiki
    ;So in ASM something like this
    ;also based on this formula 
    ;https://www.easeus.com/resource/fat32-disk-structure.htm
    mov al, byte[FAT_count]
    mul dword[Big_Sectors_Per_Fat] ;Multiply value in ax 0x0002 by Sectors per fat aka table count * fat size 
    add ax, word[Reserved_Sectors] ;add the reserved sectors 
    mov [FATDATA], eax ;save our data sector into here for future use.
    ;So this currently only works with Fat32 but I'll try and make it compatiable later
    ;TODO With other FATS though not a huge deal now  
    
    ;;Making it actually look for the second stage.
    mov ax, word[RootDirStart]
    call calc_lba
    mov bx, 0x0800
    mov cx, 0x0001
    call lba_read
    
    mov di, 0x0800
 
    ;We loop here to load the next file if the last one is incorrect
    mov cx, 0x10 ;We search the first 16 file entries 
    
    next_entry:
    push cx ;save cx so we don't overwrite it.
    mov ax, word[di + 0x003a];read in the disk start cluster 
    
    ;Load stage2 here
    call calc_lba ;
    mov bx, 0x8000 ;address to load bx at
    push eax ;Push the LBA address on to the stack to keep it safe
    
    xor dx,dx ;Clear out DX as it's important that it equals zero
    
    ;Calculate the size of the stage2 file
    mov ax, word[di + 0x003c] ;Read in a word of the size 
    mov cx, 0x0200 ;move 512 bytes into ecx  
    div cx ;Divide 
    mov cx,ax ;move the result into the cx register
    
    cmp dx, 0x00 ;if remainder of divide is 0
    je no_round ;dont round up just skip to no_round

round:
    inc cx ;round up to read on more sector

no_round:
    pop eax ;restore the EAX register the LBA val
    call lba_read
    
    pop cx
    mov bx, word[di + 0x003c] ;read in the word size
    cmp word[0x8000 + bx - 2], 0xaa55 ;compare the last two bytes 
    jne not_valid ;If they are not equal goto not valid
    cmp word[0x8000], 0x0000 ;If it is valid but empty goto err
    je not_valid ;loop again to see if there is a valid oe

    ;Jump to stage 2
    jmp 0x0000:0x8000


;
;  If Last entry was invalid
;
not_valid:
    add di, 0x40 ;move to the next file entry 
    dec cx ;decreament dx 
    cmp cx, 0x00 ;if dx reaches zero 
    je stage2err ;print error 
    jmp next_entry ;else jump next 
    
;
;  LBA READ DISK
;
disk_reset:
    pusha ;save all registers 
    xor ax,ax ;disk reset function for int 13
    mov dl, [DriveNum] ;drive to reset
    int 0x13 ;call interupt 
    jc disk_reset ;if an error occurs while resetting try reset again
    
    popa ;restore all registers 
    ret ;return 


lba_read:
    call disk_reset 
    
    push dword 0x00 
    push dword eax
    push word 0x00
    push word bx 
    push word cx
    push word 0x0010
    
    mov dl, [DriveNum]
    mov ah, 0x42
    
    mov si, sp

    int 0x13
    jc disk_error 
    
    ;;Me being a dummy returning from this before adding this and it failing 
    ;;Then I realised the DAP was still on the stack
    add sp, 0x10    

    ret

;
; outdated but may be needed 
; Currently unworking reads wrong disk sectors I think
chs_read:
    call disk_reset

    call lba_to_chs 
    mov ah, 0x02 ;BIOS READ int 0x13
    mov al, cl ;sectors to read 
    mov ch, byte[abs_cyli] ;Move the cylinder count into ch
    mov cl, byte[abs_sect] 
    mov dh, byte[abs_head]
    mov dl, byte[DriveNum]
    int 0x13
    jc disk_error 
    ret

;
; Errors
;
stage2err:
    mov si, stage2_fail 
    call print_str
    jmp $


disk_error:
    mov si, disk_fail
    call print_str
    jmp $

;;
;  BIOS Print Function
;;
print_str:
    mov ah, 0x0e
    
    .loop:
	lodsb
	cmp al,0 
	je .done
	int 0x10
	jmp print_str.loop
    .done:
	ret

;;
;  Calculate the LBA sector of data we want to read.
;;

    ;;If extentions are supported do this aka we can use LBA
    calc_lba:
	sub eax, 0x0002 ;clusters start at 2 so zero out the number
	xor cx,cx 
	mov cl, byte[Sectors_Per_Cluster] ;mov sectors per cluster to cl
	mul cx ;ax now equal previous value * cx
	add eax, dword[FATDATA] ;ax now equals previous + FATDATA sector
	add ax, word[partition_offset]
	ret

    ;;If extentions aren't supported we need to calculate this
    ;;formula taken from here: https://www.viralpatel.net/taj/tutorial/chs_translation.php
    ;   cylinder = LBA / (heads_per_cylinder * sectors_per_track)
    ;   temp = LBA % (heads_per_cylinder * sectors_per_track)
    ;   head = temp / sectors_per_track
    ;   sector = temp % sectors_per_track + 1
    lba_to_chs:
	xor dx, dx
	div word [Sectors_Per_Track] ; calculate absolute sector
	inc dl 
	mov byte [abs_sect], dl
	xor dx,dx
	div word [Sectors_Per_Head] 
	mov [abs_head], dl
	mov [abs_cyli], al
	ret

;;
;   DATA SECTION 
;;

abs_sect db 0x00
abs_cyli db 0x00
abs_head db 0x00
;;
; strings 
;;
stage2_sig: dw 0x0000
disk_fail: db "Read Error", 0x00
stage2_fail: db "Unable to find valid stage 2", 0x00


times 504-($-$$) db 0 
FATDATA dd 0x0000
partition_offset dw 0x0000
db 0x55, 0xaa

