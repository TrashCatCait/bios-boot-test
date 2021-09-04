;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ATA Notes:												    ;
;	OS-Dev-Wiki-Notes: https://wiki.osdev.org/ATA
;	ata_io-Docs: http://www.controllersandpcs.de/ataio/code_snippets.pdf
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ATA Ports:
;	Primary Command Ports: 0x01f0 - 0x01f7 
;	Primary Control Port: 0x03f6 - 0x03f7
;	Secondary Command Ports: 0x0170 - 0x0177
;	Secondary Control Port: 0x0376 - 0x0377
;	Ternary Command Ports: 0x01e8 - 0x01ef
;	Ternary Contol Port: 0x03ee - 0x03ef 
;	Quaternary Command Ports: 0x0168 - 0x016f 
;	Quaternary Control Ports: 0x0036 - 0x0036
;;
;;
;;
;	ATA Port:	R/W:	Description:
;	------------------------------------
;	0x0**0/8	R/W	Data Register. Bytes are written / read here
;	0x0**1/9	R	Error Register. Can't be written to but can read error codes
;	0x0**2/a	R/W	Sector Count Register. How many sectors to read
;	0x0**3/b	R/W 	Sector Number Register/LBA Low Register
;	0x0**4/c	R/W	Cylinder Low Number/LBA Mid Register
;	0x0**5/d	R/W	Cylinder High Number/LBA High Register
;	0x0**6/e	R/W	Drive/Head Select Register
;					bit 0 to 3 = Head Selector Bits
;					bit 4 = Master/Slave drive select
;					bit 5 = always set(1)
;					bit 6 = Use CHS if unset or use LBA if bit set
;					bit 7 = always set(1)
;	0x0**7/f	R/W	When read it's a status register/When written it's a command register 
;					Status Bits:
;		                              bit 7 = 1  Busy Bit
;		                              bit 6 = 1  drive is ready
;               		              bit 5 = 1  write fault
;               		              bit 4 = 1  seek complete
;		                              bit 3 = 1  sector buffer requires servicing
;		                              bit 2 = 1  disk data read corrected
;		                              bit 1 = 1  index - set to 1 each revolution
;		                              bit 0 = 1  previous command ended in an error
;					Commands:
;					      https://wiki.osdev.org/ATA_Command_Matrix
;	0x03*6/e	R/W	Alternate status register or control register on write commands
;					bit 0 = always zero  
;					bit 1 = nIEN set this bit to stop the device from throwing interupts
;					bit 2 = Set then clear after 5us. This performs a software reset on disks
;					bit 3 to 6 = reserved
;					bit 7 = Set to read back the high order byte of last LBA48 value sent to IO
;	0x03*7/f	R/W	Drive Address Register
;					bit 0 = Drive 0 select. Clears when drive 0 selected 
;					bit 1 = dido the above for drive 1 
;					bit 2 to 5 = ones compliment reprsentation of the current head
;					bit 6 = Write Gate goes low/unset when drive is being written to.
;					bit 7 = reserved for backwards compatiablity with floppy drive controllers
;
;;

[bits 64]
;
; INPUTS:
; RAX = 48 bit LBA Address 
; BL = Drive Head and Selector Register 
; CX = Sector Count 
; RDI = Buffer To Read Into 
; DX = Base Legacy ATA Register 
; 
; OUTPUT(s):
; On success = data will be written to memory at RDI 
; On failure = carry flag(CF) is set and al has an error code

ata_read:
    push rax ;save the LBA address 

;Check if ata bus returns 0xff assume it doesn't exist if 
;it does return 0xff
.present:
    add dx,7 ;Move to ATA status port
    in al,dx
    cmp al,0xff ;check if the bus is floating. 
    je ata_read.failure ;if not 0xff jump to rest of read
    cmp al, 0x00 ;also known to cause problems with empty CD drives
    je ata_read.failure
    ;will work on implementing a better method to deal with this


;48bit PIO read function
.lba48:
    push rcx 
    ;1f0 
    sub dx,7
    ;1f2
    add dx,2 ;point dx to the sector port
    mov al,ch;move high byte of sector 
    out dx,al;output the higher sector count 
    
    pop rcx 
    pop rax ;restore the value of LBA into rax
    push rcx
    
    mov rbp,rax ;save original LBA into rbp

    bswap eax ;LBA 4 and 3 now in ah(3) and al(4)
    mov ch,ah;save LBA 3 into ch as we no longer need ch
    ;1f3
    inc dx ;point DX to the sector number/LBA low port
    out dx,al ;output LBA 4 into port

    shr rax,32 ;ah(LBA 6), al(LBA 5)
    ;1f4
    inc dx ;point dx to cylinder low port
    out dx,al ;output LBA5 to port  
    
    mov al,ah ;mov LBA6 into al
    inc dx ;increment dx to 0x01*5
    out dx,al ;output LBA 6
    ;1f2 
    sub dx,3 ;sector count port 
    mov al,cl ;sector count low byte 
    out dx,al ;output to port

    mov rax,rbp ;restore LBA 
    ;1f3
    inc dx ;point back at the port 
    out dx,al ;output LBA 1 
    ;1f4 
    inc dx ;LBA mid port 
    mov al,ah ;mov LBA2 in al 
    out dx,al ;output LBA 2 
    
    inc dx ;increment dx
    mov al,ch ;restore LBA 3 from where we stored it
    out dx,al ;output LBA 3 to LBA high
    
    inc dx
    mov al,bl
    out dx,al

    inc dx ;Command port
    mov al,0x24 ;Read Extended 
    out dx,al ;send command
.buffer_service:
    in al,dx
    test al,0x01 
    jnz .error
    test al,0x08 ;DRQ bit set?
    jz .buffer_service ;until the sector buffer is ready.
    pop rcx
    mov rax, 0x100 ;0x100 = 256 words half of a sector 
    
    push dx ;save dx as it's over written by mul 
    mul cx ;Multiply this by the sector count to read 
    mov rcx, rax ;Move result into times to repeat
    pop dx  ;restore DX 
    
    sub dx, 7 ;set DX to data port of the drive
    rep insw ;read in a single word to [rdi] 
    jmp ata_read.done

;if read fails set the carry flag and return
.error:
    sub dx,6
    in al,dx
    jmp $
.failure:
    pop rax
    stc ;set the carry flag  

.done:
    ret ;return 

;
;calculate FAT32 LBAS
;This assumes the fat VBR is located at 0x7c00
;
calc_lba:
    sub eax, 0x0002 ;clusters start at 2 so zero out the number
    xor cx,cx 
    mov cl, byte[0x7c0d] ;mov sectors per cluster to cl
    mul cx ;ax now equal previous value * cx
    add eax, dword[0x7df8] ;ax now equals previous + FATDATA sector
    add ax, word[0x7dfc]
    ret

