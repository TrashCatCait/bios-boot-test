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
;	ATA LBA READ Function.				  ;
;	JOBS: read data into a memory buffer(rdi register);
;	INPUTS: 					  ;
;	rdi = read in buffer address			  ;
;	rax = LBA 48 bit address			  ;
;	cx = sector count to read			  ;
;	bl is the head index and drive 	                  ;
;	dx = the base port address of the ATA device	  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[bits 64]	

;
;  Right now this is a VERY basic set up it doesn't account for a lot of possiblitys
;  Drive being busy, Data not being on the first disk, etc... 
;  I need to think of ways to solve these issues which I'll do at a later date
;

;;
;write high bytes then low bytes
;so 4->5->6->1->2->3
;Sectors high bytes then low bytes then execute read commnad


ata_read_lba:
    push rbp
    mov rbp,rax
    
    add dx, 2 ;Sector count port
    mov al, ch ;Mov value here to be outputted
    out dx, al ;higher byte of sector
    
    mov rax, rbp ;lba in here
    
    ;LBA 4 and LBA 3 now in ah,al
    bswap eax 
    inc dx
    out dx,al 

    shr rax,32 ;LBA 5 and 6 in ah(6),al(5)
    
    ;LBA 5 out 
    inc dx
    out dx, al
    
    ;LBA 6 out 
    inc dx
    mov al, ah
    out dx, al

    mov al,cl ;Sector count low
    sub dx,3 ;minus 3 from dx to sector port
    out dx,al ;sector count low bytes
    
    ;restore RAX
    mov rax, rbp
    
    ;LBA 1 & 2 are in ah(2) and al(1)
    ;LBA 1 out 
    inc dx
    out dx,al
    
    ;LBA 2 out 
    inc dx
    mov al,ah
    out dx,al

    ;LBA 3 out
    bswap eax  
    inc dx 
    mov al,ah
    out dx,al

    inc dx
    or bl, 01000000b ;These bits must be set master/slave bit to be set by user
    mov al, bl 
    out dx, al
    
    inc dx ;Command port
    mov al,0x24 ;Read Extended 
    out dx,al ;send command

.buffer_service: 
    in al,dx
    test al, 0x08 ;DRQ bit set?
    jz .buffer_service ;until the sector buffer is ready.
    
    mov rax, 0x100 ;0x100 = 256 words half of a sector 
    push dx
    mul cx ;Multiply this by the sector count to read 
    mov rcx, rax ;Move result into times to repeat
    pop dx 
    sub dx, 7 ;set DX to data port of the drive
    rep insw ;read in a single word to [rdi] 
    pop rbp
    ret

