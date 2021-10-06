#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    //File Pointers defined but not opened 
    FILE *stage2file;
    FILE *diskdevice;
    FILE *mbr;
    unsigned short magic = 0xaa55;

    //check if enough arguements where provided 
    if(argc < 4) {
        printf("Usage of installer: \n./installer <Disk> <MBRFILE> <Stage2File>");
        exit(1); //if not enough args given exit 
    }

    stage2file = fopen(argv[3],"rb"); 
    if(stage2file == NULL){
        printf("Error Opening Stage 2 file, %s", argv[3]);
        exit(1);
    }
   
    diskdevice = fopen(argv[1],"r+b");
    if(diskdevice == NULL){
        printf("Unable to open disk device %s", argv[1]);
        exit(1);
    }

    mbr = fopen(argv[2],"rb"); 
    if(mbr == NULL){
        printf("Unable to open MBR file %s", argv[2]);
        exit(1);
    }
    fseek(stage2file, 0l, SEEK_END);
    unsigned short sz = ftell(stage2file); //Get 16bit size of file 
    fseek(stage2file, 0, SEEK_SET);

    unsigned long long LBA = 1; //at the moment we auto assume MBR
    
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
    fseek(diskdevice, LBA*0x200, SEEK_SET);
    for(int i = 0; i <= sz; i++) {
        char byte = 0;
        fread(&byte, 1, 1, stage2file);
        fwrite(&byte, 1, 1, diskdevice); 
    }
    
    fclose(mbr);
    fclose(stage2file);
    fclose(diskdevice);
}
