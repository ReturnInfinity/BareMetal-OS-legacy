extern int main(int argc, char **argv, char **environ);
unsigned long b_system_config(unsigned long function, unsigned long var);

extern char __bss_start, _end; // BSS should be the last think before _end

// XXX: environment
char *__env[1] = { 0 };
char **environ = __env;

_start()
{
	char *i;
	int retval = 0;
	unsigned long Argc = 0;
	char **Argv;

	// zero BSS
	for(i = &__bss_start; i < &_end; i++)
	{
		*i = 0;
	}
	
	// XXX: get argc and argv
	Argc = b_system_config(1, 0);
	Argv = 0;

	retval = main((int)Argc, Argv, __env);

//	fflush(stdout);

	return retval;
}

unsigned long b_system_config(unsigned long function, unsigned long var)
{
	unsigned long tlong;
	asm volatile ("call *0x001000B0" : "=a"(tlong) : "d"(function), "a"(var));
	return tlong;
}


// EOF

