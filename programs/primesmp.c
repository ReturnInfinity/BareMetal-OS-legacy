// Prime SMP Test Program (v1.6, January 27 2014)
// Written by Ian Seyler @ Return Infinity
//
// This program checks all odd numbers between 3 and 'maxn' and determines if they are prime.
// On exit the program will display the execution time and how many prime numbers were found.
// Useful for testing runtime performance between Linux/BSD and BareMetal OS.
//
// BareMetal compile using GCC (Tested with 4.8) with Newlib 2.1.0
// gcc -I newlib-2.1.0/newlib/libc/include/ -c primesmp.c -o primesmp.o -DBAREMETAL
// gcc -c -nostdlib -nostartfiles -nodefaultlibs libBareMetal.c -o libBareMetal.o
// ld -T app.ld -o primesmp.app crt0.o primesmp.o libBareMetal.o libc.a
//
// Linux/BSD compile using GCC (Tested with 4.8)
// gcc -pthread primesmp.c -o primesmp
//
// maxn = 500000	primes = 41538
// maxn = 1000000	primes = 78498
// maxn = 5000000	primes = 348513
// maxn = 10000000	primes = 664579
// maxn = 4294967295	primes = 203280221
// maxn = 18446744073709551615	primes aprox 4.15829ee17

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef BAREMETAL
#include "libBareMetal.h"
#else
#include <pthread.h>
#endif

void *prime_process(void *param);

// primes is set to 1 since we don't calculate for '2' as it is a known prime number
unsigned long max_number=0, primes=1, local=0, process_stage=0, processes=0, max_processes=0, singletime=0, k=0;
unsigned long max_root=0xFFFFFFFF; // max_number <= max_64 implies sqr(max_number) <= sqr(max_64)
float speedup;
time_t start, finish;

#ifdef BAREMETAL
unsigned int lock=0;
#else
pthread_mutex_t mutex1 = PTHREAD_MUTEX_INITIALIZER;
#endif


int main(int argc, char *argv[])
{
	printf("PrimeSMP v1.6\n");

	if ((argc == 1) || (argc >= 4))
	{
		printf("usage: %s max_processes max_number\n", argv[0]);
		return 1;
	}
	else
	{
		max_processes = atoi(argv[1]);
		max_number = atoi(argv[2]);
	}

	if ((max_processes == 0) || (max_number == 0))
	{
		printf("Invalid argument(s).\n");
		printf("usage: %s max_processes max_number\n", argv[0]);
		return 1;
	}

	printf("Using a maximum of %ld process(es). Searching up to %ld.\n", max_processes, max_number);

	for (processes=1; processes <= max_processes; processes++) // changed to ++ from *=2 so processes matches comments below
	{       
		primes = 1;
		process_stage = processes;

#ifdef BAREMETAL
		unsigned long tval = 0;
#else
		pthread_t worker[processes];
#endif

		printf("Processing with %ld process(es)...\n", processes);

		time(&start);				// Grab the starting time
	
		if(!(max_number&1)) max_number--; // drop max to odd

		// using McDougall/Wotherspoon to find root of max_number as starting point for all threads
		unsigned long xx_k, x_k, f_val, df_val; // root finding variables
		xx_k = max_root;				// x*_0 = x_0
		f_val = max_root * max_root - max_number;	// f(x_0)
		df_val = max_root * 2;				// f'((x_0+x*_0)/2) = f'(x_0)
		x_k = max_root / 2 + max_number / df_val;	// x_1  = x_0 - f(x_0)/f'((x_0+x*_0)/2) = x_0 - f(x_0)/f'(x_0)
		for(int i=1; i<30 && (max_root - x_k); i++){
			max_root= x_k;
			f_val	= x_k * x_k - max_number;
			xx_k	= (df_val * x_k - f_val) / df_val;
			df_val	= x_k + xx_k;
			x_k	= (df_val * x_k - f_val) / df_val;
		}
		// end root algo

		// Spawn the worker processes
		for (k=0; k<processes; k++)
		{
#ifdef BAREMETAL
			b_smp_enqueue(prime_process, tval);
#else
			pthread_create(&worker[k], NULL, prime_process, NULL);
#endif
		}

#ifdef BAREMETAL
		// Attempt to run a process on this CPU Core
		do {
			local = b_smp_dequeue(NULL);	// Grab a job from the queue. b_smp_dequeue returns the memory address of the code
			if (local != 0)			// If it was set to 0 then the queue was empty
				b_smp_run(local, tval);	// Run the code
		} while (local != 0);			// Abandon the loop if the queue was empty
		b_smp_wait();				// Wait for all CPU cores to finish
#else
		for (k=0; k<processes; k++)
		{
			pthread_join(worker[k], NULL);	// Wait for process k to terminate
		}
#endif

		time(&finish);				// Grab the finishing time

		// Print the results
		if (processes == 1)
		{
			singletime = difftime(finish, start);
			speedup = 1;
		}
		else
		{
			speedup = singletime / difftime(finish, start);
		}
		printf("%ld in %.0lf seconds. Speedup over 1 process: %.2lfX of maximum %ld.00X\n", primes, difftime(finish, start), speedup, processes);
	}

	return 0;
}


// prime_process() only works on odd numbers.
// The only even prime number is 2. All other even numbers can be divided by 2.
// 1 process	1: 3 5 7 ...
// 2 processes	1: 3 7 11 ...	2: 5 9 13 ...
// 3 processes	1: 3 9 15 ...	2: 5 11 17 ...	3: 7 13 19 ...			// not done when processes*=2
// 4 processes	1: 3 11 19 ...	2: 5 13 21 ...	3: 7 15 23 ...	4: 9 17 25...
// And so on.

void *prime_process(void *param)
{
	register unsigned long h, i, j, tprimes=0, iRoot=max_root, iFloor;

	// Lock process_stage, copy it to local var, subtract 1 from process_stage, unlock it.
#ifdef BAREMETAL
	b_system_misc(smp_lock, &lock, 0);
#else
	pthread_mutex_lock(&mutex1);
#endif

	iFloor = (process_stage * 2) + 1;
	process_stage--;

#ifdef BAREMETAL
	b_system_misc(smp_unlock, &lock, 0);
#else
	pthread_mutex_unlock(&mutex1);
#endif

	h = processes * 2;

	// Process
	for(i = max_number - (max_number - iFloor) % h; i>=iFloor; i-=h)
	{
		// use a step of Babylonian to find root of i
		// I think one step is probably ok until around h >= 64379, then you may need two steps
		iRoot = (iRoot + i / iRoot) / 2;
		// end root algo
		
		for(j=3; j<=iRoot && i%j; j+=2);
		if(j>iRoot) tprimes++;
	} // Continue loop down from max number

	// Add tprimes to primes.
#ifdef BAREMETAL
	b_system_misc(smp_lock, &lock, 0);
#else
	pthread_mutex_lock(&mutex1);
#endif

	primes = primes + tprimes;

#ifdef BAREMETAL
	b_system_misc(smp_unlock, &lock, 0);
#else
	pthread_mutex_unlock(&mutex1);
#endif
}

// EOF
