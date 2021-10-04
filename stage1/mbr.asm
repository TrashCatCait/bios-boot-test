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
    mov bp, 0x7c00 + 446 ;hard coded to read pt 1 this will change in future but works for now
    mov [bp],dl ;save dl in [bp]

check_disk_ext:
    mov ah, 0x41 ;Function number for check extentions
    mov bx, 0x55aa ;Should be reversed if extentions exist
    mov dl, [bp] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jnc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
    
disk_read_ext:
    call disk_reset ;call reset disk function

    mov dl, [bp] ;mov the value of [bp] BIOS boot disk into dl
    mov ah, 0x42 ;BIOS extended read function interupt number 
    
    push dword 0x00 ;push dword into zero 
    push dword [bp+0x08] ;Starting absolute sector read from PT table
    push word 0x0000 ;Segement and offset 
    push word 0x0600 ;read into 0x0000:0x0600 
    push word 0x0004 ;Sectors to read
    push word 0x0010 ;DAP size 
    
    mov si, sp ;ds:si must point to DAP ds = 0 from program start and dap is on top of the stack
    int 0x13 ;call interupt 

    jc read_error ;if carry flag is set jump to the read error label

    add sp, 0x10 ;add ten bytes to the stack pointer to clean out the DAP values we saved
    jmp check_vbr
;;;;;NOTE
;I know this currently doesn't work on qemu
;But it seems to work on all hardware I've run it on.
;So if you run this on hardware and it doesn't work
;That would be good to know
disk_read_no_ext:
    call disk_reset ;call reset disk function 
    
    ;clear out all the registers we are going to use
    xor ecx,ecx
    xor di,di 

    mov ah,0x08 ;get drive parameter interupt no 
    mov dl,[bp] ;disk to get parameters for 
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
    mov eax,[bp+0x08] ;move LBA into eax 
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

    xor bx,bx
    mov es,bx ;es can be modified when this function is run on a floopy disk we want to make sure it's back at zero as this can effect where we load our data in

    mov bx, 0x0600 ;Where to load the VBR 
    mov dl, [bp] ;where we saved the BIOS disk number 
    mov dh, [abs_had] ;Partition head number 
    mov cl, [abs_sec] ;Partition sector number 
    mov ch, [abs_cyl] ;Partition cyliander number 
    mov ax, 0x0204 ;disk read and al is sectors to read 
    int 0x13 ;call interupt 
    jc read_error ;if carry flag is set jump to read error 

check_vbr:
    mov ax,word[0x0a00-2]
    cmp ax,0xaa55
    jne vbr_error 
    cmp word[0x0600],0x0000
    je vbr_error 
    mov dl,[bp]
    mov edi,dword[bp+0x08]
    jmp 0x0600 

vbr_error:
    mov si,invalid_part 
    call print_str 
    jmp loop_end 

disk_reset:   
    mov ah, 0x00 ;mov BIOS disk reset number into ah 
    mov dl, [bp] ;BP should have been overwritten with BIOS disk No
    int 0x13 ;call interupt 
    jc disk_reset ;if an error happended reset the disk again 
    ret ;return 

read_error:
    mov si,disk_error 
    call print_str ;call print string function 
    jmp loop_end ;jump endlessly 

%include './stage1/print16.asm'

loop_end:
    cli
    hlt
    jmp loop_end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR data         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
abs_cyl: db 0x00 
abs_sec: db 0x00
abs_had: db 0x00
disk_error: db "Disk Err", 0x00 ;4 
invalid_part: db "VBR Err",0x00

times 510-($-$$) db 0x00
db 0x55, 0xaa
