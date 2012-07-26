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

	pop rdi
	pop rdx
	pop rcx
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_write_directory -- Rewrite the BMFS directory sectors
; TODO: write a copy to the end of the disk as well; add a version marker to
; track which version of the block was written
os_bmfs_write_directory:
	push rax
	push rcx
	push rdx
	push rsi

	; Save the directory -- 4KiB @ sector 8
	mov rax, 8
	mov rcx, 8
	mov rdx, [sata_port]
	mov rsi, hd_directory
	call writesectors

	pop rsi
	pop rdx
	pop rcx
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_update_dirent_crc32 -- Update the CRC32 for a directory entry
; IN: RAX = pointer to the start of the directory entry
; TODO: This is horrifically inefficient; consider using CRC32 instruction
; instead, although it's only available on Core i7 and up.
os_bmfs_update_dirent_crc32:
	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push rsi

	mov rsi, rax
	mov rdi, 56			; 32 bytes filename + 8 start + 8 reserved + 8 size

	mov ecx, -1
	mov edx, ecx
.nextbyte:				;next byte from buffer
	xor eax, eax
	xor ebx, ebx
	lodsb				;get next byte
	xor al, cl
	mov cl, ch
	mov ch, dl
	mov dl, dh
	mov dh, 8
.nextbit:				;next bit in the byte
	shr bx, 1
	rcr ax, 1
	jnc .nocarry			;jump to nocarry if carry flag not set
	xor ax, 0x08320
	xor bx, 0x0EDB8
.nocarry:				;if carry flag wasn't set
	dec dh
	jnz .nextbit
	xor ecx, eax
	xor edx, ebx
	dec rdi				;finished with that byte, decrement counter
	jnz .nextbyte			;if edi counter isnt at 0, jump to nextbyte
	not edx
	not ecx
	mov eax, edx
	rol eax, 16
	mov ax, cx

	mov [rsi + BMFS_DirEnt.crc32], eax	;crc32 result is in eax
.done:
	pop rsi
	pop rdi
	pop rdx
	pop rcx
	pop rbx
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
	jne .next

	; Not found
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

	; TODO

.done:
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
; os_bmfs_file_read -- Read a file from disk into memory. The destination
; buffer must be large enough to store the entire file, rounded up to the next
; 512 bytes.
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry clear on success, set if file was not found or error occured
os_bmfs_file_read:
	push rcx			; Used by os_bmfs_find_file
	push rax
	push rdx
	push rbx

	; Check to see if the file exists
	call os_bmfs_find_file		; Fuction will return the starting cluster value in RAX or carry set if not found
	jc .error			; Does not exist, return error

	clc

	add rcx, 1			; Convert byte count to the number of sectors required to fit
	shr rcx, 9

	mov rbx, rcx
	mov rdx, [sata_port]
	mov rax, [rax + BMFS_DirEnt.start]

.loop:
	; Ensure reads are for no more than 4MiB at a time
	mov rcx, 8192
	cmp rbx, rcx
	jg .read

	mov rcx, rbx

.read:
	; Read the file to rdi
	call readsectors
	jc .error

	sub rbx, rcx
	jnz .loop

	jmp .done

.error:
	stc

.done:
	pop rbx
	pop rdx
	pop rax
	pop rcx
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
	push rdx
	push rbx

	; Check to see if the file exists
	mov r8, rsi
	mov rsi, rdi
	call os_bmfs_file_get_ptr
	mov rsi, r8
	mov r9, rax

	jnc .error	; If not, throw an error

	; Ensure the file will fit within its reserved space
	mov rbx, rcx
	add rbx, 1			; Convert byte count to the number of 2MiB blocks
	shr rbx, 21

	mov rdx, [r9 + BMFS_DirEnt.reserved]
	cmp rbx, rdx
	jg .error			; Write too large to fit in file

	mov r8, rcx ; Save byte count for later

	; Determine number of sectors to write
	mov rbx, rcx
	add rbx, 1
	shr rbx, 9

	; Set up the write
	mov rax, [r9 + BMFS_DirEnt.start]
	mov rdx, [sata_port]

.loop:
	; Ensure writes are for no more than 4MiB at a time
	mov rcx, 8192
	cmp rbx, rcx
	jg .write

	mov rcx, rbx

.write:
	; Write the file from rsi
	call writesectors
	jc .error

	sub rbx, rcx
	jnz .loop

	; Update file directory entry with count of bytes written (r8)
	mov [r9 + BMFS_DirEnt.size], r8

	; Update directory entry CRC32
	mov rax, r9
	call os_bmfs_update_dirent_crc32

	; Rewrite the directory table
	call os_bmfs_write_directory

	jmp .done

.error:
	stc

.done:
	pop rbx
	pop rdx
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
	push rdi

	call os_bmfs_file_get_ptr	; Check if file exists, error if so
	jnc .error

	clc

	; Convert bytes reserved to 2MiB blocks, rounding up
	inc rcx
	shr rcx, 21

	; TODO: Look for a free block large enough for this file

	; Find a free directory entry, set it up for this file
	mov rdi, 0			; beginning of directory structure

.next:
	cmpb [rdi*64 + hd_directory], 0x01
	jle .found
	inc rdi				; next record
	cmp rdi, 64			; end of directory
	jne .next

	; Not found
	jmp error

.found:
	; Copy the file name
	mov [rax + 0x0], [rsi + 0x0]
	mov [rax + 0x8], [rsi + 0x8]
	mov [rax + 0x10], [rsi + 0x10]
	mov [rax + 0x18], [rsi + 0x18]

	; Set file location parameters
	mov [rax + BMFS_DirEnt.start], r8
	mov [rax + BMFS_DirEnt.reserved], rcx
	mov [rax + BMFS_DirEnt.size], 0x0000000000000000

	; Update directory entry CRC32
	call os_bmfs_update_dirent_crc32

	; Rewrite the directory table
	call os_bmfs_write_directory

	jmp .done

.error:
	stc

.done:
	pop rdi
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_bmfs_file_delete:
	push rax

	call os_bmfs_file_get_ptr	; find the file's directory entry
	jc .error

	clc

	; Add deleted marker to file name
	movb [rax + BMFS_DirEnt.filename], 0x01

	; Update directory entry CRC32
	call os_bmfs_update_dirent_crc32

	; Rewrite the directory table
	call os_bmfs_write_directory

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
