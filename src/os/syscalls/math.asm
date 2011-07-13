; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Math Functions
; =============================================================================

align 16
db 'DEBUG: MATH     '
align 16


; -----------------------------------------------------------------------------
; os_oword_add -- Add two 128-bit integer together
; IN:	RDX,RAX = Integer 1, RCX,RBX = Integer 2
; OUT:	RDX,RAX = Result
; Note:	Carry set if overflow
os_oword_add:
	add rax, rbx
	adc rdx, rcx
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
