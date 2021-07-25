[org 0x7c00]
[bits 16]
;Stage one jobs enable A20
;load stage 2
;get to 32 bit mode
;check CPUID and Long mode
;call stage 2 main function

STAGE2 equ 0x9000

_start: ;start execution here 
    mov [BOOT_DISK], dl
    mov bp, 0x7c00 
    mov sp, bp ;set up stack base and pointer
        ;first thing we do is read our bootloaders second stage. this is because BIOS loads the bootdisk into the dl registor
    call read_disk
    call checkA20
    cmp ax, 0
    je _start.a20off
    
    .a20off:
    call enableA20
        
    .a20on:
    jmp toprotected
    jmp $

printr:
    pusha 
    mov ah, 0x0e

    .real_loop:
        lodsb
        cmp al, 0x00
        je .real_done
        int 0x10
        jmp .real_loop
    .real_done:
        popa 
        ret

%include './a20.asm'
%include './stage1gdt.asm'
%include './diskread.asm'

diskerror: db "Err Disk", 0x00 

a20error: db "Err A20", 0x00

[bits 32]
%include './cpuid.asm'
%include './stage1print.asm'
protectedmode:
    mov ax, dataseg
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
    
    mov ebp, 0x90000;New stack above video mem 
    mov esp, ebp

    mov edi, 0xb8000
    mov eax, 0x1f201f20
    mov ecx, 1000
    rep stosd 
    call checkcpuid
    jmp 0x9000
    hlt


;data
longerror: db "Err Long", 0x00

times 510-($-$$) db 0x00

db 0x55, 0xaa
