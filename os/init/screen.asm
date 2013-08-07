; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; INIT_SCREEN
; =============================================================================

align 16
db 'DEBUG: INIT_SCRE'
align 16


init_screen:
	mov rsi, 0x5080
	xor eax, eax
	lodsd				; VIDEO_BASE
	mov [os_VideoBase], rax
	lodsw				; VIDEO_X
	mov [os_VideoX], ax
	lodsw				; VIDEO_Y
	mov [os_VideoY], ax
	lodsb				; VIDEO_DEPTH
	mov [os_VideoDepth], al
	ret


; =============================================================================
; EOF
