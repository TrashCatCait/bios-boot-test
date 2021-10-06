;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   BIOS MBR sector 0.                               ;
; This MBR is intented to be used on a hard disk/usb ;
; Please don't use it on a CD-ROM as they have 2048  ;
; bytes per sector not 512 and this could lead to    ;
; many errors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 16]
[org 0x7c00]


; $$ - section start = org 0x7c00
; $ - current pos
; ($ - $$)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Definations        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR code         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
    jmp after_bpb
    nop

    ;So according the Limine bootloader comments
    ;Some bioses will overwrite the section where the fat BPB would be.
    ;Potentially overwriting code if code is placed here. 
    ;So we are now zeroing this out and jumping after the bpb
    ;Slighlty annoying as I need to rework this bootloader.
    ;as it previous code was to big to fit now we can't use the bpb
    ;bytes - Cait.
    times 87 db 0x00 

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
    
    mov ax,word[stage2_size]
    mov cx,512
    xor dx,dx ;clear out remainder register

    div cx ;divide size by 512 ;we assume this is the sector size

    cmp dx,0x00 
    je check_disk_ext ;if remainder not set go straight to reading 
    
    inc ax 

check_disk_ext:
    push ax
    mov ah,0x41 ;Function number for check extentions
    mov bx,0x55aa ;Should be reversed if extentions exist
    mov dl,byte[disk] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
     
disk_read_ext:
    call disk_reset 
    pop ax ;sector count to read really only al should have bytes set.
    push dword [stage2_lba+4];push the four higher bytes on to the stack
    push dword [stage2_lba];Push lower bytes on the stack
    push word 0x1000 ;segement to load stage 2 at 
    push word 0x0000 ;offset to load at 
    push word ax ;sectors to read
    push word 0x0010 ;size of dap 
    
    mov si,sp ;ds:si must point to dap
    mov dl,byte[disk]
    mov ah,0x42
    
    int 0x13 ;call interupt

    jnc attempt_boot

disk_read_no_ext:
    call disk_reset ;call reset disk function 
    mov eax,dword[stage2_lba+4] ;mov higher bytes of the LBA into eax 
    cmp eax,0x00 ;if the higher bytes of the LBA aren't 0
    jne read_error ;if it doesn't = 0 print read error we can't currently
    ;calculate a 48 bit LBA

    ;clear out all the registers we are going to use
    xor ecx,ecx
    xor di,di 

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
    
    pop ax
    mov bx,0x1000
    mov es,bx 
    xor bx,bx ;Where to load the VBR 
    mov dl, [disk] ;where we saved the BIOS disk number 
    mov dh, [abs_had] ;Partition head number 
    mov cl, [abs_sec] ;Partition sector number 
    mov ch, [abs_cyl] ;Partition cyliander number 
    mov ah, 0x02 ;disk read and al is sectors to read 
    int 0x13 ;call interupt 
    jc read_error ;if carry flag is set jump to read error 
    
attempt_boot:
    jmp 0x1000:0x1000

disk_reset:
    xor ah,ah
    mov dl,byte[disk]
    int 0x13
    jc disk_reset
    ret
read_error:
    mov si,disk_error 
    call print_str ;call print string function 

loop_end:
    cli
    hlt
    jmp loop_end

%include './stage1/print16.asm'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR data         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
abs_cyl: db 0x00 ;calculated absolute cyliander
abs_sec: db 0x00 ;calculated absolute sector 
disk: db 0x00 ;BIOS Boot Disk 
abs_had: db 0x00 ;calculated absolute head 
disk_error: db "Disk Err", 0x00 ;4 
;constants of where the LBA and size of stage2 will be stored
times 0x190-($-$$) db 0x00
stage2_lba: dq 1
stage2_size: dw 0x0010 ;stage 2 is limited to 64K in size

times 510-($-$$) db 0x00
db 0x55, 0xaa
