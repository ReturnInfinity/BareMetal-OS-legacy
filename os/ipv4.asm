; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; IP (Internet Protocol) Version 4
; =============================================================================

align 16
db 'DEBUG: IPv4 IP  '
align 16

; os_ipv4_open -- Open an IPv4 socket
; os_ipv4_close -- Close an IPv4 socket
; os_ipv4_connect -- Connect an IPv4 socket to a specified destination
; os_ipv4_disconnect -- Disconnect an IPv4 socket
; os_ipv4_bind -- Bind an IPv4 socket to a port
; os_ipv4_listen -- Listen on a socket
; os_ipv4_accept -- Accept a connection
; os_ipv4_select -- 


%include "ipv4/arp.asm"
%include "ipv4/icmp.asm"
%include "ipv4/tcp.asm"
%include "ipv4/udp.asm"


; =============================================================================
; EOF
