; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; UDP (User Datagram Protocol) over IPv4
; =============================================================================

align 16
db 'DEBUG: IPv4 UDP '
align 16


; os_ipv4_udp_sendto -- Writes data the remote host via UDP
; os_ipv4_udp_recvfrom -- Reads data from the remote host via UDP


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
