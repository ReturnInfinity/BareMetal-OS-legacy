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
// maxn = 500000	=0x000000000007a120	primes = 41538
// maxn = 1000000	=0x00000000000f4240	primes = 78498
// maxn = 5000000	=0x00000000004c4b40	primes = 348513
// maxn = 10000000	=0x0000000000989680	primes = 664579
// maxn = 4294967295	=0x00000000ffffffff	primes = 203280221	(max_32)

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
	
	if(!(max_number&1))max_number--; // drop max to odd
	unsigned long xx_k, x_k, f_val, df_val;	// root finding variables
	unsigned long iRoot=0xFFFFFFFF;		// max_number <= max_64 implies sqr(max_number) <= sqr(max_64)
	// using McDougall/Wotherspoon to find square root of max_number
	xx_k 	= iRoot;			// x*_0 = x_0
	f_val 	= iRoot * iRoot - max_number;	// f(x_0)
	df_val 	= iRoot * 2;			// f'((x_0+x*_0)/2) = f'(x_0)
	x_k 	= iRoot / 2 + max_number / df_val;// x_1  = x_0 - f(x_0)/f'((x_0+x*_0)/2) = x_0 - f(x_0)/f'(x_0)
	for(j=1; j<30 && (iRoot - x_k); j++){
		iRoot  = x_k;
		f_val  = x_k * x_k - max_number;
		xx_k   = (df_val * x_k - f_val) / df_val;
		df_val = x_k + xx_k;
		x_k    = (df_val * x_k - f_val) / df_val;
       	}
       	// end root algo

	for(i=max_number; i>2; i-=2) // reversed i to count down so previous step's iRoot is a good starting point
	{
		// using a step of Raphson to find the square root of i from previous iRoot
		iRoot = (iRoot * iRoot + i) / (2 * iRoot);
		// end root algo
		for(j=3; j<=iRoot && i%j; j+=2); // test i for divisibility by j
		if(j>iRoot)primes++;             // count as prime when not divisible
	} //Continue loop up to max number

	time(&finish);

	printf("%ld in %.0lf seconds\n", primes, difftime(finish, start));

	return 0;
}

// EOF
