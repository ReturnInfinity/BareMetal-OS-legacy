// =============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
//
// The BareMetal OS C/C++ library code.
//
// Version 2.0
//
// This allows for a C/C++ program to access OS functions available in BareMetal OS
//
//
// Linux compile:
//
// Compile:
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o libBareMetal.o libBareMetal.c
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o yourapp.o yourapp.c
// Link:
// ld -T app.ld -o yourapp.app yourapp.o
//
//
// Windows compile:
//
// gcc -m64 -nostdlib -nostartfiles -nodefaultlibs -fomit-frame-pointer -mno-red-zone -o yourapp.o yourapp.c libBareMetal.c -Ttext=0x200000
// objcopy -O binary yourapp.o yourapp.app
//
// =============================================================================


void b_print_string(const char *str)
{
	asm volatile ("call *0x00100018" : : "S"(str)); // Make sure source register (RSI) has the string address (str)
}

void b_print_char(char chr)
{
	asm volatile ("call *0x00100028" : : "a"(chr));
}

unsigned long b_input_string(unsigned char *str, unsigned long nbr)
{
	unsigned long len;
	asm volatile ("call *0x00100038" : "=c" (len) : "c"(nbr), "D"(str));
	return len;
}

unsigned char b_input_get_key(void)
{
	unsigned char chr;
	asm volatile ("call *0x00100048" : "=a" (chr));
	return chr;
}

void b_file_create(const char *name, unsigned long size)
{
	asm volatile ("call *0x00100058" : : "S"(name), "c"(size));
}

void b_delay(unsigned long nbr)
{
	asm volatile ("call *0x00100068" : : "a"(nbr));
}

void b_move_cursor(unsigned char col, unsigned char row)
{
	asm volatile ("call *0x00100078" : : "a"(col + row<<8));
}

void b_smp_reset(void)
{
	asm volatile ("call *0x00100088");
}

unsigned long b_smp_get_id()
{
	unsigned long tlong;
	asm volatile ("call *0x00100098" : "=a"(tlong));
	return tlong;
}

unsigned long b_smp_enqueue(void *ptr, unsigned long var)
{
	unsigned long tlong;
	asm volatile ("call *0x001000A8" : "=a"(tlong) : "a"(ptr), "S"(var));
	return tlong;
}


unsigned long b_smp_dequeue(unsigned long *var)
{
	unsigned long tlong;
	asm volatile ("call *0x001000B8" : "=a"(tlong), "=D"(*(var)));
	return tlong;
}

void b_serial_send(unsigned char chr)
{
	asm volatile ("call *0x001000C8" : : "a"(chr));
}

unsigned char b_serial_recv(void)
{
	unsigned char chr;
	asm volatile ("call *0x001000D8" : "=a" (chr));
	return chr;
}

unsigned long b_smp_queuelen(void)
{
	unsigned long tlong;
	asm volatile ("call *0x001000E8" : "=a"(tlong));
	return tlong;
}

void b_smp_wait(void)
{
	asm volatile ("call *0x001000F8");
}

void b_file_read(const unsigned char *name, void *mem)
{
	asm volatile ("call *0x00100108" : : "S"(name), "D"(mem));
}


void b_file_write(void *data, const unsigned char *name, unsigned int size)
{
	asm volatile ("call *0x00100118" : : "S"(data), "D"(name), "c"(size));
}


void b_file_delete(const unsigned char *name)
{
	asm volatile ("call *0x00100128" : : "S"(name));
}

// b_file_get_list

void b_smp_run(unsigned long ptr, unsigned long var)
{
	asm volatile ("call *0x00100148" : : "a"(ptr), "D"(var));
}

void b_smp_lock(unsigned long ptr)
{
	asm volatile ("call *0x00100158" : : "a"(ptr));
}

void b_smp_unlock(unsigned long ptr)
{
	asm volatile ("call *0x00100168" : : "a"(ptr));
}

void b_ethernet_tx(void *mem, void *dest, unsigned short type, unsigned short len)
{
	asm volatile ("call *0x00100178" : : "S"(mem), "D"(dest), "b"(type), "c"(len));
}

unsigned long b_ethernet_rx(void *mem)
{
	unsigned long tlong;
	asm volatile ("call *0x00100188" : "=c"(tlong) : "D"(mem));
	return tlong;
}

unsigned long b_mem_allocate(unsigned long *mem, unsigned long nbr)
{
	unsigned long tlong;
	asm volatile ("call *0x00100198" : "=a"(*(mem)), "=c"(tlong) : "c"(nbr));
	return tlong;
}

unsigned long b_mem_release(unsigned long *mem, unsigned long nbr)
{
	unsigned long tlong;
	asm volatile ("call *0x001001A8" : "=c"(tlong) : "a"(*(mem)), "c"(nbr));
	return tlong;
}

unsigned long b_mem_get_free(void)
{
	unsigned long tlong;
	asm volatile ("call *0x001001B8" : "=c"(tlong));
	return tlong;
}

unsigned long b_smp_numcores(void)
{
	unsigned long tlong;
	asm volatile ("call *0x001001C8" : "=a"(tlong));
	return tlong;
}

unsigned long b_file_get_size(const char *name)
{
    unsigned long tlong;
    asm volatile ("call *0x001001D8" : "=c"(tlong) : "S"(name));
    return tlong;
}

unsigned long b_ethernet_avail()
{
	unsigned long tlong;
	asm volatile ("call *0x001001E8" : "=a"(tlong));
	return tlong;
}

void b_ethernet_tx_raw(void *mem, unsigned short len)
{
	asm volatile ("call *0x001001F8" : : "S"(mem), "c"(len));
}

void b_show_statusbar(void)
{
	asm volatile ("call *0x00100208");
}

void b_hide_statusbar(void)
{
	asm volatile ("call *0x00100218");
}

void b_screen_update(void)
{
	asm volatile ("call *0x00100228");
}

void b_print_chars(const char *str, unsigned long len)
{
	asm volatile ("call *0x00100238" : : "S"(str), "c"(len));
}

void b_print_chars_with_color(const char *str, unsigned long len, unsigned char clr)
{
	asm volatile ("call *0x00100238" : : "S"(str), "c"(len), "b"(clr));
}

// =============================================================================
// EOF
