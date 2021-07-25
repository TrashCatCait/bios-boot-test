
;This comment is here for my own sanity as in my test env
;sector 2048 = first partition
;1b8 onwards is the first partition number 
;start of partition 
;0x20, 0x21, 00 (H, S, C)
;0x20 - 32 dec   C    S
;0x21 - 33 dec - 00 100001

;end of partition
;0x5f, 0x19, 0x06 (H, S, C)
;0x5f - 95 head  C     S
;0x19 - 25 -     00 0110001 
;0x06 - 6 - 0000 0110

;LBA 
;start 
;00 08 00 00 reverse because little endian
;0x0800
;number of sectors
;00 88 01 00 reverse beacasue smol endian
;0x018800 = 100352 in decimal times this by
;512 to get 50Mb in bytes yay my math works
[bits 16]
read_disk:
sti
;Reset the disk
mov ah, 0x00 
int 0x13

mov ah, 0x02
mov al, 0x01
mov ch, 0x20 
mov cl, 0x21
mov dh, 0x00
mov dl, [BOOT_DISK]
mov bx, STAGE2
int 0x13 
jc read_fail
ret


read_fail:
    mov si, diskerror 
    call printr
    jmp $

BOOT_DISK: 
db 0
