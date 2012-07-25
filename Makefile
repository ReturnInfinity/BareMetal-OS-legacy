### COMMAND OPTIONS

# If you're using a specific nasm binary, run make like:
# NASM=/path/to/nasm make -e
NASM = nasm


### MAKE OPTIONS

# HDD specifies the hard disk interface type.
# Options: PIO or AHCI
HDD = PIO
# FS specifies the supported filesystem.
# Options: FAT16 or BMFS
FS = FAT16

all: kernel64.sys

_build:
	mkdir -p build

kernel64.sys: _build
	${NASM} -Ios/ os/kernel64.asm -o build/kernel64.sys -dHDD=${HDD} -dFS=${FS}

clean:
	rm -r build
