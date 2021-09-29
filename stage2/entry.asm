[bits 32]

;
;   Okay so this is a little funky because this is technically a
;   x86_64 elf executeable but we load in here at 32 bit then.
;   jump to 64bit mode this is done here as though I could, 
;   attempt to cram all this into stage1 I couldn't do it well
;   with good error checking. - Caitcat 
;


;
; 32bit code 
;

global _start

_start:
    cli
    pop eax ;pop 32bit framebufferpointer off the stack 
    mov dword[bufferptr],eax ;save it here as the stack isn't going survive the jump to 64 bit 
    pop eax ;pop 32bit ptr to the memory map 
    mov dword[mmap_ptr],eax
    call checkcpuid ;check the CPU is a 64bit CPU 
    call enablepaging ;setup idenitity paging for the first two megabytes

load_long:
    lgdt [gdt64_pointer]
    jmp 0x0008:long_start

hltloop:
    cli
    hlt
    jmp hltloop


%include './stage2/print32.asm'
%include './stage2/paging.asm'
%include './stage2/cpuid.asm'
;
; 32 bit data
;
cpuiderr: db "cpuid not supported", 0x00
longerror: db "long mode error",0x00
bufferptr: dd 0x0000000
mmap_ptr: dd 0x0000000 
%include './stage2/gdt64.asm'


[bits 64]
extern stage2_start

long_start:
    mov ax,0x10
    mov es,ax
    mov ds,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov rsp,0x90000 ;reset the stack to 0x90000 just bellow the framebuffer 
    cli
    xor rdi,rdi ;clear the upper bits of the rdi(arg1) registers
    xor rsi,rsi
    mov edi,dword[bufferptr] ;set the lower 32bits to the bufferptr value
    ;essentially this in C
    ;uint64_t framebuffer_ptr = (uint64 *) framebuffer32_ptr
    ;now we have a pointer to the framebufferstructure in 64bits
    mov esi,dword[mmap_ptr]

    cli
    call stage2_start ;call C code 
    jmp $ ;we should never get he but loop endlessly if we do 

