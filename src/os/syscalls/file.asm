; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; File System Functions
; =============================================================================

align 16
db 'DEBUG: FILESYS  '
align 16


; This source acts as an abstraction layer between the OS and an actual File
; System driver. A check can go here to detect the actual FS used and call the
; appropriate FS driver.
;
; Example:
; os_file_read:
;	cmp [os_FS], 1	; FAT16
;	je os_fat16_file_read
;	cmp [os_FS], 2	; FAT32
;	je os_fat32_file_read
;	etc...


; -----------------------------------------------------------------------------
; os_file_read -- Read a file from disk into memory
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry is set if the file was not found or an error occured
os_file_read:
	jmp os_fat16_file_read
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_write -- Write a file from memory to disk
; IN:	RSI = Memory location of data to be written
;	RDI = Address of filename string
;	RCX = Number of bytes to write
; OUT:	Carry is set if an error occured
os_file_write:
	jmp os_fat16_file_write
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_rename -- Rename a file on disk
; IN:	RSI = Memory location of file name to change
;	RDI = Memory location of new file name
; OUT:	Carry is set if the file was not found or an error occured
os_file_rename:
	jmp $
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_delete -- Delete a file from disk
; IN:	RSI = Memory location of file name to delete
; OUT:	Carry is set if the file was not found or an error occured
os_file_delete:
	jmp os_fat16_file_delete
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_get_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_file_get_list:
	jmp os_fat16_get_file_list
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_size -- Return the size of a file on disk
; IN:	RSI = Address of filename string
; OUT:	RCX = Size in bytes
;	Carry is set if the file was not found or an error occured
os_file_get_size:
	jmp os_fat16_get_file_size
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
