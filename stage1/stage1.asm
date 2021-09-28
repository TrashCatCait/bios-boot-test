[bits 16]
[org 0x600]

%define charmap 0x1000
;
; 16-bit code
;
stage1_start:
    cli 
    jmp 0x0000:init_cs ;reinitlize code seg

init_cs:
    xor ax,ax ;reinitlize all these to
    mov es,ax ;zero in case someone is
    mov ds,ax ;using this code from a
    mov ss,ax ;different MBR that hasn't
    mov fs,ax ;done this for us already
    mov gs,ax
    
    mov sp,0x7c00 ;reinitlize the stack here
    mov byte[disk],dl
    mov dword[part_offset],edi 

rip_vga_fonts: 
    push ds ;save original ds 
    push es ;save es = 0 onto stack
    mov bh, 0x06 ;offset pointer to get VGA fonts
    mov ax, 0x1130 ;bios VGA font interupt 
    int 0x10 ;call interupt 
    push es ;save segement of video font 
    pop ds ;ds = segement of video font 
    pop es ;restore es to zero 
    mov si,bp ;move offset of segement into si
    mov di,0x1000 ;move destination index here
    mov	cx,256*16/4 ;number of times to copy
    rep movsd ;move all fonts from ds:si to es:di
    pop ds ;restore ds 
    
init_video:
    mov ax,0x0013 ;bios mode 0x13 later if I have 
    ;the space free i may use VESA for bigger res
    int 0x10 ;call interupt to set video mode

    xor edx,edx ;empty out division register 
    mov eax,inode_count ;mov inode count into arthemitc reg 
    mov ecx,inodesper_group ;mov inodes per group into count reg 
    div ecx ;eax /ecx
    cmp edx,0x00 ;check for a remainder 
    je no_rounding ;if there isn't one skip rounding 
    
    inc eax ;eax now equals the number of block groups

no_rounding:
    mov dword[desc_count],eax
    
load_bgd:
    ;;Lets just auto assume that it's part of BGD 1 for now.
    mov edi,dword[part_offset];LBA to load 
    add edi,4
    mov ax,0x0000 ;segement to load to 
    mov bx,0x2000 ;where to load data to
    mov cx,0x02 ;sectors to load 
    mov dl,byte[disk]
    call read_disk
    
load_inode_tbl:
    mov eax,dword[0x2008]
    mov ecx, 1024
    mul ecx 
    mov ecx, 512 ;Take in the block address of the inode table
    div ecx ;covert it into an LBA to be added to offset
    

    mov edi,dword[part_offset]
    add edi,eax
    xor ax,ax
    mov bx,0x3000
    mov cx,0x0008 ;load in 8 sectors, 4 blocks, 4096 bytes 16 inode entries 
    ;so 0x3000 - 0x4000 equals the first 16 inode entries 
    mov dl,byte[disk]
    call read_disk

    mov eax,dword[0x3100]
    mov al,ah
    mov ah,0x0e
    mov bl,0x0f
    int 0x10


    
load_gdt:
    lgdt [gdtr32]
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp code32:pmode_start ;jumpt to 32bit code 

loop_end:
    cli
    hlt
    jmp loop_end

; 
; include code
;
%include './stage1/a20.asm'
%include './stage1/readdisk.asm'
%include './stage1/print16.asm'

;
; 16-bit Data
;
desc_count: dd 0 
disk: db 0x00 
part_offset: dd 0x0

;
; include data
;
%include './stage1/gdt32.asm'


[bits 32]
;
; 32-bit code section 
;
pmode_start:
    mov ax,data32 ;load in the kernel gdt data segement 
    mov ds,ax ;set all the segement register to this value
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov esp,0x90000

    jmp $

;
; 32-bit code includes
;
%include './stage1/print32.asm'

;
; 32-bit data section 
;

times 1022 - ($-$$) db 0x00
db 0x55, 0xaa

;Had a sorta good idea.
;Instead of referncing the superblock like
;[0x0eff] why don't i just build a structure with labels 
;down here but not write it to disk then I can refernce these labels
;while referncing the actual superblock at runtime.
;Saves me calculating the memory addresses I need manually.
;-Cait
inode_count: dd 0 ;number of inodes
block_count: dd 0 ;number of blocks
resvered_blocks: dd 0 ;resvered blocks in FS
unallocated_blocks: dd 0 
unallocated_inodes: dd 0 
superblock_block: dd 0 ;This is the superblocks block
log2_blocksize: dd 0 ;number to shift 1024 by to get blocksize
log2_fragsize: dd 0 ;number to shift 1024 by to get frag size
;For the previous shift left not right.
blocksper_group: dd 0 ;blocks count per group
fragsper_group: dd 0 ;fragments per group 
inodesper_group: dd 0 ;inodes per group 
mount_time: dd 0 ;last mount time in posix time
write_time: dd 0 ;last write time in posix time
mount_unsafe: dw 0 ;number of times the drive has been mounted without
;a consitencey check being preformed 
unsafe_max: dw 0 ;Number of times this may happen befor a check must
;be done
magic_sig: dw 0 ;magic signature
FSS: dw 0x00 ;file system state 
error: dw 0 ;what to do when an error happens 
min_ver: dw 0 ;minor portation add with major to get full version
check_time: dd 0 ;posix time of last consitencey check
interval: dd 0 ;time that can pass without a check 
OSID: dd 0 ;OS ID that the file system was made on
maj_ver: dd 0 ;major version count 
userid: dw 0 ;user id that can use reserved blocks 
groupid: dw 0 ;group id that can use reserved blocks

first_inode: dd 0 ;first non reserved inode 
inode_size: dw 0 ;sizeof(inode); 
superblock_group: dw 0 ;block group this superblock is part of
optional_features: dd 0 ;present 
required_features: dd 0 ;present 
readonly_features: dd 0 ;features that if not supported must be mount ro 
filesystemUUID: dq 0,0 ;UUID of this volume 
volume_name: dq 0,0 ;Name of this volume 
mount_pth: times 64 db 0x00 ;path of last mount location
compression: dd 0 ;compression algo used 
preallocatef: db 0 ;amount of blocks to preallocate for files
preallocated: db 0 ;amount for directorys 
reservedGDTent: dw 0 ;amount of GDT entries reserved for fs expansion
journalUUID: dq 0,0 ;journal UUID
journalinode: dd 0 
journaldevno: dd 0 
headorphan_ls: dd 0 
htreearray: dd 0,0,0,0
hashalgo: db 0 ;hash algorithm to use for dirs 
journalbup: db 0 ;journal blocks contains a copy of inode block array
groupdesc: dw 0 ;sizeof(group descriptor);
mountopts: dd 0 ;mount options
metablock: dd 0 ;first metablock if these are enabled 
creationtime: dd 0 ;creation time of FS
;The rest are 64bit features and likely aren't used. I may disable
;this in the FS creation command just to make sure as it's not like
;we can process these well even if they are populated like I'm still 
;in 16bit real mode.
