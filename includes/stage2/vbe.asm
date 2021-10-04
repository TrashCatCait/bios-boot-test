vbe_info: 
    .signature: db "VBE2";
    .vbe_ver: dw 0x0000
    .oem_str_ptr: dw 0x0000, 0x0000
    .capabilities: dw 0x0000, 0x0000, 0x0000, 0x0000
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
