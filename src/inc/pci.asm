; Only relavent to access mode #1 not used in #2     
; PCI port 0x0cf8 config port 
; access mode #1 layout 
;  bits  |  desc
; --------------- 
; 31 	enable bit ; boolean 
; 30 - 24 	reserved ; reserved 7 bits 
; 23 - 16 	PCI bus number ; 8 bits in length
; 15 - 11 	PCI device number ; 5 bits in length 
; 10 - 8 	PCI Function ; 3 bits in length (Used for multifunction devices)
; 7 - 0	Register offset ; 8 bits select which register of the 256 byte config to read
;
; PCI port 0x0cfc data port
; 32 bit port prints the registers at Register offset
; So Vendor ID and Device ID at offset 0x00 
;
; Only relavent to access mode #2 not used in 1 
; port 0x0cf8 config port 
; 7 - 4 	key 0 = access mechnism disabled. not(0) = enabled
; 3 - 1 	PCI function number
; 0 	Special cycle enabled if set
; 
; port 0x0cfa forwarding register 8 bit register selects PCI bus
; ports 0xc000 - 0xcfff access PCI configuration space
; 15 - 12 	must be 1100b
; 11 - 8 	dev num
; 7 - 2	Register index
; 1 - 0	must be zero

;
; we are just using acess mekanism 1 for now
; as that's all my PCs and VMS support. Will work on 2 later
;

;read PCI register 
;Input eax = PCI device and register to read
;output eax = PCI register contents
read_pci_reg:
    or eax, 0x80000000
    mov dx, 0x0cf8
    out dx, eax

    mov dx, 0x0cfc
    in eax, dx
    ret
