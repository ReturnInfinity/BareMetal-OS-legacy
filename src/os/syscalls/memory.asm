; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Memory functions
; =============================================================================

align 16
db 'DEBUG: MEMORY   '
align 16


; -----------------------------------------------------------------------------
; os_mem_allocate -- Allocates the requested number of 2 MiB pages
;  IN:	RCX = Number of pages to allocate
; OUT:	RAX = Starting address
;	RCX = Number of pages allocated (Set to the value asked for or 0 on failure)
; This function will only allocate continous pages
os_mem_allocate:
	push rdi
	push rsi
	push rdx
	push rbx

	cmp rcx, 0
	je os_mem_allocate_fail		; At least 1 page must be allocated
	xor rax, rax
	mov rsi, os_MemoryMap
	mov ax, word [os_MemAmount]
	shr ax, 1			; Divide actual memory by 2
	add rsi, rax			; RSI now points to the last page
	sub rsi, 1
	std				; Set direction flag to backward

os_mem_allocate_start:			; Find a free page of memory
	lodsb
	cmp rsi, os_MemoryMap		; We have hit the start of the memory map, no free pages
	je os_mem_allocate_fail
	cmp al, 1			; If the byte is one then we found a free memory page
	jne os_mem_allocate_start
	mov rbx, rcx			; RBX is our temporary counter
	sub rbx, 1			; One free page was already found
	cmp rbx, 0			; Was only one page requested?
	je os_mem_allocate_mark

os_mem_allocate_nextpage:
	lodsb
	cmp rsi, os_MemoryMap		; We have hit the start of the memory map, no more free pages
	je os_mem_allocate_fail
	cmp al, 1
	jne os_mem_allocate_start
	sub rbx, 1
	cmp rbx, 0
	jne os_mem_allocate_nextpage

os_mem_allocate_mark:
	; We have a suitable free series of pages. Allocate them.
	cld				; Set direction flag to forward
	mov rdi, rsi
	add rdi, 1
	mov rdx, rdi			; RDX points to the starting page
	mov al, 2
	push rcx
	rep stosb
	pop rcx
	sub rdx, os_MemoryMap		; RDX now contains the memory page number
	shl rdx, 21			; Quick multiply by 2097152 (2 MiB) to get the starting memory address
	mov rax, rdx			; Return the starting address in RAX
	jmp os_mem_allocate_end

os_mem_allocate_fail:
	cld				; Set direction flag to forward
	xor rcx, rcx			; Failure so set RCX to 0 (No pages allocated)
	xor rax, rax

os_mem_allocate_end:
	pop rbx
	pop rdx
	pop rsi
	pop rdi
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
	add rcx, 1
	cmp rcx, 65536
	je os_mem_get_free_end
	cmp al, 1
	jne os_mem_get_free_next
	add rbx, 1
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
