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

	mov rax, 8			; Load the directory -- 4KiB @ sector 8
	mov rcx, 8
	mov rdx, [sata_port]
	mov rdi, hd_directory
	call readsectors

	; Get total blocks from Pure64 (hacky)
	mov dword eax, [0x0000000000005A80]
	shr rax, 1
	mov [bmfs_TotalBlocks], rax

	pop rdi
	pop rdx
	pop rcx
	pop rax
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; _bmfs_write_directory -- Rewrite the BMFS directory sectors
; TODO: write a copy to the end of the disk as well; add a version marker to
; track which version of the block was written
_bmfs_write_directory:
	push rax
	push rcx
	push rdx
	push rsi

	mov rax, 8			; Save the directory -- 4KiB @ sector 8
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
; _bmfs_get_space_after -- Get the number of blocks free following a given file
; IN: RAX = pointer to the start of the directory entry for the file
; OUT: RCX = number of blocks free after that file
_bmfs_get_space_after:
	push rdi

	mov r8, [rax + BMFS_DirEnt.start]
	add r8, [rax + BMFS_DirEnt.reserved]	; r8 = end of this file
	mov rcx, [bmfs_TotalBlocks]
	sub rcx, r8			; rcx = space remaining on drive after file
	sub rcx, 2			; 2 blocks reserved @ end

	mov rdi, hd_directory		; beginning of directory structure

.next:
	cmp byte [rdi], 0x01			; skip unused/deleted files
	jle .inc

	mov r9, [rdi + BMFS_DirEnt.start]
	cmp r9, r8			; ignore any files starting < our file end
	jl .inc

	sub r9, r8
	cmp r9, rcx
	cmovl rcx, r9			; r9 = min(r9, rcx)

.inc:
	add rdi, 64			; point to next record
	cmp rdi, hd_directory + 0x1000	; end of directory
	jne .next

.done:
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; _bmfs_get_start_space -- Get the number of blocks free at the start of the disk
; OUT: RCX = number of blocks free after that file
_bmfs_get_start_space:
	push rdi

	mov rdi, hd_directory		; beginning of directory structure
	mov rcx, [bmfs_TotalBlocks]
	sub rcx, 4			; 2 blocks reserved @ start and end

.next:
	cmp byte [rdi], 0x01			; skip unused/deleted files
	jle .inc

	mov r9, [rdi + BMFS_DirEnt.start]
	sub r9, 2			; 2 blocks allocated at start
	cmp r9, rcx
	cmovl rcx, r9			; r9 = min(r9, rcx)

.inc:
	add rdi, 64			; point to next record
	cmp rdi, hd_directory + 0x1000	; end of directory
	jne .next

.done:
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; _bmfs_update_dirent_crc32 -- Update the CRC32 for a directory entry
; IN: RAX = pointer to the start of the directory entry
; TODO: This is horrifically inefficient; consider using CRC32 instruction
; instead, although it's only available on Core i7 and up.
_bmfs_update_dirent_crc32:
	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push rsi

	push rax
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

	pop rsi				; contains the original value of rax
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
; _bmfs_file_get_ptr -- Search for a file name and return its directory
; entry's address
; IN:	RSI = Pointer to file name
; OUT:	RAX = Directory entry address
;	Carry set if not found. If carry is set then ignore value in RAX
_bmfs_file_get_ptr:
	push rdi

	clc				; Clear carry
	mov rdi, hd_directory		; beginning of directory structure

.next:
	call os_string_compare
	jc .done
	add rdi, 64			; next record
	cmp rdi, hd_directory + 0x1000	; end of directory
	jne .next

	xor rdi, rdi
	mov rax, rdi
	stc
	pop rdi				; Not found
ret

.done:
	clc
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
	xor rax, rax
	xor rcx, rcx

	call _bmfs_file_get_ptr		; file idx in rax, or carry set
	jc .notfound

	mov rcx, [rax + BMFS_DirEnt.size]	; Size in bytes
	mov rax, [rax + BMFS_DirEnt.start]	; Starting block number

.notfound:
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_bmfs_file_get_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_bmfs_file_get_list:
	push rsi
	push rax
	push rbx
	push rcx

	mov rsi, dir_title_string
	call os_string_length
	call os_string_copy
	add rdi, rcx

	mov rbx, hd_directory		; beginning of directory structure

.next:
	cmp byte [rbx], 0x01
	jle .inc

	mov rsi, rbx			; copy filename to destination
	call os_string_length		; get the length before copying
	call os_string_copy
	add rdi, rcx			; remove terminator

	sub rcx, 32			; pad out to 32 characters
	neg rcx
	mov al, ' '
	rep stosb

	mov rax, [rbx + BMFS_DirEnt.size]
	call os_int_to_string
	dec rdi
	mov al, 13
	stosb

.inc:
	add rbx, 64			; next record
	cmp rbx, hd_directory + 0x1000	; end of directory
	jne .next

.done:
	mov al, 0x00
	stosb

	pop rcx
	pop rbx
	pop rax
	pop rsi
ret

