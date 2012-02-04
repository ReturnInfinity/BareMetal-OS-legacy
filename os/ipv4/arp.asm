; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; ARP (Address Resolution Protocol)
; =============================================================================

align 16
db 'DEBUG: ARP      '
align 16


; ARP Incoming Request layout:
; Ethernet header:
; 0-5, Broadcast MAC (0xFFFFFFFFFFFF)
; 6-11, Source MAC
; 12-13, Type ARP (0x0806)
; ARP data:
; 14-15, Hardware type (0x0001 Ethernet)
; 16-17, Protocol type (0x0800 IP)
; 18, Hardware size (0x06)
; 19, Protocol size (0x04)
; 20-21, Opcode (0x0001 Request)
; 22-27, Sender MAC
; 28-31, Sender IP
; 32-37, Target MAC (0x000000000000)
; 38-41, Target IP

; ARP Outgoing Request layout:
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

; ARP Outgoing Reply layout:
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


; -----------------------------------------------------------------------------
os_arp_request:

ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_arp_handler -- Handle an incoming ARP packet; Called by Network interrupt
;  IN:	RCX = packet length
;	RSI = location of received ARP packet
os_arp_handler:
	push rdi
	push rsi
	push rax
	
	mov ax, [rsi+0x14]		; Grab the Opcode
	xchg al, ah			; Convert to proper endianess
	cmp ax, 0x0001			; Request
	je os_arp_handler_request	; Respond if the ARP packet is for us
	cmp ax, 0x0002			; Reply
	je os_arp_handler_reply		; Add to our local ARP table
	jmp os_arp_handler_end		; Bail out

os_arp_handler_request:
	mov eax, [rsi+0x26]		; Grab the target IP address
	cmp eax, [ip]			; Does it match our IP?
	jne os_arp_handler_end		; If not then we don't need to respond

	push rsi			; Save the address of the packet
	mov rdi, rsi
	add rsi, 0x1C			; Skip to Sender IP
	mov eax, [rsi]
	push rax			; Save the Sender IP
	sub rsi, 0x16			; Skip back to Source MAC
	movsd				; Copy destination MAC address
	movsw
	push rsi			; Copy source MAC address
	mov rsi, os_NetMAC
	movsd
	movsw
	pop rsi
	add rdi, 9
	mov al, 0x02			; Change the opcode to a reply
	stosb
	push rsi			; Copy source MAC address (again)
	mov rsi, os_NetMAC
	movsd
	movsw
	pop rsi
	mov eax, [ip]			; Copy our IP
	stosd
	sub rsi, 12			; Copy destination MAC
	movsd
	movsw
	pop rax				; Restore the Sender IP
	stosd
	pop rsi				; Restore the packet address
	mov cx, 60
	call os_ethernet_tx_raw		; Send the packet
	jmp os_arp_handler_end

os_arp_handler_reply:
	; If this was a reply to a request that this computer sent out then this should be added to the local ARP table
	jmp os_arp_handler_end

os_arp_handler_end:
	pop rax
	pop rsi
	pop rdi
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
