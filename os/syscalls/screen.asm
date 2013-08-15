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
; os_inc_cursor -- Increment the cursor by one, scroll if needed
;  IN:	Nothing
; OUT:	All registers preserved
os_inc_cursor:
	push rax

	add word [os_Screen_Cursor_Col], 1
	mov ax, [os_Screen_Cursor_Col]
	cmp ax, [os_Screen_Cols]
	jne os_inc_cursor_done
	mov word [os_Screen_Cursor_Col], 0
	add word [os_Screen_Cursor_Row], 1
	mov ax, [os_Screen_Cursor_Row]
	cmp ax, [os_Screen_Rows]
	jne os_inc_cursor_done
	call os_screen_scroll
	sub word [os_Screen_Cursor_Row], 1

os_inc_cursor_done:
	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_dec_cursor -- Decrement the cursor by one
;  IN:	Nothing
; OUT:	All registers preserved
os_dec_cursor:
	push rax

	sub word [os_Screen_Cursor_Col], 1
	cmp word [os_Screen_Cursor_Col], 0
	jne os_dec_cursor_done
	sub word [os_Screen_Cursor_Row], 1
	mov ax, [os_Screen_Cols]
	mov word [os_Screen_Cursor_Col], ax

os_dec_cursor_done:
	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line and scroll if needed
;  IN:	Nothing
; OUT:	All registers perserved
os_print_newline:
	push rax

	mov word [os_Screen_Cursor_Col], 0

	mov ax, [os_Screen_Rows]
	sub ax, 1
	cmp ax, [os_Screen_Cursor_Row]
	je os_print_newline_scroll
	add word [os_Screen_Cursor_Row], 1
	jmp os_print_newline_done

os_print_newline_scroll:
	call os_screen_scroll

os_print_newline_done:

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
; os_output_char -- Displays a char
;  IN:	AL  = char to display
; OUT:	All registers perserved
os_output_char:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	cmp byte [os_VideoEnabled], 1
	je os_output_char_graphics

	mov ah, 0x07		; Store the attribute into AH so STOSW can be used later on

	push rax
	mov ax, [os_Screen_Cursor_Row]
	and rax, 0x000000000000FFFF	; only keep the low 16 bits
	mov cl, 80			; 80 columns per row
	mul cl				; AX = AL * CL
	mov bx, [os_Screen_Cursor_Col]
	add ax, bx
	shl ax, 1			; multiply by 2
	mov rdi, 0xB8000		; Address of the screen buffer
	add rdi, rax
	pop rax

	stosw			; Write the character and attribute with one call
	jmp os_output_char_done

os_output_char_graphics:
	mov ebx, 0x00FFFFFF
	and eax, 0x000000FF
	call os_glyph_put

os_output_char_done:
	call os_inc_cursor

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_pixel_put -- Put a pixel on the screen
;  IN:	EBX = Packed X & Y coordinates (YYYYXXXX)
;	EAX = Pixel Details (AARRGGBB)
; OUT:	All registers preserved
os_pixel_put:
	cmp byte [os_VideoDepth], 32
	je os_pixel_put_32
	cmp byte [os_VideoDepth], 24
	je os_pixel_put_24
	ret
os_pixel_put_32:
os_pixel_put_24:
	push rdi
	push rcx
	push rdx
	push rbx
	push rax

	push rax
	mov rax, rbx
	shr eax, 16
	xor ecx, ecx
	mov cx, [os_VideoX]
	mul ecx
	and ebx, 0x0000FFFF
	add eax, ebx
	mov ecx, 3
	mul ecx
	mov rdi, [os_VideoBase]
	add rdi, rax
	pop rax

; multiply Y by os_VideoX
; add X
; multiply by 3 or 4

	stosb
	shr eax, 8
	stosb
	shr eax, 8
	stosb

	pop rax
	pop rbx
	pop rdx
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_glyph_put -- Put a glyph on the screen at the cursor location
;  IN:	EAX = Glyph
;	EBX = Color (AARRGGBB)
; OUT:	All registers preserved
os_glyph_put:
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax

	and eax, 0x000000FF
	sub rax, 0x20
	mov ecx, 12		; Font height
	mul ecx
	mov rsi, font_data
	add rsi, rax		; add offset to correct glyph

; Calculate pixel co-ords for character
	xor ebx, ebx
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Row]
	mov cx, 12		; Font height
	mul cx
	mov bx, ax
	shl ebx, 16
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Col]
	mov cx, 6		; Font width
	mul cx
	mov bx, ax
;	add bx, 1	; offset

;mov eax, 0x0000FFFF
;	call os_pixel_put

	xor eax, eax
	xor ecx, ecx		; x counter
	xor edx, edx		; y counter

nextline1:
	lodsb			; Load a line

nextpixel:
	cmp ecx, 6		; Font width
	je bailout		; Glyph row complete
	rol al, 1
	bt ax, 0
	jc os_glyph_put_pixel
	push rax
	mov eax, 0x00000000
	call os_pixel_put
	pop rax
	jmp os_glyph_put_skip

os_glyph_put_pixel:
	push rax
	mov eax, 0x00FFFFFF
	call os_pixel_put
	pop rax
os_glyph_put_skip:
	add ebx, 1
	add ecx, 1
	jmp nextpixel

bailout:
	xor ecx, ecx
	sub ebx, 6		; column start
	add ebx, 0x00010000	; next row
	add edx, 1
	cmp edx, 12		; Font height
	jne nextline1

glyph_done:

	pop rax
	pop rbx
	pop rcx
	pop rdx
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
	call os_output_char
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
;	mov al, [os_Screen_Cursor_Col]	; Grab the current cursor X value (ex 7)
;	mov cl, al
;	add al, 8			; Add 8 (ex 15)
;	shr al, 3			; Clear lowest 3 bits (ex 8)
;	shl al, 3			; Bug? 'xor al, 7' doesn't work...
;	sub al, cl			; (ex 8 - 7 = 1)
;	mov cl, al
	mov al, ' '
;os_output_chars_tab_next:
	call os_output_char
;	sub cl, 1
;	cmp cl, 0
;	jne os_output_chars_tab_next
	pop rcx
	jmp os_output_chars_nextchar

os_output_chars_done:

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

	cmp byte [os_VideoEnabled], 1
	je os_screen_scroll_graphics

	mov rsi, 0xB80A0 		; Start of video text memory for row 2
	mov rdi, 0xB8000 		; Start of video text memory for row 1
	mov rcx, 1920			; 80 x 24
	rep movsw			; Copy the Character and Attribute
	; Clear the last line in video memory
	mov ax, 0x0720			; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov rdi, 0xB8F00
	mov rcx, 80
	rep stosw			; Store word in AX to RDI, RCX times
	jmp os_screen_scroll_done

os_screen_scroll_graphics:
	xor esi, esi
	xor ecx, ecx
	mov rdi, [os_VideoBase]
	mov esi, [os_Screen_Row_2]
	add rsi, rdi
	mov ecx, [os_Screen_Bytes]
	rep movsb

os_screen_scroll_done:

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

	xor ecx, ecx

	cmp byte [os_VideoEnabled], 1
	je os_screen_clear_graphics

	mov ax, 0x0720		; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov rdi, 0xB8000	; Address for start of color video memory
	mov cx, 2000
	rep stosw		; Clear the screen. Store word in AX to RDI, RCX times
	jmp os_screen_clear_done

os_screen_clear_graphics:
	mov rdi, [os_VideoBase]
	xor eax, eax
	mov ecx, [os_Screen_Bytes]
	rep stosb

os_screen_clear_done:
	pop rax
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