dir_title_string: db "Name                            Size", 13, \
	"====================================", 13, 0
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

	add rcx, 511			; Convert byte count to the number of sectors required to fit
	shr rcx, 9

	shl rax, 12			; Multiply block start count by 4096 to get sector start count
	mov rbx, rcx
	mov rdx, [sata_port]

.loop:
	mov rcx, 8192			; Ensure reads are for no more than 4MiB at a time
	cmp rbx, rcx
	jg .read

	mov rcx, rbx

.read:
	call readsectors		; Read the file to rdi
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

	mov r8, rsi			; Check to see if the file exists
	mov rsi, rdi
	call _bmfs_file_get_ptr
	mov rsi, r8
	mov r9, rax

	jc .error			; If not, throw an error

	; Ensure the file will fit within its reserved space
	mov rbx, rcx
	add rbx, 2097151		; Convert byte count to the number of 2MiB blocks
	shr rbx, 21

	mov rdx, [r9 + BMFS_DirEnt.reserved]
	cmp rbx, rdx
	jg .error			; Write too large to fit in file

	mov r8, rcx			; Save byte count for later

	mov rbx, rcx			; Determine number of sectors to write
	add rbx, 511
	shr rbx, 9

	mov rax, [r9 + BMFS_DirEnt.start]	; Set up the write
	shl rax, 12			; 4096 sectors per block
	mov rdx, [sata_port]

.loop:
	mov rcx, 8192			; Ensure writes are for no more than 4MiB at a time
	cmp rbx, rcx
	jg .write

	mov rcx, rbx

.write:
	call writesectors		; Write the file from rsi
	jc .error

	sub rbx, rcx
	jnz .loop

	mov rax, r9
	mov [rax + BMFS_DirEnt.size], r8	; Update entry with bytes written (r8)
	call _bmfs_update_dirent_crc32	; Update directory entry CRC32
	call _bmfs_write_directory	; Rewrite the directory table

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

	call _bmfs_file_get_ptr		; Check if file exists, error if so
	jnc .error

	clc

	; Convert bytes reserved to 2MiB blocks, rounding up
	mov r11, rcx
	add r11, 2097151
	shr r11, 21

	jz .error			; Don't allow zero-length reservations

	mov rax, hd_directory		; Point rdi to start of directory

	; Look for a free block large enough for this file -- r10 holds start
	; address. Try to allocate only the minimum amount of space we need;
	; previous minimum is in r12.
	mov r10, 0x7FFFFFFFFFFFFFFF
	mov r12, 0x7FFFFFFFFFFFFFFF

	call _bmfs_get_start_space

	cmp rcx, r11
	jl .space_next

	mov r10, 2			; If enough space at start, r10 = 2
	mov r12, rcx

	; Loop over all files and get the space after each one; if that space
	; is larger than the block allocation, then pick the minimum of that
	; space and the previous smallest (r12).
.space_next:
	mov r8, [rax]
	cmp r8, 0x01
	jle .inc

	call _bmfs_get_space_after

	cmp rcx, r11			; ignore if space is smaller than we need
	jl .inc

	cmp rcx, r12			; ignore if space is larger than previous min
	jge .inc

	mov r12, rcx			; set smallest big-enough space to rcx,
	mov r10, [rax + BMFS_DirEnt.start]	; and set the file start ptr
	add r10, [rax + BMFS_DirEnt.reserved]	; to right after the file we found

.inc:
	add rax, 64			; point to next record
	cmp rax, hd_directory + 0x1000	; end of directory
	jne .space_next

	cmp r10, 0x7FFFFFFFFFFFFFFF
	je .error			; Can't find a block large enough

	; Now find a free directory entry, set it up for this file
	mov rax, hd_directory		; beginning of directory structure

.dir_next:
	mov byte r8, [rax]

	cmp r8, 0x01
	jle .found
	add rax, 64			; next record
	cmp rax, hd_directory + 0x1000	; end of directory
	jne .dir_next

	jmp .error			; Not found

.found:
	push rcx			; Copy the file name
	mov rdi, rax
	mov rcx, 4
	rep movsq
	pop rcx

	mov [rax + BMFS_DirEnt.start], r10	; Set file location parameters
	mov [rax + BMFS_DirEnt.reserved], r11
	mov qword [rax + BMFS_DirEnt.size], 0x0000000000000000
	call _bmfs_update_dirent_crc32	; Update directory entry CRC32
	call _bmfs_write_directory	; Rewrite the directory table

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

	call _bmfs_file_get_ptr		; find the file's directory entry
	jc .done

	mov byte [rax + BMFS_DirEnt.filename], 0x01 ; Add deleted marker to file name

	call _bmfs_update_dirent_crc32	; Update directory entry CRC32
	call _bmfs_write_directory	; Rewrite the directory table

	jmp .done

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

	call _bmfs_file_get_ptr		; Check to see if the file exists
	jc .error
	mov rcx, [rax + BMFS_DirEnt.size]

	jmp .done

.error:
	xor rcx, rcx

.done:
	pop rax
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
