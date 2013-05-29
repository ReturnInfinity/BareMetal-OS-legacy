// =============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
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


void b_output(const char *str)
{
	asm volatile ("call *0x00100010" : : "S"(str)); // Make sure source register (RSI) has the string address (str)
}

void b_output_chars(const char *str, unsigned long nbr)
{
	asm volatile ("call *0x00100018" : : "S"(str), "c"(nbr));
}


unsigned long b_input(unsigned char *str, unsigned long nbr)
{
	unsigned long len;
	asm volatile ("call *0x00100020" : "=c" (len) : "c"(nbr), "D"(str));
	return len;
}

unsigned char b_input_key(void)
{
	unsigned char chr;
	asm volatile ("call *0x00100028" : "=a" (chr));
	return chr;
}


unsigned long b_smp_enqueue(void *ptr, unsigned long var)
{
	unsigned long tlong;
	asm volatile ("call *0x00100030" : "=a"(tlong) : "a"(ptr), "S"(var));
	return tlong;
}

unsigned long b_smp_dequeue(unsigned long *var)
{
	unsigned long tlong;
	asm volatile ("call *0x00100038" : "=a"(tlong), "=D"(*(var)));
	return tlong;
}

void b_smp_run(unsigned long ptr, unsigned long var)
{
	asm volatile ("call *0x00100040" : : "a"(ptr), "D"(var));
}

void b_smp_wait(void)
{
	asm volatile ("call *0x00100048");
}


unsigned long b_mem_allocate(unsigned long *mem, unsigned long nbr)
{
	unsigned long tlong;
	asm volatile ("call *0x00100050" : "=a"(*(mem)), "=c"(tlong) : "c"(nbr));
	return tlong;
}

unsigned long b_mem_release(unsigned long *mem, unsigned long nbr)
{
	unsigned long tlong;
	asm volatile ("call *0x00100058" : "=c"(tlong) : "a"(*(mem)), "c"(nbr));
	return tlong;
}


void b_ethernet_tx(void *mem, unsigned long len)
{
	asm volatile ("call *0x00100060" : : "S"(mem), "c"(len));
}

unsigned long b_ethernet_rx(void *mem)
{
	unsigned long tlong;
	asm volatile ("call *0x00100068" : "=c"(tlong) : "D"(mem));
	return tlong;
}


unsigned long b_file_open(const unsigned char *name)
{
	unsigned long tlong;
	asm volatile ("call *0x00100070" : "=a"(tlong) : "S"(name));
	return tlong;
}

unsigned long b_file_close(unsigned long handle)
{
	unsigned long tlong = 0;
	asm volatile ("call *0x00100078" : : "a"(handle));
	return tlong;
}

unsigned long b_file_read(unsigned long handle, void *buf, unsigned int count)
{
	unsigned long tlong;
	asm volatile ("call *0x00100080" : "=c"(tlong) : "a"(handle), "D"(buf), "c"(count));
	return tlong;
}

unsigned long b_file_write(unsigned long handle, const void *buf, unsigned int count)
{
	unsigned long tlong;
	asm volatile ("call *0x00100088" : "=c"(tlong) : "a"(handle), "S"(buf), "c"(count));
	return tlong;
}

/*
unsigned long b_file_create(const char *name, unsigned long size)
{
	unsigned long tlong;
	asm volatile ("call *0x001000F8" : : "S"(name), "c"(size));
	return tlong;
}

unsigned long b_file_delete(const unsigned char *name)
{
	unsigned long tlong;
	asm volatile ("call *0x00100108" : : "S"(name));
	return tlong;
}

unsigned long b_file_query(const unsigned char *name)
{
	unsigned long tlong;
	asm volatile ("call *0x00100118" : : "S"(name));
	return tlong;
}
*/


unsigned long b_system_config(unsigned long function, unsigned long var)
{
	unsigned long tlong;
	asm volatile ("call *0x001000B0" : "=a"(tlong) : "d"(function), "a"(var));
	return tlong;
}

void b_system_misc(unsigned long function, unsigned long *var1, unsigned long *var2)
{
	asm volatile ("call *0x001000B8" : "=a"(*var1), "=c"(*var2) : "d"(function), "a"(*var1), "c"(*var2));
}



// =============================================================================
// EOF
