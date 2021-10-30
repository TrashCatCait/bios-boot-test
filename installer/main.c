#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h> 


void print_help() {
    printf("Installer.elf:\nUSAGE: ./installer [-hmbdplo]\n");
    printf("Option Descriptions:\n");
    printf("-h Displays this help message\n-m path to mbr file to flash to mbr\n-b path to bootloader file to flash\n-d device to flash to\n-p GPT partition number to place bootloader in\n-l legacy mode for dos disk");
    printf("Example: ./installer -m mbr.bin -d /dev/sdx -b stage2.elf -p 2");
}

int main(int argc, char **argv) {
    //File Pointers defined but not opened 
    FILE *stage2file;
    FILE *diskdevice;
    FILE *mbr;

    uint8_t usingmbr = 0;
    unsigned short magic = 0xaa55;
    uint64_t LBA = 0; 
    uint64_t offset = 0;
    int marg = 0, darg = 0, barg = 0, parg = 0;

    for(int arg = 1; arg < argc; arg++) {
        if(argv[arg][0] == '-') {
            switch(argv[arg][1]) {
                case 'h':
                    print_help();
                    exit(1); //exit after printing help
                case 'l':
                    usingmbr = 1; //set legacy MBR true
                    break;
                case 'm':
                    marg = arg + 1; 
                    break;
                case 'd':
                    darg = arg + 1;
                    break;
                case 'b':
                    barg = arg + 1;
                    break;
                case 'p': 
                    parg = arg + 1;
                    break;
                default:
                    printf("Unknow option passed quitting\nOption %s\n", argv[arg]);
                    exit(1);
            }
        }
    }
    //check if enough arguements where provided 
    if((parg == 0 && !usingmbr) || barg == 0 || darg == 0 || marg == 0) {
        print_help();
        exit(1); //if not enough args given exit 
    }

    stage2file = fopen(argv[barg],"rb"); 
    if(stage2file == NULL){
        printf("Error Opening Stage 2 file, %s", argv[barg]);
        exit(1);
    }
   
    diskdevice = fopen(argv[darg],"r+b");
    if(diskdevice == NULL){
        printf("Unable to open disk device %s", argv[darg]);
        exit(1);
    }

    mbr = fopen(argv[marg],"rb"); 
    if(mbr == NULL){
        printf("Unable to open MBR file %s", argv[marg]);
        exit(1);
    }
    fseek(stage2file, 0l, SEEK_END);
    unsigned short sz = ftell(stage2file); //Get 16bit size of file 
    fseek(stage2file, 0, SEEK_SET);
    
    if(usingmbr) {
        LBA = 1;
    } else { 
        uint8_t partition = atoi(argv[parg]);
        fseek(diskdevice, 0x420+(0x80*(partition-1)), SEEK_SET);
        
        fread(&LBA, 8, 1, diskdevice);
    }
    //Set up and write the MBR Code to the disk image 
    fseek(diskdevice, 0x00, SEEK_SET);
    for(int i = 0; i <= 436; i++) {
        char byte = 0;
        fread(&byte, 1, 1, mbr);
        fwrite(&byte, 1,  1, diskdevice);
    }

    fseek(diskdevice, 0x198, SEEK_SET); //File Size 
    fwrite(&sz, 1, 2, diskdevice); //Write the file size to MBR 
    fseek(diskdevice, 0x190, SEEK_SET); //LBA offset 
    fwrite(&LBA, 1, 8, diskdevice); //write 64bit LBA address to MBR 
    fseek(diskdevice, 0x1fe, SEEK_SET); //Offset of Magic boot no
    fwrite(&magic, 1, 2, diskdevice); // write BIOS magic num

    //Write stage2 to offset LBA * 0x200
    fseek(diskdevice, (LBA+offset)*0x200, SEEK_SET);
    for(int i = 0; i <= sz; i++) {
        char byte = 0;
        fread(&byte, 1, 1, stage2file);
        fwrite(&byte, 1, 1, diskdevice); 
    }
    
    fclose(mbr);
    fclose(stage2file);
    fclose(diskdevice);
}
