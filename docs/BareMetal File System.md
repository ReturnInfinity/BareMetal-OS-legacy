# BareMetal OS File System (BMFS) - Version 1

BMFS is a new file system used by BareMetal OS and its related systems. The design is extremely simplified compared to conventional file systems. The system is also geared more toward a small number of very large files (databases, large data files). BMFS was inspired by the [RT11 File System](http://en.wikipedia.org/wiki/RT11#File_system).

## Characteristics:

- Very simple layout
- All files are contiguous
- Disk is divided into 2 MiB blocks
- Flat organization; no subdirectories/subfolders

## Disk structure

**Blocks**

For simplicity, BMFS acts as an abstraction layer where a number of contiguous [sectors](http://en.wikipedia.org/wiki/Disk_sector) are accessed instead of individual sectors. With BMFS, each disk block is 2MiB. The disk driver will handle the optimal way to access the disk (based on if the disk uses 512 byte sectors or supports the new [Advanced Format](http://en.wikipedia.org/wiki/Advanced_Format) 4096 byte sectors).

**Free Blocks**

Of the several different approaches to managing free space on a disk, BMFS uses a bitmap scheme for simplicity. The bitmap scheme represents each disk block as 1 bit, and the file system views the entire disk as an array of these bits. If a bit is on (i.e., a one), the corresponding block is allocated. The formula for the amount of space (in bytes) required for a block bitmap is:

	disk size in bytes / (file system block size in bytes * 8)

Thus, the bitmap for a 2TiB disk with 2MiB blocks requires 128KiB of space. BMFS allocates 1MiB for the free block bitmap, allowing it to support a disk up to 16TiB.

**Disk layout**

The first two disk blocks are reserved for file system usage. All other disk blocks can be used for data.

	Block 0:
	4KiB - Legacy MBR Boot sector (512B)
	     - Free space (512B)
	     - Disk information (512B)
	     - Free space (512B)
	4KiB - Directory (Max 64 files, 64-bytes for each record)
	Free space (1016KiB)
	1MiB - Free space bitmap (Supports a drive up to 16TiB)
	
	Block 1:
	Reserved
	
	Block 2 .. n:
	Data

**Directory**

BMFS supports a single directory with a maximum of 64 individual files. Each file record is 64 bytes. The directory structure is 4096 bytes and starts at sector 8.

**Directory Record structure**:

	Filename (32 bytes) - Null-terminated ASCII string
	Starting Block number (64-bit unsigned int)
	Blocks reserved (64-bit unsigned int)
	File size (64-bit unsigned int)
	Unused (8 bytes)

A filename that starts with 0x00 marks the end of the directory. A filename that starts with 0x01 marks an unused record.

Maximum file size supported is 18,446,744,073,709,551,614 bytes (~18 EiB) with a maximum of 9,223,372,036,854,775,807 allocated blocks.

## Files

The following system calls should be available:

- Create (Create and reserve space for a new file)
- Delete (Delete an existing file from the file system)
- Read (Read a file into system memory)
- Write (Write a section of system memory to a file)
- Directory/List (Prepare and display a list of file)
- Query (Query the existance/details of a file)

# Create

The create function accepts two parameters:

	Name = A null-terminated string no more that 31 characters
	Reserved = The number of blocks to reserve for the file


# Delete

The delete function accepts one parameter:

	Name = The name of the file to delete


# Read

The read function accepts two parameters:

	Name = The name of the file to read
	Destination = The memory address to store the file


# Write

The write function accepts three parameters:

	Name = The name of the file to write
	Source = The memory address of the data
	Size = The amount of bytes to write


# Directory/List

The dir/ls function accepts no parameters


# Query

The query function accepts one parameter:

	Name = The name of the file to query

The query function will return the following:

	Size = The current size of the file in bytes (0 if it doesn't exist)
	Reserved = The amount of blocks reserved for the file

