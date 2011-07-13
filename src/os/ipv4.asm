; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; IP (Internet Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 IP  '
align 16

%include "ipv4/arp.asm"
%include "ipv4/icmp.asm"


; =============================================================================
; EOF
