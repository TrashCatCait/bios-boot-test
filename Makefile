include ./Makefile.var

#Compilers and set ups
ASM=nasm 
ASMFLAGS=-i./includes/ -fbin -w+all -w+error 
CC=clang
CFLAGS=-I./includes/ -ffreestanding -nostdlib -mno-sse -mno-sse2 -mno-mmx -mno-red-zone -m32 
LD=ld.lld
LFLAGS=--nostdlib

#Files 
MBRFILES=$(wildcard stage1/*.asm)
MBRBIN=$(patsubst stage1/%.asm, %.bin, $(ASMFILES))
CTARGET=stage.elf
CFILES=$(wildcard stage2/*.c)
COBJS=$(patsubst stage2/%.c, build/%.o, $(CFILES))


all: $(CTARGET) $(MBRBIN)

%.bin: ./src/%.asm
	$(ASM) $(ASMFLAGS) -I./src $^ -o $@

$(CTARGET): build $(COBJS) 
	$(LD) $(LFLAGS) -T./stage2.ld -o $@ $(COBJS)

build/%.o: stage2/%.c
	$(CC) $(CFLAGS) -c $^ -o $@

build:
	mkdir -p ./build 

clean:
	rm -rf *.bin ./build $(CTARGET)

.PHONY: clean

