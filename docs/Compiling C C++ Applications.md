Building C/C++ Applications for BareMetal OS
============================================

Introduction
------------

Linux is the default development environment for BareMetal OS apps since most distributions come with all of the required tools for compiling your code. This document contains the instructions necessary for compiling C/C++ applications for BareMetal OS under Linux, Mac OS X, and Windows.

Installing the compiler in Linux
--------------------------------

As mentioned earlier the tools required may already be installed. In case they are not 

Debian/Ubuntu

	sudo apt-get update
	sudo apt-get upgrade
	sudo apt-get install build-essential nasm
	gcc --version

RedHat

	yum install gcc gcc-c++ autoconf automake nasm
	gcc --version


Installing the compiler in Mac OS X
-----------------------------------

Download and install [Xcode](http://itunes.apple.com/us/app/xcode/id497799835) via the Mac App Store.


Installing the compiler in Windows
----------------------------------

You can download the latest version of GCC for Windows from [here](http://tdm-gcc.tdragon.net/download) (Make sure to get tdm64-gcc-X.X.X).

Run the installer once it has finished downloading.

- In the setup click on 'Create'.
- Select 'MinGW-w64/TDM64 Experimental (32-bit and 64-bit)' and click next.
- The default installation directory is fine for most installs. Click next.
- For a download mirror the SourceForge Default is fine. Click next.
- Select 'All Packages' for the install type. Click next.
- Once the installation is complete click next.
- Deselect the ReadMe file option and click finish.


Compiling Your Application
--------------------------

We can start with some very basic code that uses libBareMetal.

	#include "libBareMetal.h"
	
	int start(void)
	{
		b_output("Hello world, from C!\n");
		return 0;
	}

Note that the program starts in start() instead of main().

And then the compile:

	gcc -m64 -nostdlib -nostartfiles -nodefaultlibs -mno-red-zone -o hello.o hello.c libBareMetal.c -DBAREMETAL -Ttext=0x200000
	objcopy -O binary hello.o hello.app