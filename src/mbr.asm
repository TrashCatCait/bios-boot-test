;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   BIOS MBR sector 0.                               ;
;   1) Job read Partition table on the disk          ;
;   2) Find bootable partitions (if any exist)       ;
;   3) Display all valid bootable partitions         ;
;   4) Allow the users to pick one.                  ;
;   5√a) boot to the selected disk                   ;
;   6√a) if an error occurs while boot goto root 5√b ;
;   5√b) If read error occurs inform the user.       ;
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
%define textoffset 0x0028 ;Text offset loaded in DX when setting cursor befor print  
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
    mov ds, ax
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
    rep movsb ;move single byte to 0x0600
    

    ;;Jmp to 0x600+(mbr_main-0x7c00)
    ;;Aka jump to mbr_code in the copied code
    jmp 0x0000:0x0600+(mbr_main-$$)
    

mbr_main:
    sti ;renable interupts
    
    mov ax, videomode ;Vidoe mode 3 (80x25, 4bit colors)
    int 0x10 ;call interupts 
    
    mov ax, cursormode ;Set cursor int
    mov cx, curshape ;lines to display
    int 0x10 ;call interupt 
    
    call clear_screen

;
;   Print Partition Table 
;
print_pt: 
    mov bp, 0x600 + 494 ;Base pointer = new code start + partition 4 byte 0 offset
    mov cx, 4 ;Number of times to loop = size of partition table 
    xor bx, bx ;clear bx and bl

partition_loop:
    ;;Number six may seem random but is half of the string
    ;;length we are printing the purpose of this is to center
    mov dx, textoffset - 6 ;use values defined above to compute
    add dh, cl ;Move down by the number of rows = to partition 
    call cursor_pos ;set cursor
    
    mov si, partstr ;move the memory address of partition string 
    ;Replace place holder char with digit char
    mov byte[si + 10], cl ;move the current partition number 
    add byte[si + 10], 0x30 ;add the ascii code for '0' to get the number in char format
    call print_str ;print the string 
    
    cmp byte[bp], 0x80 ;check if the active byte is set to 0x80 
    jne skip_active ;if it isn't set to 0x80 skip printing the active character and setting bl

    mov bl, cl ;set bl to the first partition in the table with the active byte set
    ;previously we just set bl to 1 by default now BL will equal the first partition with 
    ;the active byte set. So now if shift isn't pressed on boot it will boot the first partition
    ;with the active byte set and not just attempt to boot partition 1 even though it may not be active

    mov ax, 0x0e2a ;print star char
    int 0x10 ;call print interupt 

skip_active:
    sub bp, 16 ;next entry 
    loop partition_loop ;loop partition_loop code cx number of times

partition_done:
    mov dx, 0x051a ;Set the cursor pos 
    call cursor_pos ;call function 
    mov si, options ;key guides
    call print_str ;call function 

setup_menu:
    ;set up menu to position one
    mov bl, 0x01
    mov ah, 0x02 ;int 0x16 get keyboard status  
    int 0x16 ;Call int 
    
    and al, 0x03 ;mask all statuses we don't care about.
    cmp al, 0x00 ;Check if either shift key is pressed
    je boot ;If neither shift key is pressed jump straight to boot 

;If not allow the user the option to select
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;         Menu Loop         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
menu_loop: 
    mov dx, textoffset + 6 ;move cursor onto currently selected partition
    add dh, bl ;add partition number 
    call cursor_pos ;call cursor position function
    
    mov ah, 0x00 ;BIOS get key function 
    int 0x16 ;call interupt 

    cmp al, 0x77 ;if w key is pressed 
    je moveup ;move menu up 

    cmp al, 0x73 ;if s key is pressed 
    je movedown ;move menu down 

    cmp al, 0x0d ;if enter key is selected
    je boot ;jump to boot with bl set to current menu 
    
jmp menu_loop ;if we get here loop back to the top

;
; read vbr and setup 
;

boot: 
    shl bl, 4 ;shift bl(selected partition) by 4 bits to the left
    mov bp, 0x7ae ;Move base pointer to just before the first partition table entry 
    add bp, bx ;add the new value of bx to bp current value so 0x7ae + (Partition Num * 16)
    ;Now BP is pointing to our selected partition
    
    xor dx, dx ;dx = 0  
    call cursor_pos ;set the cursor to dx
    call clear_screen ;clear the screen

    ;[bp] should = offset 0 of pt table 
    ;[bp] set to disk to save it 
    pop dx ;pop dx off the stack from when we saved it 
    mov [bp], dl ;Use the value of dl which is now the BIOS boot disk
    ;NOTE: if your BIOS doesn't pass this value this bootloader won't work

check_ext:
    mov ah, 0x41 ;Function number for check extentions
    mov bx, 0x55aa ;Should be reversed if extentions exist
    mov dl, [bp] ;move the BIOs disk into dl
    int 0x13 ;call interupt 

    cmp bx, 0xaa55 ;If reversed continue else jump
    jne disk_read_no_ext ;if bx does not equal 0xaa55 or carry flag is set we assume
    jc disk_read_no_ext ;extended disk read is not supported and just use regular CHS values.
    

