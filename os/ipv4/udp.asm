; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; UDP (User Datagram Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 UDP '
align 16


; -----------------------------------------------------------------------------
; os_udp_handler -- Handle an incoming UDP packet; Called by Network interrupt
;  IN:	RCX = packet length
;	RSI = location of received UDP packet
os_udp_handler:
	push rsi
	push rax

	

	pop rax
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
