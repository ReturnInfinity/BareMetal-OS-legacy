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


;------------------------------------------------------------------------------
; get_ip_config:  returns a copy of the IP configuration
; IN:  RDI = pointer to the buffer were config data should be stored
; OUT: [RDI] will be filled with 12 bytes:
;		0-3:  IP address
;		4-7:  Network mask
;		8-11: Gateway
os_get_ip_config:
	push rsi
	push rdi
	mov rsi, ip
	movsd
	mov rsi, sn
	movsd
	mov rsi, gw
	movsd
	pop rdi
	pop rsi
ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; set_ip_config:  sets the IP address, Network mask and Gateway 
; IN:  RSI = pointer to the buffer of network config data
; before calling [RSI] should be filled with 12 bytes as follows:
;		0-3:  IP address
;		4-7:  Network mask
;		8-11: Gateway
os_set_ip_config:
	push rsi
	push rdi
	mov rdi, ip
	movsd
	mov rdi, sn
	movsd
	mov rdi, gw
	movsd
	pop rdi
	pop rsi
ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; parse_ip_addr	Converts a valid IP address string to 4 bytes
;		binary address (little-endian)
; Input:	RSI:	Pointer to IPv4 address string
; 		RDI:	Location where IP address will be stored
;			Will be stored by null if IP address is invalid
os_parse_ip_addr:
	push rax
	push rcx
	push rdx
	push rsi
	push rdi

	mov rdx, rdi
	xor rax, rax

	mov rcx, 4
	mov rdi, os_parse_ip_addr_component1
next_char_component1:
	lodsb
	call os_is_digit
	jne check_point_component1
	stosb
	dec rcx
	cmp rcx, 0
	je invalid_ip
	jmp next_char_component1
check_point_component1:
	cmp al, '.'
	jne invalid_ip
	xor rax, rax
	stosb
	
	mov rcx, 4
	mov rdi, os_parse_ip_addr_component2
next_char_component2:
	lodsb
	call os_is_digit
	jne check_point_component2
	stosb
	dec rcx
	cmp rcx, 0
	je invalid_ip
	jmp next_char_component2
check_point_component2:
	cmp al, '.'
	jne invalid_ip
	xor rax, rax
	stosb
	
	mov rcx, 4
	mov rdi, os_parse_ip_addr_component3
next_char_component3:
	lodsb
	call os_is_digit
	jne check_point_component3
	stosb
	dec rcx
	cmp rcx, 0
	je invalid_ip
	jmp next_char_component3
check_point_component3:
	cmp al, '.'
	jne invalid_ip
	xor rax, rax
	stosb
	
	mov rcx, 4
	mov rdi, os_parse_ip_addr_component4
next_char_component4:
	lodsb
	call os_is_digit
	jne check_point_component4
	stosb
	dec rcx
	cmp rcx, 0
	je invalid_ip
	jmp next_char_component4
check_point_component4:
	cmp al, 0
	jne invalid_ip
	xor rax, rax
	stosb

	mov rdi, rdx

	mov rsi, os_parse_ip_addr_component1
	call os_string_to_int
	cmp rax, 255
	jg invalid_ip
	stosb

	mov rsi, os_parse_ip_addr_component2
	call os_string_to_int
	cmp rax, 255
	jg invalid_ip
	stosb

	mov rsi, os_parse_ip_addr_component3
	call os_string_to_int
	cmp rax, 255
	jg invalid_ip
	stosb

	mov rsi, os_parse_ip_addr_component4
	call os_string_to_int
	cmp rax, 255
	jg invalid_ip
	stosb

	jmp finish

invalid_ip:
	mov rdi, rdx
	xor rax, rax
	stosd

finish:
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax

	ret

os_parse_ip_addr_component1	db	'255', 0
os_parse_ip_addr_component2	db	'255', 0
os_parse_ip_addr_component3	db	'255', 0
os_parse_ip_addr_component4	db	'255', 0

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; ip_addr_to_str  Converts the value of an IP address to string
; IN:  RSI = Pointer to the numerical IP address
;      RDI = Pointer to the location where IP address string will stored
os_ip_addr_to_str:
	push rsi
	push rdi
	push rax
	push rcx
	
	mov rcx, 4
	xor rax, rax

