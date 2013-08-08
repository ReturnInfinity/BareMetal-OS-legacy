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

	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
