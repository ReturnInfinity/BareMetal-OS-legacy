Building BareMetal OS
=====================

Introduction
------------

This document describes how to build BareMetal OS. These instructions have been tested on Linux Mint 14 and Ubuntu 13.04, but should also work on most linux machines.

The original author of this document is [Klāvs Priedītis](https://gist.github.com/klavs/5808455).


Preparing local environment
---------------------------

To keep things organized you should create a separate directory for BareMetal OS and its related projects.

	mkdir ~/ReturnInfinity
	cd ~/ReturnInfinity

It is assumed that all of the following instructions will be run from this directory.


Getting the latest sources from GitHub
--------------------------------------

To get the latest sources from GitHub enter the following instructions:

	git clone https://github.com/ReturnInfinity/BMFS.git
	git clone https://github.com/ReturnInfinity/Pure64.git
	git clone https://github.com/ReturnInfinity/BareMetal-OS.git

After this your base directory will contain three subdirectories:

	BareMetal-OS
	BMFS
	Pure64


Creating build directory
------------------------

To keep the original source directories clean, you should not execute instructions from those directories. A better way would be to create separate build directory where you could execute scripts, alter files, etc.

	mkdir build
	cd build
	cp -r ../BareMetal-OS ./
	cp -r ../BMFS ./
	cp -r ../Pure64 ./

For the current version of this document I recommend to create another directory where to put the dependencies of BareMetal OS.

	mkdir target


Building Pure64
---------------

This step is quite easy. Just navigate to the Pure64 directory and run build.sh script and copy the binaries to target directory.

	cd Pure64
	./build.sh
	mv bmfs_mbr.sys ../target/
	mv pxestart.sys ../target/
	mv pure64.sys ../target/
	cd ..


Building BMFS
-------------

To build BMFS you only need to navigate to BMFS directory and compile bmfs.c file with a C compiler. You can do this by executing make 

	cd BMFS
	make
	mv bmfs ../target/
	cd ..


Building BareMetal OS kernel
----------------------------

In this step you only need to build kernel. In the next steps BareMetal OS will be compiled using all the deliveries built so far.

	cd BareMetal-OS
	./build.sh
	mv kernel64.sys ../target/
	cd ..


Creating BMFS disk image
------------------------

To create BMFS formatted disk image you will need to use dd and bmfs tool created earlier. The following commands will create a 128 MiB image. If you want to create differently sized image you can change the count parameter of dd command. The bmfs tool will ask you to confirm if you want to format the image.

	cd target
	dd if=/dev/zero of=bmfs.image bs=1M count=128
	./bmfs bmfs.image format


Make BMFS image bootable with BareMetal OS
------------------------------------------
Now you can combine Pure64 and the BareMetal OS kernel to make a bootable BMFS image. Then I will use install.sh script from BareMetal-OS. This script adds Master Boot Record to the image and then combines Pure64 with kernel and adds it to the image.

	cp ../BareMetal-OS/install.sh ./
	./install.sh bmfs.image

	
Create .vmdk virtual disk
-------------------------

In order to use BareMetal OS in virtual machine, you need to change this image to a virtual disk format, for example .vmdk format is supported by VirtualBox and other virtualization environments. This step uses qemu-img tool. If you do not have, try to get it using your package manager.

	qemu-img convert -O vmdk bmfs.image baremetal_os.vmdk

Now you have a BareMetal OS image ready to be used in VirtualBox.


Further steps
-------------

Next you can start using BareMetal OS in VirtualBox. Remember that BareMetal OS does not support an IDE controller, you must set your virtual machine to use a SATA controller instead. Also the IO APIC must be enabled.

As you may have noticed, BareMetal OS comes with no many features. If you would like to write applications in C it is possible using newlib. To do that, newlib must be compiled. That is a step which is documented in BareMetal-OS/docs/Building Newlib.md. Assembly programs may be assembled by any assembler, but nasm is used in OS development.

If you want to know how to put files in your filesystem, read it in BMFS/README.md. You should do these steps before converting it to .vmdk format.

