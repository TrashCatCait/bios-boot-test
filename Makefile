include ./Makefile.var

ASM=nasm 
ASMFLAGS=-i./src/includes/ -fbin -w+all -w+error 
ASMFILES=$(wildcard src/*.asm)


$(BIOSBOOT): $(BUILDDIR) $(ASMFILES)
	$(ASM) $(ASMFLAGS) $(ASMFILES) -o $(BIOSBOOT)

clean:
	rm -rf $(BIOSBOOT) 

.PHONY: clean

