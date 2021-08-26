include ./Makefile.var

ASM=nasm

FLAGS=-fbin -w+all -w+error 
MBRSRC=$(wildcard mbr/*.asm)
MBRBIN=$(patsubst mbr/%.asm, %.bin, $(MBRSRC))

STAGE1SRC=$(wildcard stage1/*.asm)
STAGE1BIN=$(patsubst stage1/%.asm, %.bin, $(STAGE1SRC))

STAGE2SRC=$(wildcard stage2/*.asm)
STAGE2BIN=$(patsubst stage2/%.asm, %.bin, $(STAGE2SRC))

BINARY=$(STAGE1BIN) $(STAGE2BIN) $(MBRBIN)

all: $(BINARY)

$(MBRBIN): $(MBRSRC)
	$(ASM) $(FLAGS) $^ -o $@

$(STAGE1BIN): $(STAGE1SRC)
	$(ASM) $(FLAGS) $^ -o $@

$(STAGE2BIN): $(STAGE2SRC)
	$(ASM) -I./stage2 $(FLAGS) $^ -o $@

clean:
	rm -rf *.bin *.o 

.PHONY: clean

