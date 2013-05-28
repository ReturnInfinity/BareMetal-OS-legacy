OUTPUT_FORMAT("binary")
OUTPUT_ARCH("i386:x86-64")
ENTRY(main)
SECTIONS
{
	. = 0x0000000000200000;
	.text : {
		*(.text)
		. = ALIGN(4096);
	}
	.rodata : {
		*(.rodata)
		. = ALIGN(4096);
	}
	.data : {
		*(.data)
		. = ALIGN(4096);
	}
	.bss : {
		bss = .; _bss = .; __bss = .;
		*(.bss);
	}
	end = .; _end = .; __end = .;
}
