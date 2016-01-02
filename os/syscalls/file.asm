; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; File System Abstraction Layer
;
; The file system driver needs to support the following 6 commands:
;
; open, close, read, write, seek, query, create, delete
;
; =============================================================================

align 16
db 'DEBUG: FILESYS  '
align 16


; -----------------------------------------------------------------------------
; os_file_open -- Open a file on disk
; IN:	RSI = File name (zero-terminated string)
; OUT:	RAX = File I/O handler number, 0 on error
;	All other registers preserved
os_file_open:
	jmp os_bmfs_file_open
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_close -- Close an open file
; IN:	RAX = File I/O handler
; OUT:	All registers preserved
os_file_close:
	jmp os_bmfs_file_close
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_read -- Read a number of bytes from a file
; IN:	RAX = File I/O handler
;	RCX = Number of bytes to read
;	RDI = Destination memory address
; OUT:	RCX = Number of bytes read
;	All other registers preserved
os_file_read:
	jmp os_bmfs_file_read
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_write -- Write a number of bytes to a file
; IN:	RAX = File I/O handler
;	RCX = Number of bytes to write
;	RSI = Source memory address
; OUT:	RCX = Number of bytes written
;	All other registers preserved
os_file_write:
	jmp os_bmfs_file_write
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_seek -- Seek to position in a file
; IN:	RAX = File I/O handler
;	RCX = Number of bytes to offset from origin.
;	RDX = Origin
; OUT:	All registers preserved
os_file_seek:
	jmp os_bmfs_file_seek
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_query -- Query the existence of a file
; IN:	RSI = Address of file name string
; OUT:	RCX = Size in bytes
;	Carry is set if the file was not found or an error occurred
os_file_query:
	jmp os_bmfs_file_query
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_create -- Create a file on disk
; IN:	RSI = Memory location of file name to create
;	RCX = Size in bytes of the space to reserve for this file (will be
;		rounded up to the nearest 2MiB)
; OUT:	Carry is set if the file already exists or an error occurred
os_file_create:
	jmp os_bmfs_file_create
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_file_delete -- Delete a file from disk
; IN:	RSI = Memory location of file name to delete
; OUT:	Carry is set if the file was not found or an error occurred
os_file_delete:
	jmp os_bmfs_file_delete
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
