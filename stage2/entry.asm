[bits 16]

;16bit x86 code plan is we start he do VBE to try and initlize actually colors not just a color pallet and a decent size screen. (this will obvisually be relative the monitor but anything is better than 320x200 tbh)
section .text
global _start

_start:
    mov ax,0x1000 
    mov es,ax ;segement for gdtr to be loaded with
    mov ds,ax
    ;mov ss,ax ;wait no this will mess the stack up. stack is still at 0x7c00
    mov fs,ax
    xor ax,ax
    mov gs,ax ;use gs to refer to things in segement 0 

arguements: 
    pop eax
    mov dword[es:(bufferptr-0x10000)],eax ;store this variable for later use in 64bit mode
    pop eax
    mov dword[es:(mmap_ptr-0x10000)],eax ;store this variable for later use in 64bit

setup_vbe:
    mov ax,0x4f00
    mov di,(vbe_info-0x10000)
    int 0x10 
    cmp ax,0x004f
    jne no_vesa
    
    mov si,[es:(vbe_info.vid_mod_ptr-0x10000)]
    mov bx,[es:(vbe_info.vid_mod_ptr-0x10000)+2]

vesa:
    ;currently we just try this default mode that probably won't even be 
    ;supported in a lot of modern hardware. But later I'll try scanning through
    ;the video ptr to try and find a better mode.
    mov cx,0x4100 ;vesa 640x400 video mode code 0x4000 to set up linear framebuffer 
    mov ax,0x4f01 ;vesa get info function 
    mov di,mode_info-0x10000 ;es:di = buffer to fill with mode information 
    int 0x10 ;call interupt 
    
    mov bx, 0x4100 ;Vesa 640x400 w linear buffer 
    mov ax, 0x4f02
    int 0x10
    cmp ax,0x004f ;al = 4f if function is supported ah = 0 if function succeds
    jne no_vesa
    
    ;VESA mode found and set up. Change Framebuffer values to match it.
    mov byte[es:vesa_on-0x10000], 1 ;set vesa on to one
    mov ebx,dword[es:bufferptr-0x10000] ;move dword pointer into ebx -> frambuffer
    mov eax,dword[es:(mode_info.baseptr-0x10000)] ;move the base ptr into eax 
    mov dword[gs:bx],eax ;set the physical address to the framebuffers physical addr 
    ;update height with VESA mode height 
    mov ax,word[es:(mode_info.yres-0x10000)]
    mov word[gs:bx+8],ax
    
    ;update scanline and width 
    mov ax,word[es:(mode_info.xres-0x10000)]
    mov word[gs:bx+10],ax
    mov word[gs:bx+16],ax
    
    ;clean out the registers I'll be using for calculating size of buffer
    xor eax,eax
    xor ecx,ecx
    xor edx,edx

    mov ax,word[gs:bx+8] ;mov height into ax
    mov cx,word[gs:bx+10] ;mov width into cx 
    mul ecx ;multiple height(eax) by width(ecx)

    mov dword[gs:bx+12],eax ;mov the result into size field of frambff

    jmp load_gdt

no_vesa:
    mov si,vesa_err-0x10000
    call print_str

    xor ax,ax
    int 0x16 

load_gdt:    
    lgdt [es:(gdtr32-0x10000)]
    mov eax, cr0 ;move cr0 into eax 
    or eax, 1 ;set bit one 
    mov cr0, eax ;put it back
    jmp dword 0x08:pmode_start ;jump to 32bit code 

%include './stage1/print16.asm'
;%include './debug.asm'
;
; 16bit data 
;

;bare bones structure to be filled at run time
section .data
vesa_err: db "Desired Vesa mode unsupported. Reverting to 320x200...", 0x00
vesa_on: db 0 ;used to deterimine if Vesa is set up 
%include './stage2/vbe.asm'
%include './stage1/gdt32.asm'


[bits 32]
section .text
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

pmode_start:
    cli
    mov ax,data32
    mov es,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax 
    mov ss,ax 
    mov esp,0x90000
    
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

section .data 
;
; 32 bit data
;
cpuiderr: db "cpuid not supported", 0x00
longerror: db "long mode error",0x00
bufferptr: dd 0x0000000
mmap_ptr: dd 0x0000000 
%include './stage2/gdt64.asm'


[bits 64]
section .text 
extern stage2_start

long_start:
    cli
    mov ax,0x10
    mov es,ax
    mov ds,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    mov rsp,0x90000 ;reset the stack to 0x90000 just bellow the framebuffer 
    
    xor rdi,rdi ;clear the upper bits of the rdi(arg1) registers
    xor rsi,rsi
    mov esi,dword[mmap_ptr]
    mov edi,dword[bufferptr] ;set the lower 32bits to the bufferptr value
    ;essentially this in C
    ;uint64_t framebuffer_ptr = (uint64 *) framebuffer32_ptr
    ;now wehave a pointer to the framebufferstructure in 64bits

    jmp stage2_start ;call C code 

