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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	ATA READ Function.				  ;
;	JOBS: read data into a memory buffer(rdi register);
;	INPUTS: 					  ;
;	RDI = read in buffer address			  ;
;	RAX = LBA 48 bit address			  ;
;	CX = sector count to read			  ;
;	bl is the head index and drive 	                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ata_read_lba:
    pushfq
    
    ;;Set the LBA address 
    mov dx, 0x01f3 
    out dx, ax

    inc dx
    shr rax, 16 ;shift bits to right 16 places
    out dx, ax
    
    inc dx 
    shr rax, 16 ;shift another 16 places 
    out dx, ax  

    mov dx,0x01f2
    mov ax,cx 
    out dx,ax	;read in cx number of sectors up to 65k odd
    

    mov dx,0x01f6
    or bl,11100000b ;Make sure the last bits are set and set them if they aren't while not touching the other bytes
    mov al,bl
    out dx,al ;Read drive from bl and head from bl   

    mov dx,0x01f7 ;Command port
    mov al,0x20 ;Read with retry.
    out dx,al ;send command

.still_going:   
    in al,dx
    test al, 0x08               ;the sector buffer requires servicing.
    jz .still_going         ;until the sector buffer is ready.

    mov rax,512/2           ;to read 256 words = 1 sector
    xor bx,bx
    mov bl,ch               ;read CH sectors
    mul bx
    mov rcx,rax             ;RCX is counter for INSW
    mov rdx,0x1f0            ;Data port, in and out
    rep insw                ;in to [RDI]

    popfq
    ret

