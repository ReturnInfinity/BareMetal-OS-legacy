; gcc -nostdlib stubstart.s -o hello.app hello.c

.globl _start

_start:
	call main
	ret
