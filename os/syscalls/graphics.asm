; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Graphics/Pixel functions
; =============================================================================

align 16
db 'DEBUG: GRAPHICS '
align 16


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
; os_pixel_get -- Get the value of a pixel on screen
;  IN:	Nothing
; OUT:	All registers preserved
os_pixel_get:
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
