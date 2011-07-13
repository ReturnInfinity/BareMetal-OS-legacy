// =============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
//
// The BareMetal OS C library code.
//
// Version 2.0
//
// This allows for a C program to access OS functions available in BareMetal OS
//
// Compile:
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o libBareMetal.o libBareMetal.c
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o yourapp.o yourapp.c
//
// Link:
// ld -T app.ld -o yourapp.app yourapp.o
// =============================================================================


void b_print_string(char *str)
{
	asm volatile ("call *0x00100018" : : "S"(str)); // Make sure source register (RSI) has the string address (str)
}


void b_print_char(char chr)
{
	asm volatile ("call *0x00100028" : : "a"(chr));
}


void b_print_char_hex(char chr)
{
	asm volatile ("call *0x00100038" : : "a"(chr));
}


void b_print_newline(void)
{
	asm volatile ("call *0x00100048");
}


void b_print_string_with_color(char *str, unsigned char clr)
{
	asm volatile ("call *0x00100388" : : "S"(str), "b"(clr)); // Make sure source register (RSI) has the string address (str)
}


void b_print_char_with_color(char chr, unsigned char clr)
{
	asm volatile ("call *0x00100398" : : "a"(chr), "b"(clr));

}


void b_print_char_hex_with_color(char chr, unsigned char clr)
{
	asm volatile ("call *0x00100428" : : "a"(chr), "b"(clr));

}


unsigned char b_input_get_key(void)
{
	unsigned char chr;
	asm volatile ("call *0x00100058" : "=a" (chr));
	return chr;
}


unsigned char b_input_wait_for_key(void)
{
	unsigned char chr;
	asm volatile ("call *0x00100068" : "=a" (chr));
	return chr;
}


unsigned long b_input_string(unsigned char *str, unsigned long nbr)
{
	unsigned long len;
	asm volatile ("call *0x00100078" : "=c" (len) : "c"(nbr), "D"(str));
	return len;
}


unsigned long b_string_length(unsigned char *str)
{
	unsigned long len;
	asm volatile ("call *0x001000D8" : "=c" (len) : "S"(str));
	return len;
}


unsigned long b_string_find_char(unsigned char *str, unsigned char chr)
{
	unsigned long pos;
	asm volatile ("call *0x001000E8" : "=a" (pos) : "a"(chr), "S"(str));
	return pos;
}


void b_os_string_copy(unsigned char *dst, unsigned char *src)
{
	asm volatile ("call *0x001000F8" : : "S"(src), "D"(dst));
}


void b_int_to_string(unsigned long nbr, unsigned char *str)
{
	asm volatile ("call *0x00100178" : : "a"(nbr), "D"(str));
}


unsigned long b_string_to_int(unsigned char *str)
{
	unsigned long tlong;
	asm volatile ("call *0x00100188" : "=a"(tlong) : "S"(str));
	return tlong;
}


void b_delay(unsigned long nbr)
{
	asm volatile ("call *0x00100088" : : "a"(nbr));
}


unsigned long b_get_argc()
{
	unsigned long tlong;
	asm volatile ("call *0x00100268" : "=a"(tlong));
	return tlong;
}


char* b_get_argv(unsigned char nbr)
{
	char* tchar;
	asm volatile ("call *0x00100278" : "=S"(tchar) : "a"(nbr));
	return tchar;
}


unsigned long b_get_timercounter(void)
{
	unsigned long tlong;
	asm volatile ("call *0x001002A8" : "=a"(tlong));
	return tlong;
}


void b_debug_dump_mem(void *data, unsigned int size)
{
	asm volatile ("call *0x001001A8" : : "S"(data), "c"(size));
}


void b_serial_send(unsigned char chr)
{
	asm volatile ("call *0x00100238" : : "a"(chr));
}


unsigned char b_serial_recv(void)
{
	unsigned char chr;
	asm volatile ("call *0x00100248" : "=a" (chr));
	return chr;
}


void b_file_read(unsigned char *name, void *mem)
{
	asm volatile ("call *0x00100318" : : "S"(name), "D"(mem));
}


void b_file_write(void *data, unsigned char *name, unsigned int size)
{
	asm volatile ("call *0x00100328" : : "S"(data), "D"(name), "c"(size));
}


void b_file_delete(unsigned char *name)
{
	asm volatile ("call *0x00100338" : : "S"(name));
}


unsigned long b_smp_enqueue(void *ptr,  unsigned long var)
{
 	unsigned long tlong;
	asm volatile ("call *0x00100218" : "=a"(tlong) : "a"(ptr), "S"(var));
	return tlong;
}


unsigned long b_smp_dequeue(unsigned long *var)
{
	unsigned long tlong;
        asm volatile ("call *0x00100228" : "=a"(tlong), "=D"(var));
	return tlong;
}


void b_smp_run(unsigned long ptr)
{
	asm volatile ("call *0x00100358" : : "a"(ptr));
}


unsigned long b_smp_queuelen(void)
{
	unsigned long tlong;
	asm volatile ("call *0x00100288" : "=a"(tlong));
	return tlong;
}


void b_smp_wait(void)
{
        asm volatile ("call *0x00100298");
} 


void b_smp_lock(unsigned long ptr)
{
        asm volatile ("call *0x00100368" : : "a"(ptr));
}


void b_smp_unlock(unsigned long ptr)
{
        asm volatile ("call *0x00100378" : : "a"(ptr));
}


unsigned long b_smp_get_id()
{
	unsigned long tlong;
	asm volatile ("call *0x00100208" : "=a"(tlong));
	return tlong;
}


unsigned long b_smp_numcores(void)
{
	unsigned long tlong;
	asm volatile ("call *0x001003F8" : "=a"(tlong));
	return tlong;
}


void b_speaker_tone(unsigned long nbr)
{
        asm volatile ("call *0x00100098" : : "a"(nbr));
}


void b_speaker_off(void)
{
        asm volatile ("call *0x001000A8");
}


void b_speaker_beep(void)
{
        asm volatile ("call *0x001000B8");
}


void b_ethernet_tx(void *mem, void *dest, unsigned short type, unsigned short len)
{
	asm volatile ("call *0x001003A8" : : "S"(mem), "D"(dest), "b"(type), "c"(len));
}

void b_ethernet_tx_raw(void *mem, unsigned short len)
{
	asm volatile ("call *0x00100438" : : "S"(mem), "c"(len));
}

unsigned long b_ethernet_rx(void *mem)
{
	unsigned long tlong;
	asm volatile ("call *0x001003B8" : "=c"(tlong) : "D"(mem));
	return tlong;
}

unsigned long b_ethernet_avail()
{
	unsigned long tlong;
	asm volatile ("call *0x00100418" : "=a"(tlong));
	return tlong;
}


// =============================================================================
// EOF
