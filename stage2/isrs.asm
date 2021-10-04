section .text 
    global isr_table
    extern exception_handler
    extern isr32_handler
    extern isr33_handler
    
    

%macro pushaq 0
    push rax
    push rbx
    push rcx
    push rdx
%endmacro

%macro popaq 0
    pop rax
    pop rbx
    pop rcx
    pop rdx
%endmacro

%macro isr_err 1
isr%+%1:
    pushaq
    mov rdi, %+%1
    call exception_handler 
    popaq
    iretq 
%endmacro 

%macro isr_no_error 1
isr%+%1:
    pushaq
    mov rdi, %+%1
    call exception_handler
    popaq 
    iretq 
%endmacro

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
    pushaq
    call isr32_handler
    popaq
    iretq

isr33:
   pushaq
   call isr33_handler
   popaq
   iretq


;generate rep number of entries
isr_table:
%assign i 0 
%rep    34
    dq isr%+i 
%assign i i+1 
%endrep

