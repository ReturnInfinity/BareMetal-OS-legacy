; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; IP (Internet Protocol) Version 4
; =============================================================================

align 16
db 'DEBUG: IPv4 IP  '
align 16

%include "ipv4/arp.asm"
%include "ipv4/icmp.asm"
%include "ipv4/tcp.asm"
;%include "ipv4/udp.asm"


; =============================================================================
; EOF
