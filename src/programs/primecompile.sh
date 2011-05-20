#!/bin/bash

gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -o prime.o prime.c -DBAREMETAL
gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -o libBareMetal.o libBareMetal.c
ld -T app.ld -o prime0.app prime.o libBareMetal.o

gcc -c -m64 -O2 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -o prime.o prime.c -DBAREMETAL
gcc -c -m64 -O2 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -o libBareMetal.o libBareMetal.c
ld -T app.ld -o prime2.app prime.o libBareMetal.o


gcc -m64 -fomit-frame-pointer -o prime0 prime.c -DLINUX

gcc -m64 -O2 -fomit-frame-pointer -o prime2 prime.c -DLINUX

rm *.o
