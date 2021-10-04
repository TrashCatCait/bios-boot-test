[bits 64]
section .text 
;
;	all these functions should be called from C
;	ARG1 = RDI
;	ARG2 = RSI
;	Return Value = RAX
;
out_byte:
    mov dx,di ;mov lower 16 bits of RDI into dx to serve as port No.
    mov ax,si ;mov second arg aka data to send to port to ax
    out dx,al ;output byte(al) into port(dx)
    retq ;return to C code having send data

out_word:
    mov dx,di ;mov lower 16 bits of RDI into dx to serve as port No.
    mov ax,si ;mov second arg aka data to send to port to ax
    out dx,ax ;output word(ax) into port(dx)
    retq ;return to C code having send data

out_dword:
    mov dx,di ;mov lower 16 bits of RDI into dx to serve as port No.
    mov eax,esi ;mov second arg aka data to send to port to ax
    out dx,eax ;output dword(eax) into port(dx)
    retq ;return to C code having send data

in_byte:
    mov dx,di ;move lower 16 bits of RDI into dx to serve as port No.
    xor ax,ax ;clear out return register
    in al,dx ;read in byte 
    retq ;return byte to C code 

in_word:
    mov dx,di ;move lower 16 bits of RDI into dx to serve as port No.
    xor ax,ax ;clear out return register
    in ax,dx ;read in word 
    retq ;return word to C code 

in_dword:
    mov dx,di ;move lower 16 bits of RDI into dx to serve as port No.
    xor eax,eax ;clear out return register
    in eax,dx ;read in word 
    retq ;return word to C code 

hlt_c:
    hlt 
    retq 

clear_interupts:
    cli  ;clear interupts(disable hardware interupts)
    retq ;return to C code  

set_interupts:
    sti  ;set interupts(enable hardware interupts)
    retq ;return to C code 

wait_io: 
    push ax ;Save value of register 
    xor al,al ;xor it 
    out 0x80, al ;out to 0x80
    pop ax ;pop the original value 
    retq

;This function should never return 
;and should be used if an horrible error occurs that
;we can't recover from
kernel_hang:
    cli ;clear hardware interupts 
    hlt ;halt CPU 
    jmp kernel_hang ;if NMI occurs jump back to hangloop

;make them all global so we can define and use them in C code
global out_byte 
global out_word
global out_dword

global in_byte 
global in_word
global in_dword

global hlt_c
global clear_interupts 
global set_interupts 
global wait_io

global kernel_hang

