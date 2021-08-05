include ./Makefile.var

ASM=nasm 
ASMFLAGS=-i./src/includes/ -fbin -w+all -w+error 
ASMFILES=$(wildcard src/*.asm)
RAWFILES=$(patsubst src/%.asm, %.bin, $(ASMFILES))


all: $(RAWFILES)

%.bin: ./src/%.asm
	$(ASM) $(ASMFLAGS) $^ -o $@

clean:
	rm -rf *.bin 

.PHONY: clean

