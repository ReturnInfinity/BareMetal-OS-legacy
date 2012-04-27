; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Input Functions
; =============================================================================

align 16
db 'DEBUG: INPUT    '
align 16


; -----------------------------------------------------------------------------
; os_input_key -- Scans keyboard for input
;  IN:	Nothing
; OUT:	AL = 0 if no key pressed, otherwise ASCII code, other regs preserved
;	Carry flag is set if there was a keystoke, clear if there was not
;	All other registers preserved
os_input_key:
	mov al, [key]
	cmp al, 0
	je os_input_key_no_key
	mov byte [key], 0x00	; clear the variable as the keystroke is in AL now
	stc			; set the carry flag
	ret

os_input_key_no_key:
	clc			; clear the carry flag
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
;  IN:	RDI = location where string will be stored
;	RCX = maximum number of characters to accept
; OUT:	RCX = length of string that was inputed (NULL not counted)
;	All other registers preserved
os_input_string:
	push rdi
	push rdx			; Counter to keep track of max accepted characters
	push rax

	mov rdx, rcx
	xor rcx, rcx
os_input_string_more:
	push rdi			; Display a cursor during user input
	mov rdi, [screen_cursor_offset]	; Offset within the screen buffer
	sub rdi, 0xC8000		; Write directly to video memory (0xB8000)
	add rdi, 1			; Add 1 to get to the attribute byte
	mov al, 0x70			; Gray background, black foreground
	stosb
	pop rdi
	call os_input_key
	jnc os_input_string_halt	; No key entered... halt until an interrupt is received
	cmp al, 0x1C			; If Enter key pressed, finish
	je os_input_string_done
	cmp al, 0x0E			; Backspace
	je os_input_string_backspace
	cmp al, 32			; In ASCII range (32 - 126)?
	jl os_input_string_more
	cmp al, 126
	jg os_input_string_more
	cmp rcx, rdx			; Check if we have reached the max number of chars
	je os_input_string_more		; Jump if we have (should beep as well)
	stosb				; Store AL at RDI and increment RDI by 1
	inc rcx				; Increment the couter
	call os_print_char		; Display char
	jmp os_input_string_more

os_input_string_backspace:
	cmp rcx, 0			; backspace at the beginning? get a new char
	je os_input_string_more
	push rdi			; Remove the old cursor
	mov rdi, [screen_cursor_offset]	; Offset within the screen buffer
	sub rdi, 0xC8000		; Write directly to video memory (0xB8000)
	add rdi, 1			; Add 1 to get to the attribute byte
	mov al, 0x07
	stosb
	pop rdi
	call os_dec_cursor		; Decrement the cursor
	mov al, 0x20			; 0x20 is the character for a space
	call os_print_char		; Write over the last typed character with the space
	call os_dec_cursor		; Decrement the cursor again
	dec rdi				; go back one in the string
	mov byte [rdi], 0x00		; NULL out the char
	dec rcx				; decrement the counter by one
	jmp os_input_string_more

os_input_string_halt:
	hlt				; Halt until another keystroke is received
	jmp os_input_string_more

os_input_string_done:
	mov al, 0x00
	stosb				; We NULL terminate the string

	pop rax
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
