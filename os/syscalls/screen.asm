; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
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

	cmp word [os_Screen_Cursor_Col], 0
	jne os_dec_cursor_done
	sub word [os_Screen_Cursor_Row], 1
	mov ax, [os_Screen_Cols]
	mov word [os_Screen_Cursor_Col], ax

os_dec_cursor_done:
	sub word [os_Screen_Cursor_Col], 1

	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line and scroll if needed
;  IN:	Nothing
; OUT:	All registers preserved
os_print_newline:
	push rax

	mov word [os_Screen_Cursor_Col], 0	; Reset column to 0
	mov ax, [os_Screen_Rows]		; Grab max rows on screen
	sub ax, 1				; and subtract 1
	cmp ax, [os_Screen_Cursor_Row]		; Is the cursor already on the bottom row?
	je os_print_newline_scroll		; If so, then scroll
	add word [os_Screen_Cursor_Row], 1	; If not, increment the cursor to next row
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
; OUT:	All registers preserved
os_output:
	push rcx

	call os_string_length
	call os_output_chars

	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_output_char -- Displays a char
;  IN:	AL  = char to display
; OUT:	All registers preserved
os_output_char:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	cmp byte [os_VideoEnabled], 1
	je os_output_char_graphics

os_output_char_text:
	mov ah, 0x07			; Store the attribute into AH so STOSW can be used later on

	push rax
	mov ax, [os_Screen_Cursor_Row]
	and rax, 0x000000000000FFFF	; only keep the low 16 bits
	mov cl, 80			; 80 columns per row
	mul cl				; AX = AL * CL
	mov bx, [os_Screen_Cursor_Col]
	add ax, bx
	shl ax, 1			; multiply by 2
	mov rbx, rax			; Save the row/col offset
	mov rdi, os_screen		; Address of the screen buffer
	add rdi, rax
	pop rax
	stosw				; Write the character and attribute to screen buffer
	mov rdi, 0xb8000
	add rdi, rbx
	stosw				; Write the character and attribute to screen

	jmp os_output_char_done

os_output_char_graphics:
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
; os_pixel -- Put a pixel on the screen
;  IN:	EBX = Packed X & Y coordinates (YYYYXXXX)
;	EAX = Pixel Details (AARRGGBB)
; OUT:	All registers preserved
os_pixel:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	push rax			; Save the pixel details
	mov rax, rbx
	shr eax, 16			; Isolate Y co-ordinate
	xor ecx, ecx
	mov cx, [os_VideoX]
	mul ecx				; Multiply Y by os_VideoX
	and ebx, 0x0000FFFF		; Isolate X co-ordinate
	add eax, ebx			; Add X
	mov rdi, [os_VideoBase]

	cmp byte [os_VideoDepth], 32
	je os_pixel_32

os_pixel_24:
	mov ecx, 3
	mul ecx				; Multiply by 3 as each pixel is 3 bytes
	add rdi, rax			; Add offset to pixel video memory
	pop rax				; Restore pixel details
	stosb
	shr eax, 8
	stosb
	shr eax, 8
	stosb
	jmp os_pixel_done

os_pixel_32:
	shl eax, 2			; Quickly multiply by 4
	add rdi, rax			; Add offset to pixel video memory
	pop rax				; Restore pixel details
	stosd

os_pixel_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_glyph_put -- Put a glyph on the screen at the cursor location
;  IN:	AL  = char to display
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
	mov ecx, 12			; Font height
	mul ecx
	mov rsi, font_data
	add rsi, rax			; add offset to correct glyph

; Calculate pixel co-ordinates for character
	xor ebx, ebx
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Row]
	mov cx, 12			; Font height
	mul cx
	mov bx, ax
	shl ebx, 16
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Col]
	mov cx, 6			; Font width
	mul cx
	mov bx, ax

	xor eax, eax
	xor ecx, ecx			; x counter
	xor edx, edx			; y counter

nextline1:
	lodsb				; Load a line

