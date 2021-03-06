include ./Makefile.var

#Compilers and set ups
ASM=nasm 
ASMFLAGS=-i./includes/ -w+all -w+error 
CC=clang
CFLAGS=-I./includes/ -ffreestanding -fno-pic -nostdlib -mno-sse -m32 -mno-sse2 -mno-mmx -mno-red-zone  
LD=ld
LFLAGS=--nostdlib -static -z max-page-size=0x1000 

#Files 
MBRFILES=$(wildcard stage1/*.asm)
MBRBIN=$(patsubst stage1/%.asm, %.bin, $(MBRFILES))
CTARGET=stage2.elf
CFILES=$(wildcard stage2/*.c)
COBJS=$(patsubst stage2/%.c, build/%.co, $(CFILES))
ASMFILES=$(wildcard stage2/*.asm)
ASMOBJS=$(patsubst stage2/%.asm, build/%.ao, $(ASMFILES))

#Stage 2 comes first so it's present for MBR calculations
all: build $(CTARGET) $(MBRBIN) installer.elf

installer.elf: ./installer/*.c
	$(CC) -fuse-ld=lld -o $@ $^

%.bin: ./stage1/%.asm
	$(ASM) $(ASMFLAGS) -fbin -I./src $^ -o $@

$(CTARGET): $(ASMOBJS) $(COBJS) 
	$(LD) $(LFLAGS) -T./stage2.ld -o $@ $(ASMOBJS) $(COBJS) -melf_i386
	llvm-strip --strip-all $@

build/%.ao: stage2/%.asm
	$(ASM) $(ASMFLAGS) -felf $^ -o $@

build/%.co: stage2/%.c
	$(CC) $(CFLAGS) -c $^ -o $@

build:
	mkdir -p ./build 

clean:
	rm -rf *.bin ./build $(CTARGET)

.PHONY: clean

