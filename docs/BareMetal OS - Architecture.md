# BareMetal OS - Architecture #

Version 0.6.0, 2 April 2013 - Return Infinity

This document details the architecture of BareMetal OS and how it differs from other Operating Systems.

## Introduction to BareMetal OS ##

BareMetal OS is a new Operating System being written by Return Infinity. There are a few key differences that make it stand apart from other Operating Systems that are currently available:

- **64-Bit Only** No backwards compatibility here! BareMetal OS has been written from scratch for modern 64-bit computers with CPUs using the [x86-64](http://en.wikipedia.org/wiki/X86-64) architecture. Operating in 64-bit mode has several [new features](http://en.wikipedia.org/wiki/X86-64#Architectural_features) that offer advantages over 32-bit mode. BareMetal OS makes use of the [Pure64](https://github.com/ReturnInfinity/Pure64) boot-loader to get the computer and all of its CPUs into 64-bit mode, gather and store valuable system information, and to load the BareMetal OS binary.

- **Written in 100% Assembly language** Most Operating Systems are written in high level languages like C or C++. High level languages are great if you want your code to compile for running on different kinds of hardware but it also adds another layer of abstraction to the overall picture. BareMetal OS is written in Assembly (also known as machine code) and targets the X86-64 CPU architecture only. While writing code in Assembly language is a bit more difficult you have the advantage of being in full control of what the CPU is executing at any given time. Assembly also lets us focus on optimization of the code at the core level.

- **Mono-tasking** The philosophy behind BareMetal OS is to run one application at a time. Multitasking adds complexity to the overall system as well as degraded performance due to the protection mechanisms necessary in a multitasking system. While BareMetal OS is a mono-tasking system it does allow for [multiprocessing](http://en.wikipedia.org/wiki/Symmetric_multiprocessing) to submit sub-tasks to other available CPUs.

- **Multiprocessor** The computer industry is undergoing a paradigm shift as chip manufacturers are shifting development resources away from single-processor chips to a new generation of multi-processor chips. This fundamental change in our core computing architecture requires a fundamental change in how we program in order to optimize the use of the CPU resources that are available. BareMetal OS includes system calls to utilize all available CPU's. BareMetal OS currently supports up to 128 x86-64 processors.

- **No GUI** A graphical user interface is great for today's modern multitasking OS's but is not necessary for a mono-tasking system. BareMetal OS has a CLI (Command Line Interface) for a more simplified operating environment.

- **Size** The current size of the BareMetal OS kernel binary is 16384 bytes (16KiB). In actuality the size of the kernel code is only about 10000 bytes with the additional space being used as padding. The memory footprint of the OS, while running, is less than 512KiB, the majority of this being the [Page Table](http://en.wikipedia.org/wiki/Page_table) structures in memory that are needed for 64-bit operation and the individual stacks for each CPU.

- **Open Source** The source code for BareMetal OS is freely available. Feel free to modify anything to more fit your needs. If you create a function that others would find useful you may submit your code to have it included in future versions. All source code is heavily commented to give you a better understanding of what is going on and how this work. The BSD license allows you to do anything you like with the code, including basing your own project on it, providing you retain the license file and give credit to Return Infinity and the BareMetal OS developers for their work.

- **Simplicity** We believe that simplicity is key in creating a lean and powerful Operating System.

## Goals ##

BareMetal OS development is being guided by three main goals.

**High Performance Computing** - Act as the base OS for a HPC cluster node. Running advanced computation workloads is ideal for a mono-tasking Operating System.

**Embedded Applications** - Provide a platform for embedded applications running on commodity x86-64 hardware.

**Education** - Provide an environment for learning and experimenting with programming in x86-64 Assembly as well as Operating System fundamentals.


## Overview of System ##

The architecture of BareMetal OS isn't anything new. In fact if you have been around computers long enough it should remind you of something like [DOS](http://en.wikipedia.org/wiki/DOS). What is new is that we are applying this concept to today's 64-bit computers.

![](https://raw.github.com/ReturnInfinity/BareMetal-OS/master/docs/images/OS%20Diagram%20-%20BareMetal.png)

As you can see in the above diagram both the running application as well as the OS have full access to the underlying hardware. In BareMetal OS the kernel as well as the running application are in "[Ring 0](http://en.wikipedia.org/wiki/Ring_%28computer_security%29)". Mono-tasking allows us to keep costly [context switches](http://en.wikipedia.org/wiki/Context_switch) to an absolute minimum. While the application is running the OS mainly stays out of the way, only providing system calls if the application asks.

![](https://raw.github.com/ReturnInfinity/BareMetal-OS/master/docs/images/OS%20Diagram%20-%20Standard.png)

As you can see in the above diagram the application runs on top of the OS. Only the OS has full access to the underlying hardware. In this configuration the OS kernel runs in "Ring 0" and the application(s) run in "Ring 3". This layout works very well for multi-tasking OS's as it keeps the application from doing any damage to the OS or causing a complete system crash.


## Extra ##

**Help**

If you have any questions about BareMetal OS, or you're developing a similar OS and want to share code and ideas, you can post a message to the <a href="http://groups.google.com/group/baremetal-os">BareMetal OS Group</a> hosted by Google Groups.


**License**

BareMetal OS is open source and released under the 3-clause "New BSD License" (see **docs/LICENSE.TXT** in the BareMetal OS distribution). Essentially, it means you can do anything you like with the code, including basing your own project on it, providing you retain the license file and give credit to Return Infinity and the BareMetal OS developers for their work.