# BareMetal OS - Building, Installing, and Operating #

Version 0.6.1, XX XXXXX 2013 - Return Infinity

This document details the steps needed to compile BareMetal OS, as well as how to install it on a hard drive or disk image.

This document will make use of a VMDK disk image that is already BMFS-formatted. Make sure to only use the 'BMFS-256-flat.vmdk' file. 'BMFS-256.vmdk' is just a description file for the flat disk image.

## Compiling from source ##

Download the latest stable version of BareMetal OS from GitHub: https://github.com/ReturnInfinity/BareMetal-OS/tags

Extract the ZIP file to a location of your choosing and open a Terminal/Command Prompt window to that location.

./build.sh

build.bat

## Installing ##


./install.sh BMFS-256-flat.vmdk

install.bat BMFS-256-flat.vmdk


## Copying files to/from a disk ##

Grab the latest BMFS source code from here: https://github.com/ReturnInfinity/BMFS

## Extra ##

**Help**

If you have any questions about BareMetal OS, or you're developing a similar OS and want to share code and ideas, you can post a message to the <a href="http://groups.google.com/group/baremetal-os">BareMetal OS Group</a> hosted by Google Groups.


**License**

BareMetal OS is open source and released under the 3-clause "New BSD License" (see **docs/LICENSE.TXT** in the BareMetal OS distribution). Essentially, it means you can do anything you like with the code, including basing your own project on it, providing you retain the license file and give credit to Return Infinity and the BareMetal OS developers for their work.