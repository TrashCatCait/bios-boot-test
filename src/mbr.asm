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
;   This project is simply a chain loader it does    ;
;   nothing to ensure A20, GDT or anything else is   ;
;   set up it assumes the bootloader will do that    ;
;   The purpose of this is to allow multiboot on MBR ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 16]
[org 0x7c00]


; $$ - section start = org 0x7c00
; $ - current pos
; ($ - $$)

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
    
    ;Clear segement regs
    xor ax, ax
    mov ss, ax
    mov es, ax
    mov gs, ax
    mov ds, ax
    mov fs, ax 
    ;Set up stack 
    ;Stack technically will grow towards our mbr code.
    ;This isn't an issue as we won't be pushing a lot to stack 
    ;so we should never go that low
    mov sp, 0x7c00

    push dx ;save dl
    
 
    ;copy code to 0x600
    mov si, 0x7c00 ;Current MBR pos 
    mov di, 0x0600 ;destination 
    mov cx, 0x0200 ;copy 512bytes
    cld ;clear direction grow upwards not downwards
    rep movsb
    

    ;;Jmp to 0x600+(mbr_main-0x7c00)
    ;;Aka jump to mbr_code in the copied code
    jmp 0x0000:0x0600+(mbr_main-$$)
    

mbr_main:
    sti
    

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
        ;mov si, options
        ;call print_str
setup_menu:
    ;set up menu to position one
    mov bl, 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Menu Loop         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
menu_loop:
    xor dx,dx 
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
    mov [0x600+chosenpart-$$],bl
    xor dx,dx
    call cursor_pos
    call clear_screen

    ;Basically set up BP to point at our chosen partition
    ;Put stuff in for reading
    mov bl, [0x600+chosenpart-$$]
    xor bh,bh  
    shl bl, 4 
    mov bp, 0x600 + 430 
    add bp, bx
    
    ;[bp] should = offset 0 of pt table 
    ;[bp] set to disk to save it 
    pop dx
    mov [bp], dl


check_ext:
    mov ah, 0x41 ;Function number for check extentions
    mov bx, 0x55aa ;Should be reversed if extentions exist
    mov dl, [bp]
    int 0x13

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext
    jc disk_read_no_ext ;technically checking bx should cover this but just in case
    
    mov dl,[bp]
    jmp disk_read_ext

disk_reset:
    mov ah, 0x00
    mov dl, [bp]
    int 0x13
    jc disk_reset
    
    ret 


disk_read_ext:
    call disk_reset

    mov dl, [bp]
    mov ah, 0x42
    
    push dword 0x00 ;push dword into zero 
    push dword [bp+0x08] ;Starting absolute sector read from PT table
    push word 0x00 ;Segement and offset 
    push word 0x7c00 ;read into 0x0000:0x7c00 
    push word 0x0001 ;Sectors to read
    push word 0x0010 ;DAP size 
    
    mov si, sp ;ds:si must point to DAP ds = 0 from program start and dap is on top of the stack
    int 0x13
    
    add sp,0x10

    jc read_error
    jmp check_vbr

disk_read_no_ext:
    call disk_reset
    
    mov bx, 0x7c00
    mov dl, [bp]
    mov dh, [bp+1]
    mov cl, [bp+2]
    mov ch, [bp+3]
    mov ax, 0x0201 
    int 0x13
    jc read_error
    
check_vbr:
    cmp word [es:0x7c00], 0x0000 
    je invalid_part
    cmp word [es:0x7dfe], 0xaa55
    jne invalid_part

attempt_boot:
    ;Removed this as it's not on screen long enough to see as far as I can tell
    ;It's not really on screen long enough to see.
    ;mov si,0x0600+(booting-$$)
    ;call print_str
    xor dx,dx 
    xor bx,bx
    mov bx,[bp+0x08]
    mov dl,[bp]
    jmp 0x0000:0x7c00

invalid_part:
    ;Not 100% sure whats going on but I think I understand. This didn't print after I read the code to 0x7c00
    ;I think it must have something to do with org 0x7c00 so the label code_error is like for example at position 0x7c*
    ;Not referencing the new location of 0x06**
    mov si, 0x0600+(code_error-$$)
    call print_str
    jmp loop_end


read_error:
    ;Not sure this has to be position independant but just in case
    mov si, 0x600+(disk_error-$$)
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
; swapped using boot drive to use stack instead along with chose part
;bootdrive: db 0
chosenpart: db 0
partstr: db "Partition *", 0x00 ;6
;options: db "w-up | s-down | enter-select", 0x00 ;14
disk_error: db "Disk Err", 0x00 ;4 
;;Shortened to part to save bytes 
code_error: db "Invalid Part", 0x00

times 440-($-$$) db 0x00 

times 6 db 0x00

times 64 db 0x00

db 0x55, 0xaa 