os_ip_addr_to_str_next_component:
	lodsb
	call os_int_to_string
	mov al, '.'
	dec rdi
	stosb
	dec rcx
	cmp rcx, 0
	jne os_ip_addr_to_str_next_component

	; Put the null character at the end of output string
	dec rdi
	mov al, 0
	stosb
	
	pop rcx
	pop rax
	pop rdi
	pop rsi

	ret
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; os_send_ip_packet -- Sends out an IP packet
; IN:  RSI -- Pointer to packet data
;       CX -- Data length
;      EDX -- Destination IP address (little endian)
;       BL -- Protocol
; OUT: RBX -- Result code
;             00: Success
;             01: Destination unreachable
os_send_ip_packet:
	push rax
	push rcx
	push rdx
	push rsi
	push rdi
	
	push rdx

	; Copy buffer
	push rcx
	mov rdi, os_ip_tx_buffer
	add rdi, 20
	rep movsb
	pop rcx

	push rbx

	; Check with network mask
	mov eax, [sn]
	cmp eax, 0
	je os_send_ip_packet_resolve
	and eax, edx
	mov ebx, [ip]
	cmp ebx, 0
	je os_send_ip_packet_resolve
	and ebx, [sn]
	cmp eax, ebx			; Check if packet is local
	je os_send_ip_packet_resolve
	mov eax, [gw]			; Check if Gateway is set
	cmp eax, 0
	je os_send_ip_packet_resolve
	mov edx, eax			; If not local, set gateway as destination

os_send_ip_packet_resolve:

	pop rbx

	; Lookup MAC address
	xor rax, rax
	mov rdi, os_ipv4_destination_mac_addr
	stosd
	stosw
	sub rdi, 6
	mov eax, edx
	call os_arp_request
	call os_lookup_ip_addr

	mov rax, [rdi]
	shl rax, 16
	shr rax, 16

	cmp rax, 0
	je os_send_ip_packet_destination_unreachable

	pop rdx
	
	; Bits 0-15
	mov rdi, os_ip_tx_buffer
	mov ax, 0x45
	stosw
	
	; Total length 16-31
	mov ax, cx
	add ax, 20
	xchg ah, al
	stosw	
	
	; No fragments
	xor eax, eax
	stosd
	
	; TTL
	mov al, 200
	stosb
	
	; Protocol
	mov al, bl
	stosb

	; Checksum set to zero
	xor ax, ax
	stosw

	; Source IP
	mov rsi, ip
	movsd
	
	; Target IP
	mov eax, edx
	stosd

	; Checksum
	mov rsi, os_ip_tx_buffer
	push rcx
	mov rcx, 10
	call os_internet_checksum
	mov rdi, os_ip_tx_buffer
	add rdi, 10
	xchg ah, al
	stosw
	pop rcx
	
	mov rsi, os_ip_tx_buffer

	; Send the packet	
	mov bx, 0x0800
	add rcx, 20
	mov rsi, os_ip_tx_buffer
	mov rdi, os_ipv4_destination_mac_addr
	call os_ethernet_tx
	jmp os_send_ip_packet_end
	
os_send_ip_packet_destination_unreachable:
	mov rbx, 1
	pop rdx
	
os_send_ip_packet_end:
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rax
	ret	
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; os_internet_checksum -- calculates the internet checksum
;  IN:	RSI = Pointer to the data
; 	RCX = Number of words
; OUT:	EAX = Calculated checksum
os_internet_checksum:
	push rbx
	push rcx
	push rsi
	xor rax, rax
	xor rbx, rbx
os_internet_checksum_next:
	lodsw
	xchg ah, al
	add rbx, rax
	dec rcx
	cmp rcx, 0
	jne os_internet_checksum_next
	mov rax, rbx
	shr rbx, 16
	add rax, rbx
	;mov rbx, rax
	;shr rbx, 16
	;add rax, rbx
	xor eax, 0x0000FFFF
	and eax, 0x0000FFFF
	pop rsi
	pop rcx
	pop rbx
	ret
;------------------------------------------------------------------------------

os_ipv4_destination_mac_addr:	times 6 db 0

; =============================================================================
; EOF
