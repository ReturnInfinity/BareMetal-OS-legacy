; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Glyph functions
; =============================================================================

align 16
db 'DEBUG: GLYPH    '
align 16


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

	sub rax, 0x20
	shl rax, 3		; Quick multiply by 8
	mov rsi, font_data
	add rsi, rax		; add offset to correct glyph

; Calculate pixel co-ords for character
	xor ebx, ebx
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Row]
	mov cx, 8
	mul cx
	mov bx, ax
	shl ebx, 16
	xor edx, edx
	xor eax, eax
	mov ax, [os_Screen_Cursor_Col]
	mov cx, 6
	mul cx
	mov bx, ax

	xor eax, eax
	xor ecx, ecx		; x counter
	xor edx, edx		; y counter

nextline1:
	lodsb			; Load a line

nextpixel:
	cmp ecx, 6
	je bailout		; Glyph row complete
	rol al, 1
	bt ax, 0
	jc os_glyph_put_pixel
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
	cmp edx, 8
	jne nextline1

updatecursor:
	add word [os_Screen_Cursor_Col], 1	; Increment the cursor column by 1
	mov ax, [os_Screen_Cursor_Col]
	cmp ax, [os_Screen_Cols]		; Is it past the egde
	jne glyph_done				; If not, bail out!
	xor eax, eax
	mov word [os_Screen_Cursor_Col], ax	; Reset row to 0
	add word [os_Screen_Cursor_Row], 1	; Increment the cursor row by 1
	; check to see if scroll is required

glyph_done:

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
