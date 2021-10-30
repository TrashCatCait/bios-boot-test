;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  BIOS CD MBR sector 0.                             ;
; This MBR is intented to be used on a CD/ROM Drives ;
; This is mostly the same as the HDD bootloader as I ; 
; found when testing the HDD bootloader could work in;
; ISO files made with mkisofs. If I added byte 12 to ;
; the LBA offset as that's zero in harddrive boots   ;
; But it's mkisofs boot infos LBA offset in ISOs made;
; with mkisofs so that did work for extended reads   ; 
; but not for CHS as CHS auto assumes 512 in HDD boot;
; and I use unable to find a way to get sector size  ;
; other than extended drive parameters which isn't 
; useful for CHS. As if we revet to CHS in there it 
; means it isn't supported or an error occured.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

[bits 16]
[org 0x7c00]

; $$ - section start = org 0x7c00
; $ - current pos
; ($ - $$)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Definations        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%define disk_struct 0x0600

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR code         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
    jmp after_bpb ;Jmp to after_bpb symbol 
    nop ;No operation 
    
    times 8-($-$$) db 0x00  ;pad with zero until eltorito boot table 
    ;filled in by ISO creation tool 
    bi_PrimVolDesc_LBA dd 0x0000 ;LBA of PVD of ISO
    bi_MBR_LBA dd 0x0000 ;LBA of boot file should be this MBR
    bi_MBR_LEN dd 0x0000 ;Length of the bootfile
    bi_Checksum dd 0x0000 ;Check sum 
    bi_Reserved times 40 db 0 

    times 87-($-$$) db 0x00 ;Not sure if skip BPB matters with ISO booting but just in case

after_bpb:
    cli ;clear interupts while we set up segement registers
    jmp 0x0000:set_cs ;far jump to set cs setting the code segement to 0

set_cs:
    xor ax,ax ;xor out ax and set all other segement 
    mov es,ax ;registers equal to zero
    mov ss,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
    
    cld ;clear the direction flag so *i registers grow upwards 
    mov sp,0x7c00 ;stack grows down from here
    
    sti ;renable interupts

    mov byte[disk],dl ;save dl in [disk]
    mov eax,[bi_MBR_LBA]
    add dword[stage2_lba],eax


check_disk_ext:
    call disk_reset ;reset the disk to make sure its okay to use.
    mov ah,0x41 ;Function number for check extentions
    mov bx,0x55aa ;Should be reversed if extentions exist
    mov dl,byte[disk] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
     
disk_read_ext:
    mov ah,0x48 ;Extended disk parameters 
    mov dl,byte[disk] ;move disk no into dl  
    mov si,disk_struct ;ds:si = buffer
    mov byte[si],0x42 ;size of version 3.0 buffer

    int 0x13 ;;call interupt and fille disk_struct
    jc disk_read_no_ext ;;if somehow this errors read without ext
    xor dx,dx ;clear edx register 

    mov cx,word[disk_struct+0x18] ;calculate sector count again with extended features.

    mov ax,word[stage2_size] ;size of stage 2 
    div cx ;divide by cx
    cmp dx,0x00 ;cmp remainder to zero  
    je .skip_round ;if dx is zero dkip to 

    inc ax ;if dx is not zero increment sectors to read by one 

    .skip_round:
    push ax ;save sectors to read count
    call disk_reset ;reset the disk before read
    pop ax ;sector count to read really only al should have bytes set.
    push dword [stage2_lba+4];push the four higher bytes on to the stack
    push dword [stage2_lba];Push lower bytes on the stack
    push word 0x0000 ;segement to load stage 2 at 
    push word 0x8000 ;offset to load at 
    push word ax ;sectors to read
    push word 0x0010 ;size of dap 
    
    mov si,sp ;ds:si must point to dap
    mov dl,byte[disk] ;disk to read from 
    mov ah,0x42 ;call read interupts
    
    int 0x13 ;call interupt

    jnc attempt_boot ;if no error happened attempt boot
    ;If an error happened try again with CHS read (THOUGH this is unlikely to be needed)

