; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; TCP (Transmission Control Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 TCP '
align 16


; -----------------------------------------------------------------------------
; os_tcp_handler -- Handle an incoming TCP packet; Called by Network interrupt
;  IN:	RCX = packet length
;	RSI = location of received TCP packet
os_tcp_handler:
	push rsi
	push rax

	

	pop rax
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
