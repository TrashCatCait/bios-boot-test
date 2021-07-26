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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      Execution Start      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boot_start: ;technically unused but nice for my brain
    ;clear interupts before we clear the segement registers
    cli

    ;set up stack
    mov bp, 0x7c00 ; stack grows downwards from here
    mov sp, bp ; aka away from our mbr code 

    xor ax,ax
    mov ss,ax
    mov es,ax
    mov ds,ax
    mov gs,ax

    sti
    mov [bootdrive], dl;save dl in here
    add bp, 494 ;bp now points to last partition in table
    call video_init
    call clear_screen
    jmp print_part_labels
    jmp loop_end ;0xf0 -> stack


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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Print PT          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
print_part_labels:
    mov cx, 4 ;number of times to loop equals partition table entrys
    xor bx,bx ;we want this to be 0
    
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
;       MBR Routines        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
main_menu:
    mov dx, rows + 6 + cols
    add dh, bl
    call cursor_pos

    mov ah, 0x00
    int 0x16

    cmp al, 0x77 
    je moveup

    cmp al, 0x73
    je movedown
    
    cmp al, 0x0D
    je boot 

jmp main_menu

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR Boot         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boot:
    mov [chosenpart], bl ;move the chosen partition into here

    xor dx,dx 

    call cursor_pos
    call clear_screen

    mov bp, 0x7c00 + 430
    xor bx,bx ;make sure bh is zero
    mov bl, [chosenpart] ;restore bl original value 
    shl bl, 4 ;times partition by 16
    add bp, bx ; then add it to bp



; OKAY rant time this function disk_read annoyed me so much as it kept returning disk error
; it returned invalid parameter and as far as I could see the values where as far 
; as I know correct. However I eventually got frustraded wrote the MBR to a USB drive
; and rebooted my computer to the MBR on the USB and it didn't display the error
; instead went on to do jmp loop_end. So my first plan was to not implement LBA
; disk reading until later. But I'm going to work on this now as to see if this method 
; works on qemu emulator as I don't wish to reboot my PC every time to test.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Disk Read         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disk_read:
    mov ax, 0x0201 ;read 1 sector 
    mov bx, 0x8000 
    mov dl, [bootdrive] ;Saved disk id
    mov dh, [bp+01] ;Drive head is stored here.
    mov cl, [bp+02] ;Drive sector
    mov ch, [bp+03] ;Drive cyliander 

    int 0x13

    jc read_error



jmp loop_end

read_error:
    mov si, disk_error
    call print_str
    jmp loop_end

movedown:
    cmp bl, 0x01
    je movedown.skip
    dec bl
    .skip:
    jmp main_menu

moveup:
    cmp bl, 0x04
    je moveup.skip
    inc bl 
    .skip:
    jmp main_menu


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;      Data & strings       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
chosenpart: db 0 
bootdrive: db 0 
partstr: db "Partition *", 0x00 ;6
disk_error: db "Disk Err", 0x00 ;4  
code_error: db "Invalid Partition", 0x00
options: db "w-up | s-down | space-shutdown", 0x00 ;15


;Fill code segement of MBR with 0x00
;440 is the end of the code segement  
times 440 - ($ - $$) db 0x00 

;pad NT disk signature and two padding bytes
times 6 db 0x00

;pad partition table
times (4 * 16) db 0x00


db 0x55, 0xaa ;Magic bios boot number
