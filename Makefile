include ./Makefile.var

ASM=nasm 
ASMFLAGS=-fbin 

ASMFILES=$(wildcard src/*.asm)

$(BIOSBOOT): $(BUILDDIR) $(ASMFILES)
	$(ASM) $(ASMFLAGS) $(ASMFILES) -o $(BIOSBOOT)

clean:
	rm -rf $(BIOSBOOT) 

.PHONY: clean

