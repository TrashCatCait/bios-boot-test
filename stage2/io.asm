[bits 32]
section .text 


out_byte:
    push ebp
    mov ebp,esp
    mov al,byte[ebp+0x0c]
    mov dx,word[ebp+0x08]
    out dx,al  
    pop ebp
    retn ;return to C code having send data

in_byte:
    push ebp
    mov ebp,esp
    mov dx,word[ebp+0x08]
    in al,dx 
    pop ebp 
    ret 

out_word:
    push ebp
    mov ebp,esp
    mov ax,word[ebp+0x0c]
    mov dx,word[ebp+0x08]
    out dx,al  
    pop ebp
    retn ;return to C code having send data

in_word:
    push ebp
    mov ebp,esp
    mov dx,word[ebp+0x08]
    in ax,dx 
    pop ebp 
    ret 

out_dword:
    push ebp
    mov ebp,esp
    mov eax,dword[ebp+0x0c]
    mov dx,word[ebp+0x08]
    out dx,al  
    pop ebp
    retn ;return to C code having send data

in_dword:
    push ebp
    mov ebp,esp
    mov dx,word[ebp+0x08]
    in eax,dx 
    pop ebp 
    ret 

hlt_c:
    hlt 
    ret 

clear_interupts:
    cli  ;clear interupts(disable hardware interupts)
    ret ;return to C code  

set_interupts:
    sti  ;set interupts(enable hardware interupts)
    ret ;return to C code 

wait_io: 
    push ebp
    mov ebp,esp 
    xor al,al ;xor it 
    out 0x80, al ;out to 0x80
    pop ebp
    ret

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


