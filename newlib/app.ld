OUTPUT_FORMAT("binary")
OUTPUT_ARCH("i386:x86-64")
ENTRY(main)
SECTIONS
{
        . = 0x0000000000200000;
        .text : { *(.text) }
        .data : { *(.data .rodata) QUAD(ADDR(.bss)+SIZEOF(.bss)) }
	__bss_start = .;
        .bss : { *(.bss) }
        end = .; _end = .; __end = .;
}
