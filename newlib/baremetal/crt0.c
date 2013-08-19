#include <stdio.h> // fflush()

extern int main(int argc, char *argv[]);
unsigned long b_system_config_crt0(unsigned long function, unsigned long var);

extern char __bss_start, _end; // BSS should be the last think before _end

_start()
{
	int argc, i, retval;
	argc = (int)b_system_config_crt0(1, 0);
	char *argv[argc], *c, *tchar;

	// zero BSS
	for(c = &__bss_start; c < &_end; c++)
	{
		*c = 0;
	}

	// Parse argv[*]
	for(i=0; i<argc; i++)
		argv[i] = (char *)b_system_config_crt0(2, (unsigned long)i);

	retval = main(argc, argv);

	fflush(stdout);

	return retval;
}

unsigned long b_system_config_crt0(unsigned long function, unsigned long var)
{
	unsigned long tlong;
	asm volatile ("call *0x001000B0" : "=a"(tlong) : "d"(function), "a"(var));
	return tlong;
}


// EOF

