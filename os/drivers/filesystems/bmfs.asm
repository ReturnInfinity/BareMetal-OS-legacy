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
; init_bmfs -- Initialize the BMFS driver
init_bmfs:
	push rdi
	push rdx
	push rcx
	push rax

	; Read directory to memory
	mov rax, 8			; Start to read from 4K in
	mov rcx, 8			; Read 8 sectors (4KiB)
	xor edx, edx			; Read from drive 0
	mov rdi, bmfs_directory
	call readsectors

	; Get total blocks
	mov eax, [hd1_size]		; in mebibytes (MiB)
	shr rax, 1
	mov [bmfs_TotalBlocks], rax

	pop rax
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_read -- Read a file from disk into memory. The destination
; buffer must be large enough to store the entire file, rounded up to the next
; 2 MiB.
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry clear on success, set if file was not found or error occured
os_bmfs_file_read:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	call os_bmfs_file_query
	jc os_bmfs_file_read_done

	add rcx, 511			; Convert byte count to the number of sectors required to fit
	shr rcx, 9
	shl rax, 12			; Multiply block start count by 4096 to get sector start count
	mov rbx, rcx
	xor edx, edx			; Read from drive 0

os_bmfs_file_read_loop:
	mov rcx, 4096			; Read 2MiB at a time
	cmp rbx, rcx
	jg os_bmfs_file_read_read
	mov rcx, rbx

os_bmfs_file_read_read:
	call readsectors
	sub rbx, rcx
	jnz os_bmfs_file_read_loop

os_bmfs_file_read_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_write -- Write a file to the hard disk
; IN:	RSI = Address of data in memory
;	RDI = File name to write
;	RCX = number of bytes to write
; OUT:	Carry clear on success, set on failure
os_bmfs_file_write:

	; Flush directory to disk

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_create -- Create a file on the hard disk
; IN:	RSI = Pointer to file name, must be <= 32 characters
;	RCX = File size to reserve (rounded up to the nearest 2MiB)
; OUT:	Carry clear on success, set on failure
; Note:	This function pre-allocates all blocks required for the file
os_bmfs_file_create:

	; Flush directory to disk

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_bmfs_file_delete:
	push rdx
	push rcx
	push rbx
	push rax

	call os_bmfs_file_query
	jc os_bmfs_file_delete_notfound

	mov byte [rbx + BMFS_DirEnt.filename], 0x01 ; Add deleted marker to file name

	; Flush directory to disk

os_bmfs_file_delete_notfound:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_query -- Search for a file name and return information
; IN:	RSI = Pointer to file name
; OUT:	RAX = Staring block number
;	RBX = Offset to entry
;	RCX = File size in bytes
;	RDX = Reserved blocks
;	Carry set if not found. If carry is set then ignore returned values
os_bmfs_file_query:
	push rdi

	clc				; Clear carry
	mov rdi, bmfs_directory		; Beginning of directory structure

os_bmfs_file_query_next:
	call os_string_compare
	jc os_bmfs_file_query_found
	add rdi, 64			; Next record
	cmp rdi, bmfs_directory + 0x1000	; End of directory
	jne os_bmfs_file_query_next
	stc				; Set flag for file not found
	pop rdi
	ret

os_bmfs_file_query_found:
	clc				; Clear flag for file found
	mov rbx, rdi
	mov rdx, [rdi + BMFS_DirEnt.reserved]	; Reserved blocks
	mov rcx, [rdi + BMFS_DirEnt.size]	; Size in bytes
	mov rax, [rdi + BMFS_DirEnt.start]	; Starting block number

	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_bmfs_file_list:
	push rsi
	push rdx
	push rcx
	push rbx
	push rax

	mov rsi, dir_title_string	; Copy the header string
	call os_string_length
	call os_string_copy
	add rdi, rcx

	mov rsi, bmfs_directory
	mov rbx, rsi

os_bmfs_file_list_next:
	cmp byte [rbx], 0x01
	jle os_bmfs_file_list_skip

	mov rsi, rbx			; Copy filename to destination
	call os_string_length		; Get the length before copying
	call os_string_copy
	add rdi, rcx			; Remove terminator

	sub rcx, 32			; Pad out to 32 characters
	neg rcx
	mov al, ' '
	rep stosb

	mov rax, [rbx + BMFS_DirEnt.size]
	call os_int_to_string
	dec rdi
	mov al, 13
	stosb

os_bmfs_file_list_skip:
	add rbx, 64			; Next record
	cmp rbx, bmfs_directory + 0x1000	; End of directory
	jne os_bmfs_file_list_next

os_bmfs_file_list_done:
	mov al, 0x00			; Terminate the string
	stosb

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret

dir_title_string: db "Name                            Size", 13, \
	"====================================", 13, 0
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
