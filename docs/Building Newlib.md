Building the Newlib C library for BareMetal OS
==============================================

Introduction
------------

This document contains the instructions necessary to build the [Newlib](http://sourceware.org/newlib/) C library for BareMetal OS. The latest version of Newlib as of this writing is 2.1.0

Newlib gives BareMetal OS access to the standard set of C library calls like `printf()`, `scanf()`, `memcpy()`, etc.

These instructions are for executing on a 64-bit Linux host. Building on a 64-bit host saves us from the steps of building a cross compiler. The latest distribution of Ubuntu was used while writing this document.


Building Details
----------------

You will need the following Linux packages:

	autoconf libtool sed gawk bison flex m4 texinfo texi2html unzip make

Create a Newlib directory and download the latest Newlib:

	mkdir newlib
	cd newlib
	wget ftp://sourceware.org/pub/newlib/newlib-2.1.0.tar.gz

Extract it:

	tar xf newlib-2.1.0.tar.gz

Download the latest BareMetal OS source code from GitHub:

	wget https://github.com/ReturnInfinity/BareMetal-OS/zipball/master

Extract it:

	unzip master

Create a build folder alongside the extracted `newlib-2.1.0` directory:

	mkdir build

Modify the following files:

	newlib-2.1.0/config.sub
	@ Line 1358
	  	      | -sym* | -kopensolaris* \
	  	      | -amigaos* | -amigados* | -msdos* | -newsos* | -unicos* | -aof* \
	  	      | -aos* | -aros* \
	+ 	      | -baremetal* \
	  	      | -nindy* | -vxsim* | -vxworks* | -ebmon* | -hms* | -mvs* \
	  	      | -clix* | -riscos* | -uniplus* | -iris* | -rtu* | -xenix* \
	  	      | -hiux* | -386bsd* | -knetbsd* | -mirbsd* | -netbsd* \
	
	newlib-2.1.0/newlib/configure.host
	@ Line 542
	    z8k-*-coff)
	  	sys_dir=z8ksim
	  	;;
	+   x86_64-*-baremetal*)
	+ 	sys_dir=baremetal
	+ 	;;
	  esac
	
	newlib-2.1.0/newlib/libc/sys/configure.in
	@ Line 50
	  	tic80) AC_CONFIG_SUBDIRS(tic80) ;;
	  	w65) AC_CONFIG_SUBDIRS(w65) ;;
	  	z8ksim) AC_CONFIG_SUBDIRS(z8ksim) ;;
	+ 	baremetal) AC_CONFIG_SUBDIRS(baremetal) ;;
	    esac;
	  fi

In `newlib-2.1.0/newlib/libc/sys` create a directory called `baremetal`:

	mkdir newlib-2.1.0/newlib/libc/sys/baremetal

Copy the contents of the `newlib/baremetal` directory from the BareMetal OS code into the `newlib/libc/sys/baremetal` directory.

Refresh the configuration files:

	cd newlib-2.1.0/newlib/libc/sys
	autoconf
	cd baremetal
	autoreconf
	cd ../../../../..

Change directory to the `build` directory that was created earlier.

Run the following:

	../newlib-2.1.0/configure --target=x86_64-pc-baremetal --disable-multilib

Edit the Makefile with the following commands. This will instruct the compiler to use the default applications instead of looking for a special cross-compiler that does not exist (and is not necessary).

	sed -i 's/TARGET=x86_64-pc-baremetal-/TARGET=/g' Makefile
	sed -i 's/WRAPPER) x86_64-pc-baremetal-/WRAPPER) /g' Makefile

Optional: You may also want to add `-mcmodel=large` if you plan on running programs in the high canonical address range.

Run the following:

	make

After a lengthy compile you should have an 'etc' and 'x86_64-pc-baremetal' in your build directory

build/x86_64-pc-baremetal/newlib/libc.a is the compiled C library that is ready for linking. build/x86_64-pc-baremetal/newlib/crt0.o is the starting binary stub for your program.

	cd x86_64-pc-baremetal/newlib/
	cp libc.a ../../..
	cp crt0.o ../../..
	cd ../../..

By default libc.a will be about 5.5 MiB. You can `strip` it to make it a little more compact. `strip` can decrease it to about 1.2 MiB.

	strip --strip-debug libc.a

Compiling Your Application
--------------------------

By default GCC will look in predefined system paths for the C headers. This will not work correctly as we need to use the Newlib C headers. Using the `-I` argument we can point GCC where to find the correct headers. Adjust the path as necessary.

	gcc -I newlib-2.1.0/newlib/libc/include/ -c test.c -o test.o
	ld -T app.ld -o test.app crt0.o test.o libc.a
