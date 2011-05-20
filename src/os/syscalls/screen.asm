; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
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
	push rdx
	push rcx
	push rbx
	push rax

	mov [screen_cursor_x], ah
	mov [screen_cursor_y], al
	push rax
	and rax, 0x000000000000FFFF	; only keep the low 16 bits
	;calculate the new offset
	mov cl, 80
	mul cl				; AX = AL * CL
	xor rbx, rbx
	mov bl, [screen_cursor_x]
	add ax, bx
	shl ax, 1			; multiply by 2
	add rax, os_screen ;0x00000000000B8000
	mov [screen_cursor_offset], rax
	pop rax				; Move the hardware cursor
	mov bh, ah
	mov bl, al
	xor ax, ax
	mov al, 0x50
	mul bl				; bl * al = ax
	movzx bx, bh
	add bx, ax
	mov al, 0x0E
	mov ah, bh
	mov dx, 0x03D4
	out dx, ax
	inc ax
	mov ah, bl
	out dx, ax	

	pop rax
	pop rbx
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_inc_cursor -- Increment the hardware cursor by one
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
; os_dec_cursor -- Decrement the hardware cursor by one
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
; os_print_string -- Displays text
;  IN:	RSI = message location (zero-terminated string)
; OUT:	All registers perserved
os_print_string:
	push rdi
	push rsi
	push rax

	cld				; Clear the direction flag.. we want to increment through the string
	mov ah, 0x07			; Store the attribute into AH so STOSW can be used later on
os_print_string_nextchar:
	lodsb				; Get char from string and store in AL
	cmp al, 0			; Strings are Zero terminated.
	je os_print_string_done		; If char is Zero then it is the end of the string
	cmp al, 10			; Check if there was a newline character in the string
	je os_print_string_newline	; If so then we print a new line
	cmp al, 13			; Check if there was a newline character in the string
	je os_print_string_newline	; If so then we print a new line
	mov rdi, [screen_cursor_offset]
	stosw				; Write the character and attribute with one call
	call os_inc_cursor
	jmp os_print_string_nextchar

os_print_string_newline:
	call os_print_newline
	jmp os_print_string_nextchar

os_print_string_done:
	call os_screen_update

	pop rax
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_string_with_color -- Displays text with color
;  IN:	RSI = message location (zero-terminated string)
;	BL  = color
; OUT:	All registers perserved
os_print_string_with_color:
	push rdi
	push rsi
	push rax

	cld					; Clear the direction flag.. we want to increment through the string
	mov ah, bl				; Copy the attribute into AH so STOSW can be used later on
os_print_string_with_color_nextchar:
	lodsb					; Get char from string and store in AL
	cmp al, 0				; Strings are Zero terminated.
	je os_print_string_with_color_done	; If char is Zero then it is the end of the string
	cmp al, 13				; Check if there was a newline character in the string
	je os_print_string_with_color_newline	; If so then we print a new line
	mov rdi, [screen_cursor_offset]
	stosw					; Write the character and attribute with one call
	call os_inc_cursor
	jmp os_print_string_with_color_nextchar

os_print_string_with_color_newline:
	call os_print_newline
	jmp os_print_string_with_color_nextchar

os_print_string_with_color_done:
	call os_screen_update

	pop rax
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_char -- Displays a char
;  IN:	AL  = char to display
; OUT:	All registers perserved
os_print_char:
	push rdi
	push rsi

	mov rdi, [screen_cursor_offset]
	stosb			; Store the character to video memory
	push ax
	mov al, 0x07		; Default of light grey on black
	stosb			; Store the color attribute to video memory
	pop ax
	call os_inc_cursor
	sub rdi, 2
	mov rsi, rdi
	sub rdi, os_screen
	add rdi, 0xB8000	; Offset to video text memory
	movsw

	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_char_with_color -- Displays a char with color
;  IN:	AL  = char to display
;	BL  = color
; OUT:	All registers perserved
os_print_char_with_color:
	push rdi
	push rsi

	mov rdi, [screen_cursor_offset]
	stosb			; Store the character to video memory
	xchg al, bl		; Swap AL and BL as stosb uses AL
	stosb			; Store the color attribute to video memory
	xchg al, bl		; Swap AL and BL back again
	call os_inc_cursor
	sub rdi, 2
	mov rsi, rdi
	sub rdi, os_screen
	add rdi, 0xB8000	; Offset to video text memory
	movsw

	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_char_hex -- Displays a char in hex mode
;  IN:	AL  = char to display
; OUT:	All registers perserved
os_print_char_hex:
	push rbx
	push rax

	mov rbx, hextable

	push rax	; save rax for the next part
	shr al, 4	; we want to work on the high part so shift right by 4 bits
	xlatb
	call os_print_char

	pop rax
	and al, 0x0f	; we want to work on the low part so clear the high part
	xlatb
	call os_print_char

	pop rax
	pop rbx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_char_hex_with_color -- Displays a char in hex mode
;  IN:	AL  = char to display
;	BL  = color
; OUT:	All registers perserved
os_print_char_hex_with_color:
	push rcx
	push rbx
	push rax

	mov cl, bl
	mov rbx, hextable

	push rax	; save rax for the next part
	shr al, 4	; we want to work on the high part so shift right by 4 bits
	xlatb
	push rbx
	mov bl, cl
	call os_print_char_with_color
	pop rbx

	pop rax
	and al, 0x0f	; we want to work on the low part so clear the high part
	xlatb
	push rbx
	mov bl, cl
	call os_print_char_with_color
	pop rbx

	pop rax
	pop rbx
	pop rcx
	ret
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
; os_hide_cursor -- Turns off cursor in text mode
;  IN:	Nothing
; OUT:	All registers perserved
os_hide_cursor:
	push rdx
	push rbx
	push rax

	mov dx, 0x03d4
	mov ax, 0x000a		; Cursor Start Register
	out dx, ax
	inc dx
	xor ax, ax
	in al, dx
	mov bl, al
	or bl, 00100000b	; Bit 5 set to 1 to disable cursor
	dec dx
	mov ax, 0x000a		; Cursor Start Register
	out dx, ax
	inc dx
	mov al, bl
	out dx, al

	pop rax
	pop rbx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
;  IN:	Nothing
; OUT:	All registers perserved
os_show_cursor:
	push rdx
	push rbx
	push rax

	mov dx, 0x03d4
	mov ax, 0x000a		; Cursor Start Register
	out dx, ax
	inc dx
	xor ax, ax
	in al, dx
	mov bl, al
	and bl, 11011111b	; Bit 5 set to 0 to enable cursor
	dec dx
	mov ax, 0x000a		; Cursor Start Register
	out dx, ax
	inc dx
	mov al, bl
	out dx, al

	pop rax
	pop rbx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_show_cursor -- Manually refresh the screen from the frame buffer
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
