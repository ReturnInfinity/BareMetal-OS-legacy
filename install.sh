#!/bin/sh

if (($# != 1))
then
	echo Disk parameter required.
	exit 1
fi
echo Writing Master Boot Record to $1
dd if=bmfs_mbr.sys of=$1 bs=512 conv=notrunc
echo Writing Pure64+Software to $1
cat pure64.sys kernel64.sys > software.sys
dd if=software.sys of=$1 bs=512 seek=16 conv=notrunc