disk_read_ext:
    call disk_reset ;call reset disk function

    mov dl, [bp] ;mov the value of [bp] BIOS boot disk into dl
    mov ah, 0x42 ;BIOS extended read function interupt number 
    
    push dword 0x00 ;push dword into zero 
    push dword [bp+0x08] ;Starting absolute sector read from PT table
    push word 0x00 ;Segement and offset 
    push word 0x7c00 ;read into 0x0000:0x7c00 
    push word 0x0001 ;Sectors to read
    push word 0x0010 ;DAP size 
    
    mov si, sp ;ds:si must point to DAP ds = 0 from program start and dap is on top of the stack
    int 0x13 ;call interupt 

    jc read_error ;if carry flag is set jump to the read error label

    add sp, 0x10 ;add ten bytes to the stack pointer to clean out the DAP values we saved

    jmp check_vbr ;jump to checking VBR

;;;;;NOTE
;I know this currently doesn't work on qemu
;But it seems to work on all hardware I've run it on.
;So if you run this on hardware and it doesn't work
;That would be good to know
disk_read_no_ext:
    call disk_reset ;call reset disk function 
    
    mov bx, 0x7c00 ;Where to load the VBR 
    mov dl, [bp] ;where we saved the BIOS disk number 
    mov dh, [bp+1] ;Partition head number 
    mov cl, [bp+2] ;Partition sector number 
    mov ch, [bp+3] ;Partition cyliander number 
    mov ax, 0x0201 ;disk read and al is sectors to read 
    int 0x13 ;call interupt 
    jc read_error ;if carry flag is set jump to read error 

check_vbr:
    cmp word [es:0x7c00], 0x0000 ; check if the code is empty 
    je invalid_part ;if it does equal zero print invalid part 
    cmp word [es:0x7dfe], 0xaa55 ;Check if disk signature is there 
    jne invalid_part ;if it does not have the signature jump to invalid part

attempt_boot:
    xor dx, dx ;clear out dx reg  
    mov bx, [bp+0x08] ;move the Partitions LBA in to bx and pass it 
    mov dl, [bp] ;move BIOS disk identifier into dl
    jmp 0x0000:0x7c00 ;jmp to the VBR

invalid_part:
    mov si, 0x0600+(code_error-$$) ;org 0x7c00 used we have to make this position independant
    call print_str ;call print string function
    jmp loop_end ;jump endlessly 


read_error:
    ;Not sure this has to be position independant but just in case
    mov si, 0x600+(disk_error-$$) ;org 0x7c00 is used we have to make this position independant
    call print_str ;call print string function 
    jmp loop_end ;jump endlessly 

;
; Menu Controls 
;

movedown:
    cmp bl, 0x04 ;if menu is on partition 4 aka maximum partition entry
    je movedown.skip ;skip going down anymore and jump back to menu loop
    inc bl ;if it's not increament bl by one 
    .skip: 
    jmp menu_loop ;Jump back to menu_loop 

moveup:
    cmp bl, 0x01 ;if menu is on partition 1 aka minimum  entry 
    je moveup.skip ;skip going up anymore 
    dec bl ;dec bl if its not already on the minum
    .skip:
    jmp menu_loop ;jump back to menu loop 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       MBR Functions       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This was with other disk functions but save 2 bytes.
;Through being able to cut out a jmp command  
disk_reset:   
    mov ah, 0x00 ;mov BIOS disk reset number into ah 
    mov dl, [bp] ;BP should have been overwritten with BIOS disk No
    int 0x13 ;call interupt 
    jc disk_reset ;if an error happended reset the disk again 
    ret ;return 


clear_screen: ;clear the screen and make it blue 
    mov ax, 0x0600 ;ah = 0x06 bios scroll up 0x00 means clear_scr
    mov bh, 0x1f   ;fourground background
    xor cx, cx     ;start column and row ch,cl
    mov dx, 0x184f ;end row and column; row:24 col:79
    int 0x10 ;call interupt
    ret ;return 

loop_end: ;loop endlessly
    cli ;clear interupts 
    hlt ;halt processor until NMI happens(if one happens)
    jmp loop_end ;Jump back to loop end

print_str:
    mov ah, 0x0e ;interupt for bios print
    
    str_loop:
        lodsb ;load single byte into al
        cmp al, 0x00 ;check if al = 0 
        je str_end ;goto string end 
        int 0x10 ;call interupt
        jmp str_loop ;loop again 
    str_end:
        ret ;return 

;set dx before call
cursor_pos:
    mov ah, 0x02 ;set cursor pos for int 0x10 
    int 0x10 ;call interupt 
    ret ;return 

;
; DATA and padding
; swapped using boot drive to use stack instead along with chose part
;bootdrive: db 0
;chosenpart: db 0
options: db "w-up | s-down | enter-boot", 0x00 ;13
partstr: db "Partition *", 0x00 ;6
disk_error: db "Disk Err", 0x00 ;4 
;;Shortened to part to save bytes 
code_error: db "Inv Part", 0x00

times 440-($-$$) db 0x00 

times 6 db 0x00

times 64 db 0x00

db 0x55, 0xaa 