nextpixel:
	cmp ecx, 6			; Font width
	je bailout			; Glyph row complete
	rol al, 1
	bt ax, 0
	jc os_glyph_put_pixel
	push rax
	mov eax, 0x00000000
	call os_pixel
	pop rax
	jmp os_glyph_put_skip

os_glyph_put_pixel:
	push rax
	mov eax, [os_Font_Color]
	call os_pixel
	pop rax
os_glyph_put_skip:
	add ebx, 1
	add ecx, 1
	jmp nextpixel

bailout:
	xor ecx, ecx
	sub ebx, 6			; column start
	add ebx, 0x00010000		; next row
	add edx, 1
	cmp edx, 12			; Font height
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
;  IN:	RSI = message location (an ASCII string, not zero-terminated)
;	RCX = number of chars to print
; OUT:	All registers preserved
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
	mov ax, [os_Screen_Cursor_Col]	; Grab the current cursor X value (ex 7)
	mov cx, ax
	add ax, 8			; Add 8 (ex 15)
	shr ax, 3			; Clear lowest 3 bits (ex 8)
	shl ax, 3			; Bug? 'xor al, 7' doesn't work...
	sub ax, cx			; (ex 8 - 7 = 1)
	mov cx, ax
	mov al, ' '
os_output_chars_tab_next:
	call os_output_char
	sub cx, 1
	cmp cx, 0
	jne os_output_chars_tab_next
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
; os_scroll_screen -- Scrolls the screen up by one line
;  IN:	Nothing
; OUT:	All registers preserved
os_screen_scroll:
	push rsi
	push rdi
	push rcx
	push rax
	pushfq

	cld				; Clear the direction flag as we want to increment through memory

	xor ecx, ecx

	cmp byte [os_VideoEnabled], 1
	je os_screen_scroll_graphics

os_screen_scroll_text:
	mov rsi, os_screen 		; Start of video text memory for row 2
	add rsi, 0xA0
	mov rdi, os_screen 		; Start of video text memory for row 1
	mov cx, 1920			; 80 x 24
	rep movsw			; Copy the Character and Attribute
	; Clear the last line in video memory
	mov ax, 0x0720			; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov cx, 80
	rep stosw			; Store word in AX to RDI, RCX times
	call os_screen_update
	jmp os_screen_scroll_done

os_screen_scroll_graphics:
	xor esi, esi
	mov rdi, [os_VideoBase]
	mov esi, [os_Screen_Row_2]
	add rsi, rdi
	mov ecx, [os_Screen_Bytes]
	rep movsb

os_screen_scroll_done:
	popfq
	pop rax
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_screen_clear -- Clear the screen
;  IN:	Nothing
; OUT:	All registers preserved
os_screen_clear:
	push rdi
	push rcx
	push rax
	pushfq

	cld				; Clear the direction flag as we want to increment through memory

	xor ecx, ecx

	cmp byte [os_VideoEnabled], 1
	je os_screen_clear_graphics

os_screen_clear_text:
	mov ax, 0x0720			; 0x07 for black background/white foreground, 0x20 for space (black) character
	mov rdi, os_screen		; Address for start of frame buffer
	mov cx, 2000			; 80 x 25
	rep stosw			; Clear the screen. Store word in AX to RDI, RCX times
	call os_screen_update
	jmp os_screen_clear_done

os_screen_clear_graphics:
	mov rdi, [os_VideoBase]
	xor eax, eax
	mov ecx, [os_Screen_Bytes]
	rep stosb

os_screen_clear_done:
	popfq
	pop rax
	pop rcx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_screen_update -- Manually refresh the screen from the frame buffer
;  IN:	Nothing
; OUT:	All registers preserved
os_screen_update:
	push rsi
	push rdi
	push rcx
	pushfq

	cld				; Clear the direction flag as we want to increment through memory

	mov rsi, os_screen
	mov rdi, 0xb8000
	mov cx, 2000			; 80 x 25
	rep movsw

	popfq
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
