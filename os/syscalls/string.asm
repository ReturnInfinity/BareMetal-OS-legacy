; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2014 Return Infinity -- see LICENSE.TXT
;
; String Functions
; =============================================================================

align 16
db 'DEBUG: STRING   '
align 16


; -----------------------------------------------------------------------------
; os_int_to_string -- Convert a binary integer into an string
;  IN:	RAX = binary integer
;	RDI = location to store string
; OUT:	RDI = points to end of string
;	All other registers preserved
; Min return value is 0 and max return value is 18446744073709551615 so the
; string needs to be able to store at least 21 characters (20 for the digits
; and 1 for the string terminator).
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/rax2uint.s
os_int_to_string:
	push rdx
	push rcx
	push rbx
	push rax

	mov rbx, 10					; base of the decimal system
	xor ecx, ecx					; number of digits generated
os_int_to_string_next_divide:
	xor edx, edx					; RAX extended to (RDX,RAX)
	div rbx						; divide by the number-base
	push rdx					; save remainder on the stack
	inc rcx						; and count this remainder
	cmp rax, 0					; was the quotient zero?
	jne os_int_to_string_next_divide		; no, do another division

os_int_to_string_next_digit:
	pop rax						; else pop recent remainder
	add al, '0'					; and convert to a numeral
	stosb						; store to memory-buffer
	loop os_int_to_string_next_digit		; again for other remainders
	xor al, al
	stosb						; Store the null terminator at the end of the string

	pop rax
	pop rbx
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_to_int -- Convert a string into a binary integer
;  IN:	RSI = location of string
; OUT:	RAX = integer value
;	All other registers preserved
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/uint2rax.s
os_string_to_int:
	push rsi
	push rdx
	push rcx
	push rbx

	xor eax, eax			; initialize accumulator
	mov rbx, 10			; decimal-system's radix
os_string_to_int_next_digit:
	mov cl, [rsi]			; fetch next character
	cmp cl, '0'			; char preceeds '0'?
	jb os_string_to_int_invalid	; yes, not a numeral
	cmp cl, '9'			; char follows '9'?
	ja os_string_to_int_invalid	; yes, not a numeral
	mul rbx				; ten times prior sum
	and rcx, 0x0F			; convert char to int
	add rax, rcx			; add to prior total
	inc rsi				; advance source index
	jmp os_string_to_int_next_digit	; and check another char
	
os_string_to_int_invalid:
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_length -- Return length of a string
;  IN:	RSI = string location
; OUT:	RCX = length (not including the NULL terminator)
;	All other registers preserved
os_string_length:
	push rdi
	push rax

	xor ecx, ecx
	xor eax, eax
	xorps xmm0, xmm0
scan_loop:	
	movdqu xmm1, [rsi+rcx]	
	pcmpeqb xmm1, xmm0
	pmovmskb eax, xmm1
	add ecx, 16
	test eax, eax
	jz scan_loop
	bsf eax, eax
	sub ecx, 16		; remove last increment
	add ecx, eax

	pop rax
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_copy -- Copy the contents of one string into another
;  IN:	RSI = source
;	RDI = destination
; OUT:	All registers preserved
; Note:	It is up to the programmer to ensure that there is sufficient space in the destination
os_string_copy:
	push rsi
	push rdi
	push rax
	xor eax, eax
	xorps xmm0, xmm0
os_string_copy_more:
	movdqu xmm1, [rsi+rcx]
	pcmpeqb xmm1, xmm0		; Check for 0 
	pmovmskb eax, xmm1
	add ecx, 16
	test eax, eax
	jnz os_string_copy_more
	bsf eax, eax
	sub ecx, 16
	add ecx, eax
	rep movsb
	
	pop rax
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_compare -- See if two strings match
;  IN:	RSI = string one
;	RDI = string two
; OUT:	Carry flag set if same
os_string_compare:
	push rsi
	push rdi
	push rbx
	push rax
	xorps xmm0, xmm0
	xor ebx, ebx
os_string_compare_more:
	movdqu xmm1, [rsi]		
	movdqu xmm2, [rdi]
	movdqa xmm3, xmm1			; save 2° string for last check
	movdqa xmm4, xmm2
	pcmpeqb xmm2, xmm1			
	pmovmskb eax, xmm2
	not eax					; EAX=0 if strings agree
	setnz bl
	pcmpeqb xmm1, xmm0
	pvmomskb eax, xmm1
	add rsi, 16
	add rdi, 16
	add  eax, ebx				; either EAX or EBX !=0?
	jz os_string_compare_more

os_string_compare_not_same:
	pcmpeqb xmm3, xmm0
	pcmpeqb xmm4, xmm0
	pmovmskb edi, xmm3
	xor eax, eax
	neg ebx					; EBX=-1 if equal strings
	pmovmskb esi, xmm4
	test edi, esi
	setnz al
	and  eax, ebx
	shl eax , 1                            ; put LSB in CF
	pop rax
	pop rbx
	pop rdi
	pop rsi
	clc
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