;
; CHS is old and isn't used on any thing even remotely recent if 
; I need to FREE up space this is the first function to delete
; CHS just assumes 512 byte sectors 
; Not ideal but there doesn't seem to be
; a way to get it without ah=0x48
;
disk_read_no_ext:
    call disk_reset ;call reset disk function 
    mov eax,dword[stage2_lba+4] ;mov higher bytes of the LBA into eax 
    cmp eax,0x00 ;if the higher bytes of the LBA aren't 0
    jne read_error ;if it doesn't = 0 print read error we can't currently
    ;calculate a 48 bit LBA

    ;clear out all the registers we are going to use
    xor ecx,ecx 
    xor di,di ;es:di 0000:0000 to guard BIOS bugs

    mov ah,0x08 ;get drive parameter interupt no 
    mov dl,[disk] ;disk to get parameters for 
    int 0x13 ;call interupt 
    jc disk_error ;if carry flag set report read error 

    xor eax,eax ;clean eax register for use below
    ;LBA to CHS conversion formula take from here 
    ;https://www.viralpatel.net/taj/tutorial/chs_translation.php

    and cx,0x003f ;and out bytes we don't want/need (cyliander bytes)
    mov al,cl ;mov sector number into al 
    inc dh ;add one to drive per track count as function return (drive per track - 1)
    
    mul dh ;number of sectors per track * heads per track result
    mov ebx,eax ;move result into bx
    mov eax,dword[stage2_lba] ;move LBA into eax 
    xor edx,edx ;clear dx register to ovide errors 
    div ebx ;divide eax by ebx LBA / (heads_per_cyl * sects_per_track) 


    mov [abs_cyl],al ;move the lower 8bits into cyl count 
    shl ah, 6 ;shift the lower bits to take the highest 2 bits of the sector count
    mov [abs_sec],ah ;move the higher two bits into sec
    
    
    mov eax,edx ;move the remainder into eax
    xor edx,edx ;clear out dx register again 
    div ecx ;divide by the sectors per track  
    mov [abs_had],al ;store the result as head 
    inc dl ;add one to the sector count 
    or [abs_sec],dl ;store the sector count 
    
calculate_sectors:
    mov ax,word[stage2_size] ;move the size of stage2 into ax 
    mov cx,2048 ;size of disk sector assume 512 
    xor dx,dx ;clear out remainder register

    div cx ;divide size by 512 

    cmp dx,0x00 ;Check if DX = 0
    je .skip_rounding ;if remainder not set go straight to reading 
    
    inc ax ;if remainder is set increment by one sector

    .skip_rounding:
    mov dl, [disk] ;where we saved the BIOS disk number 
    mov bx, 0x8000 ;load stage 2 in here
    mov dh, [abs_had] ;Partition head number 
    mov cl, [abs_sec] ;Partition sector number 
    mov ch, [abs_cyl] ;Partition cyliander number 
    mov ah, 0x02 ;disk read and al is sectors to read 
    int 0x13 ;call interupt 
    jc read_error ;if carry flag is set jump to read error 
    
attempt_boot:
    xor dx,dx ;xor out dx 
    mov dl,byte[disk] ;mov disk no into dl 
    mov di,word[0x8018] ;get elf file entry point
    jmp di ;jmp to di in memory


disk_reset:
    xor ah,ah ;xor out ah for disk reset 
    mov dl,byte[disk] ;drive to reset 
    int 0x13 ;call interupt 
    jc disk_reset ;Jump if carry is set 
    ret ;return to callee function 

read_error:
    mov si,disk_error ;pointer to string to print 
    call print_str ;call print string function 

loop_end:
    cli ;clear interupts 
    hlt ;halt CPU 
    jmp loop_end ;jump to loop_end 

%include './stage1/print16.asm'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR data         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
abs_cyl: db 0x00 ;calculated absolute cyliander
abs_sec: db 0x00 ;calculated absolute sector 
disk: db 0x00 ;BIOS Boot Disk 
abs_had: db 0x00 ;calculated absolute head 
disk_error: db "Disk Err", 0x00 ;4 i
;constants of where the LBA and size of stage2 will be stored
times 0x190-($-$$) db 0x00 ;Used to postition these values at an absolute locations 0x190(stage2 LBA) & 0x198(Stage2 Size)
stage2_lba: dq 0x01 ;Default to LBA address 1(Sector 2) but fill out correctly at runtime
stage2_size: dw stage2_end - stage2 ;stage 2 is limited to 64K in size


times 2048-($-$$) db 0x00 ;pad with zeros to the 512 byte of the boot sector 

stage2:
incbin '../stage2.elf'

stage2_end:

