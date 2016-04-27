# BareMetal OS -- a 64-bit OS written in Assembly for x86-64 systems #

[![Join the chat at https://gitter.im/ReturnInfinity/BareMetal-OS](https://badges.gitter.im/ReturnInfinity/BareMetal-OS.svg)](https://gitter.im/ReturnInfinity/BareMetal-OS?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Copyright (C) 2007-2015 Return Infinity -- see LICENSE.TXT

BareMetal is a 64-bit OS for x86-64 based computers. The OS is written entirely in Assembly, while applications can be written in Assembly, C/C++, and Rust. Development of the Operating System is guided by its 3 target segments:

* **High Performance Computing** - Act as the base OS for a HPC cluster node. Running advanced computation workloads is ideal for a mono-tasking Operating System.
* **Embedded Applications** - Provide a platform for embedded applications running on commodity x86-64 hardware.
* **Education** - Provide an environment for learning and experimenting with programming in x86-64 Assembly as well as Operating System fundamentals.

BareMetal is a 64-bit protected mode operating system for x86-64 compatible PCs, written entirely in assembly language, which boots from a hard drive or via the network. It features a command-line interface, support for [BMFS-formatted](https://github.com/ReturnInfinity/BMFS) hard drives and sound via the PC speaker. It can load external programs and has over 60 system calls. BareMetal can also utilize all available CPU's in the computer it is run on.

At the moment there is no plan to build BareMetal into a general-purpose operating system like Windows, Mac OS X, or Linux; it is designed to be as lean as possible while still offering useful features.

The complete documentation for BareMetal, including instructions on running it, building it and writing your own programs for it can be found in the docs/ directory.

See LICENSE.TXT for redistribution/modification rights, and CREDITS.TXT for a list of people involved.

Ian Seyler (ian.seyler@returninfinity.com)
