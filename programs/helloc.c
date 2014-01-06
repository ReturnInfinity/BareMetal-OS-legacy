// Hello World C Test Program (v1.1, September 7 2010)
// Written by Ian Seyler
//
// BareMetal compile:
//
// GCC (Tested with 4.5.0)
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o helloc.o helloc.c
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o libBareMetal.o libBareMetal.c
// ld -T app.ld -o helloc.app helloc.o libBareMetal.o
//
// Clang (Tested with 2.7)
// clang -c -mno-red-zone -o libBareMetal.o libBareMetal.c
// clang -c -mno-red-zone -o helloc.o helloc.c
// ld -T app.ld -o helloc.app helloc.o libBareMetal.o


#include "libBareMetal.h"

int main(void)
{
	b_output("Hello world, from C!\n");
	return 0;
}
