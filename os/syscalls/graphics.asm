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
;  IN:	AH  = row
;	AL  = column
; OUT:	All registers preserved
os_pixel_put:
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
