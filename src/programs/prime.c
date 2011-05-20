// Prime Test Program (v1.2, September 7 2010)
// Written by Ian Seyler
//
// This program checks all odd numbers between 3 and 'maxn' and determines if they are prime.
// On exit the program will display the execution time and how many prime numbers were found.
// Useful for testing runtime performance between Linux and BareMetal OS.
//
// BareMetal compile using GCC (Tested with 4.5.0)
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -mno-red-zone -o prime.o prime.c -DBAREMETAL
// gcc -c -m64 -nostdlib -nostartfiles -nodefaultlibs -mno-red-zone -o libBareMetal.o libBareMetal.c
// objcopy --remove-section .eh_frame --remove-section .rel.eh_frame --remove-section .rela.eh_frame prime.o
// objcopy --remove-section .eh_frame --remove-section .rel.eh_frame --remove-section .rela.eh_frame libBareMetal.o
// ld -T app.ld -o prime.app prime.o libBareMetal.o
//
// Linux compile using GCC (Tested with 4.5.0)
// gcc -m64 -o prime prime.c -DLINUX
// strip prime
//
// maxn = 500000	primes = 41538
// maxn = 1000000	primes = 78498
// maxn = 5000000	primes = 348513
// maxn = 10000000	primes = 664579


#ifdef LINUX
#include <stdio.h>
#include <time.h>
#endif

#ifdef BAREMETAL
#include "libBareMetal.h"
#endif

int main()
{
	// primes is set to 1 since we don't calculate for '2' as it is a known prime number
	register unsigned long i, j, maxn=1000000, primes=1;

#ifdef BAREMETAL
	unsigned char tstring[25];
	unsigned long start, finish;
	start = b_get_timercounter();
#endif

#ifdef LINUX
	time_t start, finish;
	time(&start);
#endif

	for(i=3; i<=maxn; i+=2)
	{
		for(j=2; j<=i-1; j++)
		{
			if(i%j==0) break; //Number is divisble by some other number. So break out
		}
		if(i==j)
		{
			primes = primes + 1;
		}
	} //Continue loop up to max number

#ifdef LINUX
	time(&finish);
	printf("%u in %.0lf seconds\n", primes, difftime(finish, start));
#endif

#ifdef BAREMETAL
	finish = b_get_timercounter();
	b_int_to_string(primes, tstring);
	b_print_string(tstring);
	b_print_string(" in ");
	finish = (finish - start) / 8;
	b_int_to_string(finish, tstring);
	b_print_string(tstring);
	b_print_string(" seconds\n");
#endif

	return 0;
}

// EOF
