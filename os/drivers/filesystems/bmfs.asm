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
	push rax
	push rcx
	push rdx
	push rdi

	; Load the directory -- 4KiB @ sector 8
	mov rax, 8
	mov rcx, 8
	mov rdx, [sata_port]
	mov rdi, hd_directory
	call readsectors

	; TODO: create the free list

	pop rdi
	pop rdx
	pop rcx
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_ptr -- Search for a file name and return its directory
; entry's address
; IN:	RSI = Pointer to file name
; OUT:	RAX = Directory entry address
;	Carry set if not found. If carry is set then ignore value in RAX
os_bmfs_file_get_ptr:
	push rdi

	clc				; Clear carry
	mov rdi, hd_directory		; beginning of directory structure

.next:
	call os_string_compare
	jc .done
	add rdi, 64			; next record
	cmp rdi, hd_directory + 0x1000	; end of directory
	je .notfound
	jmp .next

.notfound:
	stc
	xor rdi, rdi

.done:
	mov rax, rdi
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_find_file -- Search for a file name and return the starting block
; IN:	RSI = Pointer to file name
; OUT:	RAX  = Staring block number
;	RCX = File size in bytes
;	Carry set if not found. If carry is set then ignore value in RAX
os_bmfs_find_file:
	push rsi

	call os_bmfs_file_get_ptr		; file idx in rax, or carry set
	jc .notfound

	mov rsi, rax

	mov rax, [rsi + BMFS_DirEnt.start]	; Starting block number
	mov rcx, [rsi + BMFS_DirEnt.size]	; Size in bytes
	jmp .done

.notfound:
	xor rax, rax
	xor rcx, rcx
	stc

.done:
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
	push rdx

; Check to see if the file exists
	call os_bmfs_find_file		; Fuction will return the starting cluster value in RAX or carry set if not found
	jc .done			; If Carry is clear then the file exists. RAX is set to the starting block

.read:
	; Read the file
	call readsectors
	clc				; Clear Carry

.done:
	pop rdx
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
	push rax
	clc

	; Check to see if the file exists
	call os_bmfs_file_get_ptr
	jnc .error	; If not, throw an error


	; TODO: Ensure the file will fit within its reserved space

.write:
	; TODO: Write file to disk in 4MiB blocks (max per call to writesectors)
	; TODO: Update file directory entry with bytes written
	; TODO: Update directory entry CRC32
	; TODO: Rewrite the directory table

	jmp .done

.error:
	stc

.done:
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_create -- Create a file on the hard disk
; IN:	RSI = Pointer to file name, must be <= 32 characters
;	RCX = File size to reserve (rounded up to the nearest 2MiB)
; OUT:	Carry clear on success, set on failure
; Note:	This function pre-allocates all blocks required for the file
os_bmfs_file_create:
	push rax
	clc

	call os_bmfs_file_get_ptr	; Check if file exists, error if so
	jnc .error

	;

	jmp .done

.error:
	stc

.done:
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_bmfs_file_delete:
	push rax
	clc				; Clear carry

	call os_bmfs_file_get_ptr	; find the file's directory entry
	jc .error
	; TODO: Add deleted marker to file name
	; TODO: Recalculate free list
	; TODO: Update directory entry CRC32
	; TODO: Rewrite the directory table

	jmp .done

.error:
	stc				; Set carry

.done:
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_size -- Return a file's size
; IN:	RSI = Address of filename string
; OUT:	RCX = Size of file in bytes
;	Carry clear on success, set if file was not found or error occured
os_bmfs_file_get_size:
	push rax

; Check to see if the file exists
	call os_bmfs_file_get_ptr
	jc .error
	mov rcx, [rax + BMFS_DirEnt.size]

	jmp .done

.error:
	stc
	xor rcx, rcx

.done:
	pop rax
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
