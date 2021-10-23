[bits 32]
section .text 
    global isr_table
    global load_idt
    extern exception_handler
    extern isr32_handler
    extern isr33_handler
    
    
%macro isr_err 1
isr%+%1:
    pop eax 
    push ebp,
    mov ebp,esp
    push eax 
    call exception_handler 
    mov esp,ebp 
    pop ebp 
    iretd
%endmacro 

%macro isr_no_error 1
isr%+%1:
    xor eax,eax 
    push ebp
    mov ebp,esp 
    push eax
    call exception_handler
    mov esp,ebp
    pop ebp
    iretd 
%endmacro

align 4
;
; currently exceptions that sends error codes and those that don't do the
; same actions but these are seperated in case I want to add different behaviour
; between them also not sure if I should implement one exception handler 
; that handles all exception or just each exception has it's own
;
isr_no_error 0
isr_no_error 1
isr_no_error 2
isr_no_error 3
isr_no_error 4 
isr_no_error 5
isr_no_error 6
isr_no_error 7
isr_err 8
isr_no_error 9
isr_err 10
isr_err 11
isr_err 12
isr_err 13
isr_err 14
isr_no_error 15
isr_no_error 16
isr_err 17
isr_no_error 18
isr_no_error 19 
isr_no_error 20
isr_no_error 21
isr_no_error 22
isr_no_error 23
isr_no_error 24
isr_no_error 25
isr_no_error 26
isr_no_error 27 
isr_no_error 28 
isr_no_error 29 
isr_err 30
isr_no_error 31

isr32:
    push ebp,
    mov ebp,esp 
    pushad
    call isr32_handler
    popad
    mov esp,ebp 
    pop ebp
    iretd

isr33:
    push ebp
    mov ebp,esp 
    pushad
    call isr33_handler
    popad
    mov esp,ebp
    pop ebp
    iretd


;generate rep number of entries
isr_table:
%assign i 0 
%rep    34
    dd isr%+i 
%assign i i+1 
%endrep

load_idt:
    push ebp
    mov ebp,esp
    mov edi,[ebp+8]
    lidt [edi]
    sti
    pop ebp
    ret

