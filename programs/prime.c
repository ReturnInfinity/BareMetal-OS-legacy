// Prime Test Program (v1.5, June 30 2013)
// Written by Ian Seyler @ Return Infinity
//
// This program checks all odd numbers between 3 and 'maxn' and determines if they are prime.
// On exit the program will display the execution time and how many prime numbers were found.
// Useful for testing runtime performance between Linux/BSD and BareMetal OS.
//
// BareMetal compile using GCC (Tested with 4.7) with Newlib 2.0.0
// gcc -I newlib-2.0.0/newlib/libc/include/ -c primesmp.c -o primesmp.o -DBAREMETAL
// ld -T app.ld -o primesmp.app crt0.o primesmp.o libc.a
//
// Linux/BSD compile using GCC (Tested with 4.7)
// gcc primesmp.c -o primesmp
//
// maxn = 500000	primes = 41538
// maxn = 1000000	primes = 78498
// maxn = 5000000	primes = 348513
// maxn = 10000000	primes = 664579

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

// primes is set to 1 since we don't calculate for '2' as it is a known prime number
unsigned long i, j, max_number=0, primes=1;
time_t start, finish;


int main(int argc, char *argv[])
{
	if ((argc == 1) || (argc >= 3))
	{
		printf("usage: %s max_number\n", argv[0]);
		exit(1);
	}
	else
	{
		max_number = atoi(argv[1]);
	}
	
	if (max_number == 0)
	{
		printf("Invalid argument(s).\n");
		printf("usage: %s max_number\n", argv[0]);
		exit(1);
	}
	
	printf("Prime v1.5 - Searching up to %ld.\nProcessing...\n", max_number);

	time(&start);

	for(i=3; i<=max_number; i+=2)
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

	time(&finish);

	printf("%ld in %.0lf seconds\n", primes, difftime(finish, start));

	return 0;
}

// EOF
