[bits 32]

extern stage2_start
global _start

_start:
call stage2_start
jmp $
