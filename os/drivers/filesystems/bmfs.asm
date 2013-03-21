; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; BMFS Functions
; =============================================================================

align 16
db 'DEBUG: BMFS    '
align 16


; -----------------------------------------------------------------------------
; os_bmfs_file_read -- Read a file from disk into memory. The destination
; buffer must be large enough to store the entire file, rounded up to the next
; 2 MiB.
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry clear on success, set if file was not found or error occured
os_bmfs_file_read:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_write -- Write a file to the hard disk
; IN:	RSI = Address of data in memory
;	RDI = File name to write
;	RCX = number of bytes to write
; OUT:	Carry clear on success, set on failure
os_bmfs_file_write:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_create -- Create a file on the hard disk
; IN:	RSI = Pointer to file name, must be <= 32 characters
;	RCX = File size to reserve (rounded up to the nearest 2MiB)
; OUT:	Carry clear on success, set on failure
; Note:	This function pre-allocates all blocks required for the file
os_bmfs_file_create:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_bmfs_file_delete:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_find_file -- Search for a file name and return the starting block
; IN:	RSI = Pointer to file name
; OUT:	RAX  = Staring block number
;	RCX = File size in bytes
;	Carry set if not found. If carry is set then ignore value in RAX
os_bmfs_file_query:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_bmfs_file_get_list:

	ret

dir_title_string: db "Name                            Size", 13, \
	"====================================", 13, 0
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
