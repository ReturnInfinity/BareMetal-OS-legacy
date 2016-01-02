; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; PIC Functions. http://wiki.osdev.org/PIC
; =============================================================================

align 16
db 'DEBUG: PIC      '
align 16


; -----------------------------------------------------------------------------
; os_pic_mask_clear -- Clear a mask on the PIC
;  IN:	AL  = IRQ #
; OUT:	All registers preserved
os_pic_mask_clear:
	push dx
	push bx
	push ax

	mov bl, al			; Save the IRQ value
	cmp bl, 8			; Less than 8
	jl os_pic_mask_clear_low	; If so, only set Master PIC
	mov dx, 0xA1			; Slave PIC data address
	sub bl, 8
	jmp os_pic_mask_clear_write
os_pic_mask_clear_low:
	mov dx, 0x21			; Mast PIC data address
os_pic_mask_clear_write:
	in al, dx			; Read the current mask
	btr ax, bx
	out dx, al			; Write the new mask

	pop ax	
	pop bx
	pop dx 
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
