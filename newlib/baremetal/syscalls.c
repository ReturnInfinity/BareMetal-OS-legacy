// ============================================================================
// BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
// Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
//
// Syscalls glue for Newlib
// ============================================================================


#include <sys/types.h>
#include <sys/stat.h>
#include <sys/fcntl.h>
#include <sys/times.h>
#include <sys/errno.h>
#include <sys/time.h>
#include <stdio.h>
#include <errno.h>

inline unsigned char inportbyte(unsigned int port);
inline void outportbyte(unsigned int port,unsigned char value);

// --- Process Control ---

// exit -- Exit a program without cleaning up files
int _exit(int val)
{
	exit(val);
	return (-1);
}

// execve -- Transfer control to a new process
// Minimal implementation
int execve(char *name, char **argv, char **env)
{
	errno = ENOMEM;
	return -1;
}

// environ - A pointer to a list of environment variables and their values
// Minimal implementation
char *__env[1] = { 0 };
char **environ = __env;

// getpid -- Process-ID
// Return 1 by default
int getpid(void)
{
	return 1;
}

// fork -- Create a new process
// Minimal implementation
int fork(void)
{
	errno = ENOTSUP; // EAGAIN?
	return -1;
}

// kill -- Send a signal
int kill(pid, sig)
{
	if(pid == 1)
		_exit(sig);

	errno = EINVAL;
	return -1;
}

// wait -- Wait for a child process
// Minimal implementation
int wait(int *status)
{
	errno = ECHILD;
	return -1;
}

// --- I/O ---

// isatty - Query whether output stream is a terminal
int isatty(fd)
{
	if (fd == 0 || fd == 1 || fd == 2)
		return 1;
	else
		return 0;
}

// close - Close a file
// Minimal implementation
int close(int file)
{
	return -1;
}

// link - Establish a new name for an existing file
// Minimal implementation
int link(char *old, char *new)
{
	errno = EMLINK;
	return -1;
}

// lseek - Set position in a file
// Minimal implementation
int lseek(int file, int ptr, int dir)
{
	return 0;
}

// open - Open a file
// Minimal implementation
int open(const char *name, int flags, ...)
{
	return -1;
}

// read - Read from a file
int read(int file, char *ptr, int len)
{
	if (file == 0) // STDIN
	{
		asm volatile ("call *0x00100020" : "=c"(len) : "c"(len), "D"(ptr));
		ptr[len] = '\n'; // BareMetal does not add a newline after keyboard input ...
		ptr[len+1] = 0; // ... but C expects it.
		len+=1;
		write(1, "\n", 1);
	}
	else
	{
		asm volatile ("call *0x00100080" : "=c"(len) : "a"(file));
	}
	return len;
}

// fstat - Status of an open file.
// Minimal implementation
int fstat(int file, struct stat *st)
{
	st->st_mode = S_IFCHR;
	return 0;
}

// stat - Status of a file
// Minimal implementation
int stat(const char *file, struct stat *st)
{
	st->st_mode = S_IFCHR;
	return 0;
}

// unlink - Remove a file's directory entry
int unlink(char *name)
{
	errno = ENOENT;
	return -1;
}

// write - Write to a file
int write(int file, char *ptr, int len)
{
	if (file == 1 || file == 2) // STDOUT = 1, STDERR = 2
	{
		asm volatile ("call *0x00100018" : : "S"(ptr), "c"(len)); // Make sure source register (RSI) has the string address (str)
	}
	else
	{
		// File!
		return -1;
	}
	return len;
}

// --- Memory ---

/* _end is set in the linker command file */
//extern caddr_t _end;

//#define PAGE_SIZE 2097152ULL
//#define PAGE_MASK 0xFFFFFFFFFFE00000ULL
//#define HEAP_ADDR (((unsigned long long)&_end + PAGE_SIZE) & PAGE_MASK)

/*
 * sbrk -- changes heap size size. Get nbytes more
 *         RAM. We just increment a pointer in what's
 *         left of memory on the board.
 */
// sbrk - Increase program data space

caddr_t sbrk(int incr)
{
//	asm volatile ("xchg %bx, %bx"); // Debug
	extern caddr_t _end; /* Defined by the linker */
	static caddr_t *heap_end;
	caddr_t *prev_heap_end;
//	write (2, "sbrk\n", 5);
	if (heap_end == 0)
	{
//		write (2, "sbrk end\n", 9);
		heap_end = &_end;
	}
	prev_heap_end = heap_end;
//	if (heap_end + incr > stack_ptr) {
//		write (2, "Heap and stack collision\n", 25);
//		abort ();
//	}
	heap_end += incr;
	return (caddr_t) prev_heap_end;
}


// --- Other ---

// gettimeofday -- 
int gettimeofday(struct timeval *p, void *z)
{
	unsigned char bcd;
	struct tm t;
    
//	outportbyte(0x70, 0x32); // Century
//	bcd = inportbyte(0x71);
	outportbyte(0x70, 0x09); // Year
	bcd = inportbyte(0x71);
	t.tm_year = 100 + ((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F); // Years since 1900
	outportbyte(0x70, 0x08); // Month
	bcd = inportbyte(0x71);
	t.tm_mon = (((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F)) - 1; // Months since January
	outportbyte(0x70, 0x07); // Day
	bcd = inportbyte(0x71);
	t.tm_mday = ((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F);
	outportbyte(0x70, 0x04); // Hour
	bcd = inportbyte(0x71);
	t.tm_hour = ((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F);
	outportbyte(0x70, 0x02); // Minute
	bcd = inportbyte(0x71);
	t.tm_min = ((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F);
	outportbyte(0x70, 0x00); // Second
	bcd = inportbyte(0x71);
	t.tm_sec = ((bcd & 0xF0) >> 1) + ((bcd & 0xF0) >> 3) + (bcd & 0x0F);
	t.tm_isdst = -1;

	p->tv_sec = (long) mktime(&t);
	p->tv_usec = 0;

	return 0;
}

// times - Timing information for current process.
// Minimal implementation
clock_t times(struct tms *buf){
        return -1;
}

void __stack_chk_fail(void)
{
	write(1, "Stack smashin' detected!\n", 25);
} 

inline unsigned char inportbyte(unsigned int port)
{
	// read a byte from a port
	unsigned char ret;
	asm volatile ("inb %%dx,%%al":"=a"(ret):"d"(port));
	return ret;
}

inline void outportbyte(unsigned int port,unsigned char value)
{
	// write a byte to a port
	asm volatile ("outb %%al,%%dx": :"d"(port),"a"(value));
}

// EOF
