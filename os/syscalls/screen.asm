; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Screen Output Functions
; =============================================================================

align 16
db 'DEBUG: SCREEN   '
align 16


; -----------------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
;  IN:	AH  = row
;	AL  = column
; OUT:	All registers preserved
os_move_cursor:
	push rcx
	push rbx
	push rax

	xor rbx, rbx
	mov [screen_cursor_x], ah
	mov [screen_cursor_y], al
	and rax, 0x000000000000FFFF	; only keep the low 16 bits
	;calculate the new offset
	mov cl, 80			; 80 columns per row
	mul cl				; AX = AL * CL
	mov bl, [screen_cursor_x]
	add ax, bx
	shl ax, 1			; multiply by 2
	add rax, os_screen		; Address of the screen buffer
	mov [screen_cursor_offset], rax

	pop rax
	pop rbx
	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_inc_cursor -- Increment the cursor by one
;  IN:	Nothing
; OUT:	All registers preserved
os_inc_cursor:
	push rax

	mov ah, [screen_cursor_x]	; grab the current cursor location values
	mov al, [screen_cursor_y]
	inc ah
	cmp ah, [screen_cols]		; 80
	jne os_inc_cursor_done
	xor ah, ah
	inc al
	cmp al, [screen_rows]		; 25
	jne os_inc_cursor_done
	call os_screen_scroll		; we are on the last column of the last row (bottom right) so we need to scroll the screen up by one line
	mov ah, 0x00			; now reset the cursor to be in the first colum of the last row (bottom left)
	mov al, [screen_rows]
	dec al

os_inc_cursor_done:
	call os_move_cursor

	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_dec_cursor -- Decrement the cursor by one
;  IN:	Nothing
; OUT:	All registers preserved
os_dec_cursor:
	push rax

	mov ah, [screen_cursor_x]	; Get the current cursor location values
	mov al, [screen_cursor_y]
	cmp ah, 0			; Check if the cursor in located on the first column?
	jne os_dec_cursor_done
	dec al				; Wrap the cursor back to the above line
	mov ah, [screen_cols]

os_dec_cursor_done:
	dec ah
	call os_move_cursor

	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line and scroll if needed
;  IN:	Nothing
; OUT:	All registers perserved
os_print_newline:
	push rax

	mov ah, 0			; Set the cursor x value to 0
	mov al, [screen_cursor_y]	; Grab the cursor y value
	cmp al, 24			; Compare to see if we are on the last line
	je os_print_newline_scroll	; If so then we need to scroll the sreen
	inc al				; If not then we can go ahead an increment the y value
	jmp os_print_newline_done

os_print_newline_scroll:
	call os_screen_scroll

os_print_newline_done:
	call os_move_cursor		; Update the cursor

	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_output -- Displays text
;  IN:	RSI = message location (zero-terminated string)
; OUT:	All registers perserved
os_output:
	push rcx

	call os_string_length
	call os_output_chars

	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_string_with_color -- Displays text with color
;  IN:	RSI = message location (zero-terminated string)
;	BL  = color
; OUT:	All registers perserved
; This function uses the the os_print_string function to do the actual printing
os_output_with_color:
	push rcx

	call os_string_length
	call os_output_chars_with_color

	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_char -- Displays a char
;  IN:	AL  = char to display
; OUT:	All registers perserved
os_output_char:
	push rdi
	push rsi
	push rax

	mov ah, 0x07		; Store the attribute into AH so STOSW can be used later on

os_print_char_worker:
	mov rdi, [screen_cursor_offset]
	stosw			; Write the character and attribute with one call
	call os_inc_cursor
	sub rdi, 2
	mov rsi, rdi
	sub rdi, os_screen
	add rdi, 0xB8000	; Offset to video text memory
	movsw

	pop rax
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_output_chars -- Displays text
;  IN:	RSI = message location (A string, not zero-terminated)
;	RCX = number of chars to print
; OUT:	All registers perserved
os_output_chars:
	push rdi
	push rsi
	push rcx
	push rax

	cld				; Clear the direction flag.. we want to increment through the string
	mov ah, 0x07			; Store the attribute into AH so STOSW can be used later on

