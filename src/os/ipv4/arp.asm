; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; ARP (Address Resolution Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 ARP '
align 16


;ARP Request layout:
; Ethernet header:
; 0-5, Broadcast MAC (0xFFFFFFFFFFFF)
; 6-11, Source MAC (This host)
; 12-13, Type ARP (0x0806)
; ARP data:
; 14-15, Hardware type (0x0001 Ethernet)
; 16-17, Protocol type (0x0800 IP)
; 18, Hardware size (0x06)
; 19, Protocol size (0x04)
; 20-21, Opcode (0x0001 Request)
; 22-27, Sender MAC (This host)
; 28-31, Sender IP (This host)
; 32-37, Target MAC (0x000000000000)
; 38-41, Target IP

;ARP Reply layout:
; Ethernet header:
; 0-5, Destination MAC (This host)
; 6-11, Source MAC
; 12-13, Type ARP (0x0806)
; ARP data:
; 14-15, Hardware type (0x0001 Ethernet)
; 16-17, Protocol type (0x0800 IP)
; 18, Hardware size (0x06)
; 19, Protocol size (0x04)
; 20-21, Opcode (0x0002 Reply)
; 22-27, Sender MAC
; 28-31, Sender IP
; 32-37, Target MAC
; 38-41, Target IP


os_arp_request:

ret


os_arp_handler:

ret


; =============================================================================
; EOF
