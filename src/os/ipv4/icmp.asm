; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; ICMP (Internet Control Message Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 ICMP'
align 16


; -----------------------------------------------------------------------------
; os_icmp_handler -- Handle an incoming ICMP packet
;  IN:	RCX = packet length
;	RSI = location of received ICMP packet
os_icmp_handler:

	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
