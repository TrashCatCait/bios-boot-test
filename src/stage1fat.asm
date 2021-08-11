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
    xor eax, eax
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov ds, ax
    
    ;stack below code 
    mov bp, 0x7c00
    mov sp, bp
       
    sti
    
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
    
    ;;TODO
    ;;Now we want to read the first data sector to start looking at the files.
    ;;For now we will hard code this to load the first file but later I'll work on 
    ;;Making it actually look for the second stage.
    mov ax, word[RootDirStart]
    call calc_lba
    mov bx, 0x0800
    mov cx, 0x0001
    call lba_read
    
    mov di, 0x0800
    mov ax, word[di + 0x003a]
    
    ;Load stage2 here
    
    call calc_lba
    mov cx, 0x0002
    mov bx, 0x8000
    call lba_read
    
    ;Jump to stage 2
    jmp 0x0000:0x8000

    ;;Until this is finished this is here just to confirm we are getting to stage1
    jmp $

;
;  LBA READ DISK
;
disk_reset:
    mov ah, 0x00
    mov dl, [DriveNum]
    int 0x13
    jc disk_reset
    
    ret 


lba_read:
    pusha
    call disk_reset 
    popa
    
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


disk_error:
    mov ax, 0x0e77
    int 0x10
    jmp $

;
; outdated but may be needed 
;
chs_read:


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
	add ax, 0x0800
	ret

    ;;If extentions aren't supported we need to calculate this
    ;;formula taken from here: https://www.viralpatel.net/taj/tutorial/chs_translation.php
    ;   cylinder = LBA / (heads_per_cylinder * sectors_per_track)
    ;   temp = LBA % (heads_per_cylinder * sectors_per_track)
    ;   head = temp / sectors_per_track
    ;   sector = temp % sectors_per_track + 1
    lba_to_chs:
	
	ret

;;
;   DATA SECTION 
;;

FATDATA dd 0x0000


;;
; strings 
;;
stage2_failure: db "Loading Stage 2 Failed", 0x00


times 510-($-$$) db 0 
db 0x55, 0xaa
