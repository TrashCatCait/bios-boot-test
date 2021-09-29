include ./Makefile.var

#Compilers and set ups
ASM=nasm 
ASMFLAGS=-i./includes/ -w+all -w+error 
CC=clang
CFLAGS=-I./includes/ -ffreestanding -nostdlib -mno-sse -mno-sse2 -mno-mmx -mno-red-zone  
LD=ld
LFLAGS=--nostdlib

#Files 
MBRFILES=$(wildcard stage1/*.asm)
MBRBIN=$(patsubst stage1/%.asm, %.bin, $(MBRFILES))
CTARGET=stage2.elf
CFILES=$(wildcard stage2/*.c)
COBJS=$(patsubst stage2/%.c, build/%.co, $(CFILES))
ASMFILES=$(wildcard stage2/*.asm)
ASMOBJS=$(patsubst stage2/%.asm, build/%.ao, $(ASMFILES))


all: build $(ASMOBJS) $(CTARGET) $(MBRBIN) 

%.bin: ./stage1/%.asm
	$(ASM) $(ASMFLAGS) -fbin -I./src $^ -o $@

$(CTARGET): $(COBJS) 
	$(LD) $(LFLAGS) -T./stage2.ld -o $@ $(ASMOBJS) $(COBJS)

build/%.ao: stage2/%.asm
	$(ASM) $(ASMFLAGS) -felf64 $^ -o $@

build/%.co: stage2/%.c
	$(CC) $(CFLAGS) -c $^ -o $@

build:
	mkdir -p ./build 

clean:
	rm -rf *.bin ./build $(CTARGET)

.PHONY: clean

