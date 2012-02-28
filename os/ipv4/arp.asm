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
; os_arp_request -- sends an ARP request to fetch the MAC address of an IP node
; IN:  EAX = target IP address
; All registers will be preserved.
os_arp_request:
	push rsi
	push rdi
	push rax
	push rbx
	push rcx
	
	; Check if the IP is still valid
	mov rdi, arp_table		; Search in ARP lookup table
os_arp_request_next:
	mov ebx, [rdi]			; Fetch IP address from ARP table
	cmp eax, ebx			; Check if it is a duplicate
	je os_arp_request_entry_exists
	inc cx				; Increment loop counter
	add rdi, 16			; Each entry in ARP table is 16 bytes
	cmp cx, 64			; There are 64 entries in ARP table
	jne os_arp_request_next

	jmp os_arp_request_fresh	; A fresh request should be sent
	
os_arp_request_entry_exists:
	mov ebx, [rdi + 10]		; Fetch the last update time stamp
	mov eax, [os_ClockCounter]	; Grab current RTC
	sub eax, ebx			; Calculate how old the entry is
	cmp eax, ARP_timeout		; Check if entry is outdated
	jg os_arp_request_fresh
	jmp os_arp_request_end		; Entry is still valid, finish

os_arp_request_fresh:
	; Store target IP
	mov rdi, arpreq_target_ip
	stosd

	; Copy source MAC
	mov rsi, os_NetMAC
	mov rdi, arpreq_source_mac
	movsd
	movsw
	
	; Copy source IP
	mov rsi, ip
	mov rdi, arpreq_source_ip
	movsd

	; Prepare packet for sending
	mov rsi, arp_request_msg
	mov rdi, broadcast_mac_addr
	mov rbx, 0x0806
	mov rcx, 28
	call os_ethernet_tx

os_arp_request_end:	
	pop rcx
	pop rbx
	pop rax
	pop rdi
	pop rsi
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
	push rbx
	push rcx
	push rdx

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
	; Search for the IP address to see if it is already resolved
	mov eax, [rsi + 28]		; Fetch sender IP address
	push rax			; Save sender IP address
	xor cx, cx			; Initialize loop counter
	mov rdi, arp_table		; Search in ARP lookup table
os_arp_handler_next1:
	mov ebx, [rdi]			; Fetch IP address from ARP table
	cmp eax, ebx			; Check if it is a duplicate
	je os_arp_handler_duplicate_ip
	inc cx				; Increment loop counter
	add rdi, 16			; Each entry in ARP table is 16 bytes
	cmp cx, 64			; There are 64 entries in ARP table
	jne os_arp_handler_next1

	; If the IP address is not a duplicate, then
	; store it in the first free entry of ARP table.

	xor cx, cx
	mov rdi, arp_table
os_arp_handler_next2:
	mov ebx, [rdi]
	cmp ebx, 0
	je os_arp_handler_store_entry
	inc cx
	add rdi, 16
	cmp cx, 64
	jne os_arp_handler_next2

	; If no entry is free, then find the oldest entry

	xor cx, cx
	mov rdi, arp_table
	mov eax, [rdi + 10]		; Assume the first entry as oldest
	inc cx
	add rdi, 16
os_arp_handler_next3:
	mov ebx, [rdi + 10]
	cmp eax, ebx
	jg os_arp_handler_increment
	mov eax, ebx			; Keep the oldest element value
	mov rdx, rdi			; Keep the oldest entry index
os_arp_handler_increment:
	inc cx
	add rdi, 16
	cmp cx, 64
	jne os_arp_handler_next3

	mov rdi, rdx			; Point to the oldest entry
	jmp os_arp_handler_store_entry

os_arp_handler_duplicate_ip:
	; Continue storing the data at the location found.
	; Expiration data will be updated.

os_arp_handler_store_entry:
	pop rax				; Recover the saved IP address
	mov dword [rdi], eax		; Store IP on ARP table
	mov rax, [rsi + 22]		; Grab MAC address from ARP packet
	mov qword [rdi + 4], rax	; Store MAC on ARP table
	mov rax, [os_ClockCounter]	; Grab current system counter
	mov dword [rdi + 10], eax	; Store lower part of time value

os_arp_handler_end:
	pop rdx
	pop rcx
	pop rbx
	pop rax
	pop rsi
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_arp_table :  Gets a copy of the ARP table
; IN:  RDI = Pointer to location where ARP table will be stored
; OUT: RCX = Total number of entries
;	[RDI] will be filled by IP addresses and MAC addresses
; All other registers will be preserved.
os_get_arp_table:
	push rsi
	push rdi
	push rax
	push rbx
	
	mov rsi, arp_table
	xor rax, rax
	xor rbx, rbx
	mov rcx, 64		; There are maximum 64 entries in ARP table
os_get_arp_table_check_next_entry:
	lodsd
	cmp eax, 0
	je os_get_arp_table_skip_entry
	stosd
	movsd
	movsw
	inc rbx
	add rsi, 6
	jmp os_get_arp_table_dec_counter
os_get_arp_table_skip_entry:
	add rsi, 12
os_get_arp_table_dec_counter:
	dec rcx
	cmp rcx, 0
	jne os_get_arp_table_check_next_entry
	mov rcx, rbx
	
	pop rbx
	pop rax
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


;------------------------------------------------------------------------------
; os_lookup_ip_addr -- Looks for an IP address in the ARP table
; IN:  EAX = IP address in little endian
;      RDI = Location to store the MAC address
os_lookup_ip_addr:
	push rax
	push rbx
	push rcx
	push rsi
	push rdi

	; Search for the IP address to see if it is already resolved
	xor cx, cx			; Initialize loop counter
	mov rsi, arp_table		; Search in ARP lookup table
os_lookup_ip_addr_next:
	mov ebx, [rsi]			; Fetch IP address from ARP table
	cmp eax, ebx			; Check if it is a duplicate
	je os_lookup_ip_addr_found
	inc cx				; Increment loop counter
	add rsi, 16			; Each entry in ARP table is 16 bytes
	cmp cx, 64			; There are 64 entries in ARP table
	jne os_lookup_ip_addr_next
	jmp os_lookup_ip_addr_not_found

os_lookup_ip_addr_found:
	add rsi, 4
	movsd				; Copy the MAC address
	movsw
	jmp os_lookup_ip_addr_end
	
os_lookup_ip_addr_not_found:
	
os_lookup_ip_addr_end:
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	pop rax
	ret
;------------------------------------------------------------------------------


broadcast_mac_addr:	dw  0xffff, 0xffff, 0xffff
arp_request_msg:	db  0, 1, 8, 0, 6, 4, 0, 1, 'macmac', 'ipip', 0, 0, 0, 0, 0, 0, 'ipip'
arpreq_source_mac:	equ arp_request_msg + 8
arpreq_source_ip:	equ arp_request_msg + 14
arpreq_target_mac	equ arp_request_msg + 18
arpreq_target_ip	equ arp_request_msg + 24

; =============================================================================
; EOF
