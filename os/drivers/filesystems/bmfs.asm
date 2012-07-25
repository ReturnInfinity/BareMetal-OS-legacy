; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; BMFS Functions
; =============================================================================

align 16
db 'DEBUG: BMFS    '
align 16

; -----------------------------------------------------------------------------
; os_bmfs_setup -- Initialize BMFS data structures
os_bmfs_setup:

ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_find_file -- Search for a file name and return the starting block
; IN:	RSI = Pointer to file name
; OUT:	RAX  = Staring cluster
;	RCX = File size
;	Carry set if not found. If carry is set then ignore value in RAX
os_bmfs_find_file:
	push rsi
	push rdi
	push rdx
	push rbx

	clc				; Clear carry

os_bmfs_find_file_notfound:
	stc				; Set carry
	xor rax, rax

os_bmfs_find_file_done:
	stc
wut:
	pop rbx
	pop rdx
	pop rdi
	pop rsi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_bmfs_file_get_list:
	push rsi
	push rdi
	push rcx
	push rbx
	push rax

os_bmfs_get_file_list_done:
	mov al, 0x00
	stosb

	pop rax
	pop rbx
	pop rcx
	pop rdi
	pop rsi
ret

dir_title_string: db "Name        Size", 13, "====================", 13, 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_read -- Read a file from disk into memory
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry clear on success, set if file was not found or error occured
os_bmfs_file_read:
	push rsi
	push rdi
	push rcx			; Used by os_bmfs_find_file
	push rax

; Check to see if the file exists
	call os_bmfs_find_file		; Fuction will return the starting cluster value in RAX or carry set if not found
	jc os_bmfs_file_read_done	; If Carry is clear then the file exists. RAX is set to the starting block

os_bmfs_file_read_read:
	; Read the whole file in one go
	clc				; Clear Carry

os_bmfs_file_read_done:
	pop rax
	pop rcx
	pop rdi
	pop rsi
ret

; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_write -- Write a file to the hard disk
; IN:	RSI = Address of data in memory
;	RDI = File name to write
;	RCX = number of bytes to write
; OUT:	Carry clear on success, set on failure
os_bmfs_file_write:
	push rsi
	push rdi
	push rcx
	push rax

	stc

os_bmfs_file_write_done:
	pop rax
	pop rcx
	pop rdi
	pop rsi
ret

	os_bmfs_file_write_string	times 32 db 0
	memory_address			dq 0x0000000000000000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_create -- Create a file on the hard disk
; IN:	RSI = Pointer to file name, must be <= 32 characters
;	RCX = File size
; OUT:	Carry clear on success, set on failure
; Note:	This function pre-allocates all clusters required for the size of the file
os_bmfs_file_create:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	clc				; Clear the carry flag. It will be set if there is an error

os_bmfs_file_create_fail:
	stc
	call os_speaker_beep

os_bmfs_file_create_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
ret

	filename	times 32 db 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_bmfs_file_delete:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx

	clc				; Clear carry

os_bmfs_file_delete_error:
	xor rax, rax
	stc				; Set carry

os_bmfs_file_delete_done:
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
ret

	os_bmfs_file_delete_string	times 32 db 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_size -- Read a file from disk into memory
; IN:	RSI = Address of filename string
; OUT:	RCX = Size of file in bytes
;	Carry clear on success, set if file was not found or error occured
os_bmfs_file_get_size:
	push rsi
	push rdi
	push rax
	xor ecx, ecx

; Check to see if the file exists
	call os_bmfs_find_file		; Fuction will return the starting cluster value in AX and size in ECX or carry set if not found

os_bmfs_file_get_size_done:
	pop rax
	pop rdi
	pop rsi
ret

	os_bmfs_file_get_size_string	times 32 db 0
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
