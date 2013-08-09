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

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx		; x counter
	xor edx, edx		; y counter

nextline1:
	lodsb			; Load a line

nextpixel:
	cmp ecx, 6
	je bailout
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
