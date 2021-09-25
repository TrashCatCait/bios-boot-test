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




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR code         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_start:
    jmp after_bpb
    nop

    ;So according the Limine bootloader comments
    ;Some bioses will overwrite the section where the fat BPB would be.
    ;Potentially overwriting code if code is placed here. 
    ;So we are now zeroing this out and jumping after the bpb
    ;Slighlty annoying as I need to rework this bootloader.
    ;as it previous code was to big to fit now we can't use the bpb
    ;bytes - Cait.
    times 87 db 0x00 

after_bpb:
    cli ;clear interupts while we set up segement registers
    jmp 0x0000:set_cs ;far jump to set cs setting the code segement to 0

set_cs:
    xor ax,ax ;xor out ax and set all other segement 
    mov es,ax ;registers equal to zero
    mov ss,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
    
    cld ;clear the direction flag so *i registers grow upwards
    mov sp,0x7c00 ;stack grows down from here
    sti ;renable interupts
    call enableA20

load_gdt:
    lgdt [gdtr]
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp code32:pmode_start 
jmp $

checkA20:
    pushf ;push the flags to the site
    push ds ;Save current value of ds
    push es ;Save current value of es 
    pusha ;using pusha as it uses one less byte.
  
    
    xor ax, ax ; ax = 0
    mov es, ax ; can't set segment register directly

    not ax ; ax = 0xffff
    mov ds, ax ;ds = 0xffff 
    
    mov di, 0x0500 ;set ds and si to be
    mov si, 0x0510 ;exactly 1mb apart when combinded with es,ds

    mov al, byte [es:di] ;save the current bytes at these memory
    mov ah, byte [ds:si] ;locations may not be needed but also might be
    push ax ;If the BIOS or firmware place some data here though it's unlikely
    ;as it should be above the BIOS data area 

    mov byte [es:di], 0x00 ;Place our values in and then
    mov byte [ds:si], 0xFF ;compare to see if they are the same 
    cmp byte [es:di], 0xFF

    pop ax ;pop the original values off the stack
    mov byte [ds:si], ah ;put them back
    mov byte [es:di], al
    
    mov ax, 0 ;we use move to avoid setting the flags from xor 
    je checkA20.exit ;if the bytes are the same i.e. memory wrapped around we return 0
    
    mov ax, 1 ;If not we return one 

    .exit: ;pop all the registers and returm
        popa
        pop es 
        pop ds
        popf
        ret
    
enableA20:
    pusha 
    ;attempt the bios int a20
    mov ax, 0x2401
    int 0x15 
    
    cli ;;Done with interupts for now

    call checkA20 ;check a20 again to see if bios interupt worked 
    cmp ax, 0 ;check if ax is 0 
    jne enableA20.done ;if it's not got the end a20 is on 
    
    ;
    ;Next we try enabling it through the keyboard controller IO port
    ;This is legacy from when the port used to be on the keyboard controller 
    ;IO port as there was a pin spare
    ;

    call a20wait
    mov al, 0xAD
    out 0x64,al

    call a20wait
    mov al, 0xD0
    out 0x64,al
    
    call a20wait2
    in al, 0x60
    push eax
    
    call a20wait 
    mov al, 0xD1
    out 0x64, al

    call a20wait
    pop eax 
    or al, 2
    out 0x60, al

    call a20wait 
    mov al, 0xAE
    out 0x64, al
    

    ;
    ;Check the status of a20 again if it's on goto the end if not
    ;try the "fast" a20 gate
    ;
    call checkA20
    cmp ax, 0 
    jne enableA20.done

    ;;
    ;if a20 still isn't on after this disable an error
    ;Either the system doesn't support it or it uses some other 
    ;a20 setting method I don't know about
    ;;
    in al, 0x92
    or al, 2
    out 0x92, al
    call checkA20
    cmp ax, 0 
    jne enableA20.done
    
    hlt
    jmp $

    .done:
        popa
        ret

;Wait for input ports to be ready before attempting to input data 
a20wait:
    in al, 0x64
    test al,2
    jnz a20wait
    ret

a20wait2: 
    in al,0x64
    test al,1 
    jz a20wait2
    ret


[bits 32]
pmode_start:
    mov ax,data32 
    mov es,ax ;registers equal to zero
    mov ss,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax

    mov byte[0xb8000], 'j' ;confirmed 32bit launch but need to go out
    ;shopping for for
    jmp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;          MBR data         ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gdt:
.start:

.null:
    dq 0 ;declear the null segement

.kercode:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10011010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high


.kerdata:
    dw 0xffff ;limit low
    dw 0x0000 ;base low 
    db 0x00 ;base medium
    db 10010010b ;access byte 
    db 11001111b ;flags + limit high
    db 0x00 ;base high

.end:

gdtr:
    dw gdt.end - gdt.start - 1 ;gdt size - 1 byte
    dd gdt.start ;gdt's start offset

code32 equ gdt.kercode - gdt.null ;we can now reference the code segement with code32 label
data32 equ gdt.kerdata - gdt.null ;same as above for data 



times 510-($-$$) db 0x00
db 0x55, 0xaa
