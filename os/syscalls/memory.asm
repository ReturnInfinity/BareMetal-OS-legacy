; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Memory functions
; =============================================================================

align 16
db 'DEBUG: MEMORY   '
align 16


; -----------------------------------------------------------------------------
; os_mem_allocate -- Allocates the requested number of 2 MiB pages
;  IN:	RCX = Number of pages to allocate
; OUT:	RAX = Starting address (Set to 0 on failure)
; This function will only allocate continuous pages
os_mem_allocate:
	push rsi
	push rdx
	push rbx

	cmp rcx, 0
	je os_mem_allocate_fail		; At least 1 page must be allocated

	; Here, we'll load the last existing page of memory in RSI.
	; RAX and RSI instructions are purposefully interleaved.

	xor rax, rax
	mov rsi, os_MemoryMap		; First available memory block
	mov eax, [os_MemAmount]		; Total memory in MiB from a double-word
	mov rdx, rsi			; Keep os_MemoryMap unmodified for later in RDX					
	shr eax, 1			; Divide actual memory by 2

	sub rsi, 1
	std				; Set direction flag to backward
	add rsi, rax			; RSI now points to the last page

os_mem_allocate_start:			; Find a free page of memory, from the end.
	mov rbx, rcx			; RBX is our temporary counter

os_mem_allocate_nextpage:
	lodsb
	cmp rsi, rdx			; We have hit the start of the memory map, no more free pages
	je os_mem_allocate_fail

	cmp al, 1
	jne os_mem_allocate_start	; Page is taken, start counting from scratch

	dec rbx				; We found a page! Any page left to find?
	jnz os_mem_allocate_nextpage

os_mem_allocate_mark:			; We have a suitable free series of pages. Allocate them.
	cld				; Set direction flag to forward

	xor rdi, rsi			; We swap rdi and rsi to keep rdi contents.
	xor rsi, rdi
	xor rdi, rsi
	
	; Instructions are purposefully swapped at some places here to avoid 
	; direct dependencies line after line.
	push rcx			; Keep RCX as is for the 'rep stosb' to come
	add rdi, 1
	mov al, 2
	mov rbx, rdi			; RBX points to the starting page
	rep stosb
	mov rdi, rsi			; Restoring RDI
	sub rbx, rdx			; RBX now contains the memory page number
	pop rcx 			; Restore RCX

	; Only dependency left is between the two next lines.
	shl rbx, 21			; Quick multiply by 2097152 (2 MiB) to get the starting memory address
	mov rax, rbx			; Return the starting address in RAX
	jmp os_mem_allocate_end

os_mem_allocate_fail:
	cld				; Set direction flag to forward
	xor rax, rax			; Failure so set RAX to 0 (No pages allocated)

os_mem_allocate_end:
	pop rbx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_mem_release -- Frees the requested number of 2 MiB pages
;  IN:	RAX = Starting address
;	RCX = Number of pages to free
; OUT:	RCX = Number of pages freed
os_mem_release:
	push rdi
	push rcx
	push rax

	shr rax, 21			; Quick divide by 2097152 (2 MiB) to get the starting page number
	add rax, os_MemoryMap
	mov rdi, rax
	mov al, 1
	rep stosb

	pop rax
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_mem_get_free -- Returns the number of 2 MiB pages that are available
;  IN:	Nothing
; OUT:	RCX = Number of free 2 MiB pages
os_mem_get_free:
	push rsi
	push rbx
	push rax

	mov rsi, os_MemoryMap
	xor rcx, rcx
	xor rbx, rbx

os_mem_get_free_next:
	lodsb
	inc rcx
	cmp rcx, 65536
	je os_mem_get_free_end
	cmp al, 1
	jne os_mem_get_free_next
	inc rbx
	jmp os_mem_get_free_next

os_mem_get_free_end:
	mov rcx, rbx

	pop rax
	pop rbx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
