TARGET=catboot

ASM=nasm 
ASMFLAGS=-fbin 

ASMFILES=$(wildcard src/*.asm)

$(TARGET): $(BUILDDIR) $(ASMFILES)
	$(ASM) $(ASMFLAGS) $(ASMFILES) -o $(TARGET)

clean:
	rm -rf $(TARGET) 

.PHONY: clean

