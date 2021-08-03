;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   BIOS MBR sector 0.                               ;
;   1) Job read Partition table on the disk          ;
;   2) Find bootable partitions (if any exist)       ;
;   3) Display all valid bootable partitions         ;
;   4) Allow the users to pick one.                  ;
;   5√a) boot to the selected disk                   ;
;   6√a) if an error occurs while boot goto root 6√b ;
;   5√b) If read error occurs inform the user.       ;
;   6√b) and set a timer for restarting              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[org 0x7c00]
[bits 16]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;        Definations        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;change below to change offsets of printed text
;row is timesed by 0x100 as it's the higher bytes in ah
%define rows (0x00 * 0x100) ;row offset 
%define cols 40 ;cols offset  
;These are defined here to make them easier to change and swap out
%define color 0x1f ;blue back | white front
%define videomode 0x0003 ;Video mode we want 
%define curshape 0x0107 ;Cursor shape
%define cursormode 0x0103 ;cursor set mode

mbr_start:
    cli 
    ;Set up stack 
    ;Stack technically will grow towards our mbr code.
    ;This isn't an issue as we won't be pushing a lot to stack 
    ;so we should never go that low
    mov bp, 0x7c00
    mov sp, bp
    
    ;Clear segement regs
    xor ax, ax
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov ds, ax
    
    push dx ;save dl

    ;copy code to 0x600
    mov si, 0x7c00 ;Current MBR pos 
    mov di, 0x0600 ;destination 
    mov cx, 0x0200 ;copy 512bytes
    cld ;clear direction grow upwards not downwards
    rep movsb
    
    push ax ;CS = 0000
    push mbr_main ;location to return to should be 0x0600 + however many bytes this uses
    retf ;far return to set code segement and goto new code start 

mbr_main: 
    sti
    
    pop dx 
    mov [bootdrive],dl

    call video_init 
    call clear_screen
    jmp print_pt      
    jmp loop_end ;shouldn't ever land here but just in case 

;
;   Print Partition Table 
;
print_pt: 
    mov bp, 0x600 + 494 ;Base pointer = new code start + partition 4 byte 0 offset
    mov cx, 4 ;Number of times to loop = size of partition table 
    xor bx,bx

    partition_loop:
        ;;Number six may seem random but is half of the string
        ;;length we are printing the purpose of this is to center
        mov dx, rows + (cols - 6) ;use values defined above to compute
        add dh, cl ;Move down by the number of rows = to partition 
        call cursor_pos
        
        mov si, partstr
        ;Replace place holder char with digit char
        mov byte[si + 10], cl
        add byte[si + 10], 0x30
        call print_str
        
        cmp byte[bp], 0x80
        jne skip_active
        mov ax, 0x0e2a ;print star char
        int 0x10

    skip_active:
        sub bp, 16 ;next entry 
        loop partition_loop

    partition_done:
        mov dx, 0x0518
        call cursor_pos
        mov si, options
        call print_str
setup_menu:
    ;set up menu to position one
    mov bl, 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Menu Loop         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
menu_loop:
    mov dx, rows + 6 + cols 
    add dh, bl 
    call cursor_pos
    
    mov ah, 0x00 
    int 0x16

    cmp al, 0x77
    je moveup

    cmp al, 0x73 
    je movedown

    cmp al, 0x0d
    je boot

jmp menu_loop

;
; read vbr and setup 
;

boot: 
    mov [chosenpart], bl 

disk_read: 
    mov ah, 0x00
    mov dl, [bootdrive]
    int 0x13 ;reset the boot disk
    clc
    xor dx,dx

    call cursor_pos
    call clear_screen
    
    xor bx,bx 
    mov bl, [chosenpart]
    shl bl, 4 
    mov bp, 0x600 + 430 
    add bp, bx

    mov ax, 0x0201 
    mov bx, 0x7c00
    mov dl, [bootdrive]
    mov dh, [bp+1]
    mov cl, [bp+2]
    mov ch, [bp+3]

    int 0x13
    
    jc read_error
    
attempt_boot: 
    mov si, booting
    call print_str
    jmp 0000:0x7c00

jmp loop_end


read_error:
    mov si, disk_error
    call print_str
    jmp loop_end

;
; Menu Controls 
;

movedown:
    cmp bl, 0x04
    je movedown.skip
    inc bl
    .skip:
    jmp menu_loop

moveup:
    cmp bl, 0x01
    je moveup.skip
    dec bl 
    .skip:
    jmp menu_loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       MBR Functions       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
video_init: ;set up video and cursor 
    mov ax, videomode ;Vidoe mode 3 (80x25, 4bit colors)
    int 0x10 ;call interupts 
    
    mov ax, cursormode ;Set cursor int
    mov cx, curshape ;lines to display
    int 0x10
    ret 

clear_screen: ;clear the screen and make it blue 
    mov ax, 0x0600 ;ah = 0x06 bios scroll up 0x00 means clear_scr
    mov bh, 0x1f   ;fourground background
    xor cx, cx     ;start column and row ch,cl
    mov dx, 0x184f ;end row and column; row:24 col:79
    int 0x10 
    ret

loop_end: ;loop endlessly
    cli
    hlt
    jmp $

print_str:
    pusha
    mov ah,0x0e    ;interupt for bios print
    
    str_loop:
        lodsb ;load single byte into al
        cmp al,0x00 ;check if al = 0 
        je str_end ;goto string end 
        int 0x10 
        jmp str_loop ;loop again 
    str_end:
        popa
        ret 

;set dx before call
cursor_pos:
    mov ah, 0x02
    int 0x10 
    ret

;
; DATA and padding
;
bootdrive: db 0
chosenpart: db 0
partstr: db "Partition *", 0x00 ;6
options: db "w-up | s-down | space-shutdown", 0x00 ;15
disk_error: db "Disk Err", 0x00 ;4  
code_error: db "Invalid Partition", 0x00
booting: db "Booting...", 0x00

times 440-($-$$) db 0x00 

times 6 db 0x00

times 64 db 0x00

db 0x55, 0xaa 