os_output_chars_nextchar:
	jrcxz os_output_chars_done
	sub rcx, 1
	lodsb				; Get char from string and store in AL
	cmp al, 13			; Check if there was a newline character in the string
	je os_output_chars_newline	; If so then we print a new line
	cmp al, 10			; Check if there was a newline character in the string
	je os_output_chars_newline	; If so then we print a new line
	cmp al, 9
	je os_output_chars_tab
	mov rdi, [screen_cursor_offset]
	stosw				; Write the character and attribute with one call
	call os_inc_cursor
	jmp os_output_chars_nextchar

os_output_chars_newline:
	mov al, [rsi]
	cmp al, 10
	je os_output_chars_newline_skip_LF
	call os_print_newline
	jmp os_output_chars_nextchar

os_output_chars_newline_skip_LF:
	cmp rcx, 0
	je os_output_chars_newline_skip_LF_nosub
	sub rcx, 1
os_output_chars_newline_skip_LF_nosub:
	add rsi, 1
	call os_print_newline
	jmp os_output_chars_nextchar	

os_output_chars_tab:
	push rcx
	mov al, [screen_cursor_x]	; Grab the current cursor X value (ex 7)
	mov cl, al
	add al, 8			; Add 8 (ex 15)
	shr al, 3			; Clear lowest 3 bits (ex 8)
	shl al, 3			; Bug? 'xor al, 7' doesn't work...
	sub al, cl			; (ex 8 - 7 = 1)
	mov cl, al
	mov al, ' '
os_output_chars_tab_next:
	stosw				; Write the character and attribute with one call
	call os_inc_cursor
	sub cl, 1
	cmp cl, 0
	jne os_output_chars_tab_next
	pop rcx
	jmp os_output_chars_nextchar

os_output_chars_done:
	call os_screen_update

	pop rax
	pop rcx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_chars_with_color -- Displays text with color
;  IN:	RSI = message location (A string, not zero-terminated)
;	BL  = color
;	RCX = number of chars to print
; OUT:	All registers perserved
; This function uses the the os_print_chars function to do the actual printing
os_output_chars_with_color:
	push rdi
	push rsi
	push rcx
	push rax

	cld				; Clear the direction flag.. we want to increment through the string
	mov ah, bl			; Store the attribute into AH so STOSW can be used later on

	jmp os_output_chars_nextchar	; Use the logic from os_print_chars
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_scroll_screen -- Scrolls the screen up by one line
;  IN:	Nothing
; OUT:	All registers perserved
os_screen_scroll:
	push rsi
	push rdi
	push rcx
	push rax

	cld				; Clear the direction flag as we want to increment through memory

	cmp byte [os_show_sysstatus], 0
	je os_screen_scroll_no_sysstatus

	mov rsi, os_screen 		; Start of video text memory for row 2
	add rsi, 0xa0
	mov rdi, os_screen 		; Start of video text memory for row 1
	mov rcx, 72			; 80 - 8
	rep movsw			; Copy the Character and Attribute
	mov rsi, os_screen		; Start of video text memory for row 3
	add rsi, 0x140
	mov rdi, os_screen		; Start of video text memory for row 2
	add rdi, 0xa0
	mov rcx, 1840			; 80 x 23
	rep movsw			; Copy the Character and Attribute
	jmp os_screen_scroll_lastline

os_screen_scroll_no_sysstatus:
	mov rsi, os_screen 		; Start of video text memory for row 2
	add rsi, 0xa0
	mov rdi, os_screen 		; Start of video text memory for row 1
	mov rcx, 1920			; 80 x 24
	rep movsw			; Copy the Character and Attribute

os_screen_scroll_lastline:		; Clear the last line in video memory
	mov ax, 0x0720			; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov rdi, os_screen
	add rdi, 0xf00
	mov rcx, 80
	rep stosw			; Store word in AX to RDI, RCX times

	call os_screen_update

	pop rax
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_screen_clear -- Clear the screen
;  IN:	Nothing
; OUT:	All registers perserved
os_screen_clear:
	push rdi
	push rcx
	push rax

	mov ax, 0x0720		; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov rdi, os_screen	; Address for start of color video memory
	mov rcx, 2000
	rep stosw		; Clear the screen. Store word in AX to RDI, RCX times

	call os_screen_update	; Copy the video buffer to video memory

	pop rax
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_screen_update -- Manually refresh the screen from the frame buffer
;  IN:	Nothing
; OUT:	All registers perserved
os_screen_update:
	push rsi
	push rdi
	push rcx

	mov rsi, os_screen
	mov rdi, 0xb8000
	mov rcx, 2000
	rep movsw

	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
