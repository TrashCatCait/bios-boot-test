section .text 

setup_vesa:
    call get_edid  
    
    sti
    
    push es 
    mov ax,0x4f00
    mov di,vbe_info
    int 0x10
    pop es

    cmp ax,0x004f ;check ah for function fail bits and al for function supported
    jne .failed ;if not equal jump to failed check 
    
    mov ax,word[vbe_info.vid_mod_ptr]
    mov word[vid_off],ax ;save video offset
    mov ax,word[vbe_info.vid_mod_ptr+2]
    mov word[vid_seg],ax ;save video segement 

    mov si,[vid_off]
    mov ax,[vid_seg]
    mov gs,ax ;gs:si now = real mode ptr to supported video modes 

.loop_mode:
    mov cx,word[gs:si] ;move current mode into cx
    add si,2 ;move si to next mode
    mov [vid_off],si ;save si into here incase register gets trashed.
    mov word[cur_mode],cx ;save currently process mode
    
    cmp word[cur_mode],0xffff ;end of list 
    je .failed ;if yes goto fail 
    
    push es ;I've been told some BIOS can trash the es value so save it just in case  
    mov ax,0x4f01 ;get video mode infomation
    mov cx,word[cur_mode] ;move cur_mode back into cx
    mov di,mode_info ;output buffer of where to put mode_info
    int 0x10 ;call interupt 
    pop es 
    
    cmp ax,0x004f 
    jne .failed 

    mov ax,word[pref_x] ;move preffered x res into ax
    cmp ax,[mode_info.xres] ;compare it to the current modes x res 
    jne .next_mode ;if they aren't equal loop back 

    mov ax,[pref_y] ;same procedure but with y res 
    cmp ax,[mode_info.yres]
    jne .next_mode
    
    mov al,0x08 ;check the color depth at the moment we only allow for 8 bit color 
    cmp al,[mode_info.bpp]
    jne .next_mode
    
    ;if we get here we have found a mode with the right x,y and color depth 
    push es
	mov ax, 0x4f02 ;set video mode call 
	mov bx, [cur_mode] ;set bx to the current mode 
    or bx,0x4000 ;or the bit for the linear framebuffer 
    xor di,di ;xor di es:di should = 0 to combat potential buggy bios 
    int 0x10
    pop es
 
	cmp ax, 0x004F ;check if the mode set successfully  
	jne .failed ;if it didn't don't update the framebuffer information  
    
    mov eax,[mode_info.baseptr] 
    mov dword[frmbfr],eax ;set the base ptr 
    
    xor eax,eax ;clear out registers for maths 
    xor edx,edx 
    xor ecx,ecx

    mov ax,[mode_info.xres]
    mov cx,[mode_info.yres]

    mov word[frmbfr+4],cx ;mov y res into field 
    mov word[frmbfr+6],ax ;mov x res into field 
    mov word[frmbfr+12],ax
    
    mul ecx ;multiple ecx by eax to get the size of the buffer 
    
    mov dword[frmbfr+8],eax ; move the size of the buffer into here 

    xor ax,ax
    mov gs,ax ;reset gs 
    ret 

.next_mode:
    mov ax,[vid_seg] ;re set gs:si 
    mov gs,ax ;to be video modes pointer 
    mov si,[vid_off] ;this is just in case a buggy bios wiped these(though that shouldn't happen) 
    jmp .loop_mode

.failed:
    xor ax,ax
    mov gs,ax ;reset gs back to 0 
    mov si,verror ;move error string into si 
    mov bl,0x0f ;color to print 
    call print_str ;call print string 
    xor ax,ax ;keboard wait for input number
    int 0x16 ;wait for keyboard input 
    stc
    ret


get_edid:
    mov ax,0x4f15
    mov bl,0x01
    xor cx,cx
    xor dx,dx
    mov es,dx ;es = 0 
    mov di,0x3000 ;destination buffer for Mointor EDID
    int 0x10
   
    xor ax,ax
    mov al,byte[es:0x3038]
    mov dl,byte[es:0x303a]
    and dx,0xf0
    shl dx,4
    or dx,ax
    mov word[pref_x],dx

    xor ax,ax
    xor dx,dx
    mov al,byte[es:0x303b]
    mov dl,byte[es:0x303d]
    and dx,0xf0
    shl dx,4 
    or dx,ax
    mov word[pref_y],dx
    ret

section .data
pref_y: dw 0x0000
pref_x: dw 0x0000 
bpp: db 0x08
vid_off: dw 0x0000
vid_seg: dw 0x0000 
cur_mode: dw 0x0000 
verror: db "Unable to set vesa video mode, Reverting to VGA 320x200. Press any key to continue...",0x00

vbe_info: 
    .signature: db "VBE2";
    .vbe_ver: dw 0x0000
    .oem_str_ptr: dw 0x0000, 0x0000
    .capabilities: dw 0x0000, 0x0000
    .vid_mod_ptr: dw 0x0000, 0x0000
    .table_data: times 512 - 22 db 0x00;
    
mode_info:
    .attr: dw 0x0000 ;mode attr 
    .winaattr: db 0x00
    .winbattr: db 0x00
    .wingran: dw 0x0000
    .winsize: dw 0x0000
    .winaseg: dw 0x0000
    .winbseg: dw 0x0000 
    .funcptr: dd 0x0000
    .bytespsl: dw 0x0000

    .xres: dw 0x0000
    .yres: dw 0x0000
    .xchar: db 0x00
    .ychar: db 0x00 
    .numofplanes: db 0x00
    .bpp: db 0x00
    .bankc: db 0x00 
    .memmodel: db 0x00
    .banksz: db 0x00 
    .imgpagec: db 0x00 
    .res1: db 0x00

    .redmask: db 0x00 
    .redfield: db 0x00 
    .greenmask: db 0x00 
    .greenfield: db 0x00
    .bluemask: db 0x00
    .bluefield: db 0x00 
    .rsmask: db 0x00 
    .rsfield: db 0x00
    .dccolor: db 0x00

    .baseptr: dd 0x0000
    .res2: dd 0x0000 
    .res3: dw 0x0000 

    .linbpersl: dw 0x00
    .bnknoimgs: db 0x00
    .linnoimgs: db 0x00 
    .linredmsk: db 0x00
    .linredfild: db 0x00
    .lingrnmsk: db 0x00
    .lingrnfld: db 0x00
    .linblumsk: db 0x00 
    .linblufld: db 0x00 
    .linrsmsk: db 0x00
    .linrsfld: db 0x00
    .maxpixcl: dd 0x0000
    .res4: times 189 db 0x00
