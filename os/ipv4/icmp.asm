; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; ICMP (Internet Control Message Protocol)
; =============================================================================

align 16
db 'DEBUG: IPv4 ICMP'
align 16


; -----------------------------------------------------------------------------
; os_icmp_handler -- Handle an incoming ICMP packet; Called by Network interrupt
;  IN:	RCX = packet length
;	RSI = location of received ICMP packet
os_icmp_handler:
	push rdi
	push rsi
	push rax

	; Check if reply or request
	mov al, [rsi + 0x22]
	cmp al, 8
	je os_icmp_handler_request
	cmp al, 0
	je os_icmp_handler_response

	jmp os_icmp_handler_end

os_icmp_handler_request:
	; Swap the MAC addresses
	mov rax, [rsi]			; Grab the Destination MAC as 8 bytes even though the MAC is 6 bytes
	shl rax, 16
	mov ax, [rsi+0x0C]		; Store the EtherType in the low 16-bits of RAX
	push rax			; Save the new Source MAC (with EtherType) to the stack
	mov rax, [rsi+0x06]		; Grab the Source MAC as 8 bytes (the last two bytes will be overwritten)
	mov [rsi], rax			; Store the new Destination MAC in the packet
	pop rax				; Restore the new Source MAC + EtherType
	ror rax, 16
	mov [rsi+0x06], rax		; Write it to the packet

	; Swap the IP addresses
	mov eax, [rsi+0x1A]		; Grab the Source IP
	push rax
	mov eax, [rsi+0x1E]		; Grab the Destination IP
	mov dword [rsi+0x1A], eax	; Overwrite the 'old' Source with the 'new' Source
	pop rax
	mov dword [rsi+0x1E], eax	; Overwrite the 'old' Destination with the 'new' Destination

	; Set to Echo Reply
	mov byte [rsi+0x22], 0x00	; Set to 0 for Echo Reply (Was originally 8 for Echo Request)

	; Adjust the checksum
	mov ax, [rsi+0x24]
	add ax, 8			; Add 8 since we removed 8 (by clearing the Echo Request)
	mov word [rsi+0x24], ax

	call os_ethernet_tx_raw		; Send the packet

	jmp os_icmp_handler_end

os_icmp_handler_response:
	mov rsi, os_icmp_callback
	lodsq
	cmp rax, 0
	je os_icmp_handler_end
	call rax

os_icmp_handler_end:
	pop rax
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_icmp_send_request -- Sends an ICMP request packet
;  IN:	EDX = Destination IP address
;	AH  = Code
;	AL  = Type
;	ECX = Identifier and Sequence
;	RDI = Receiver call back function
; OUT:	RBX = IP result code
;		00  Success
;		03  Invalid type
os_icmp_send_request:
	push rax
	push rcx
	push rsi
	push rdi

	cmp al, 41
	jg os_icmp_send_request_invalid_type

	; Store address of call back function
	mov [os_icmp_callback], rdi

	; Prepare ICMP header
	mov [os_icmp_request_type], al
	mov [os_icmp_request_code], ah
	xor ax, ax
	mov word [os_icmp_request_checksum], ax
	bswap ecx
	mov dword [os_icmp_request_idseq], ecx

	; Calculate header checksum
	mov rsi, os_icmp_request_header
	mov rcx, 4
	call os_internet_checksum
	mov rdi, os_icmp_request_checksum
	xchg ah, al
	stosw

	; Send the packet
	mov rcx, 8
	mov rbx, 1
	call os_send_ip_packet

	jmp os_icmp_send_request_done

os_icmp_send_request_invalid_type:
	mov rbx, 3

os_icmp_send_request_done:
	pop rdi
	pop rsi
	pop rcx
	pop rax
	ret

; -----------------------------------------------------------------------------


os_icmp_request_header:		times 8 db 0
os_icmp_request_type:		equ os_icmp_request_header
os_icmp_request_code:		equ os_icmp_request_header + 1
os_icmp_request_checksum:	equ os_icmp_request_header + 2
os_icmp_request_idseq:		equ os_icmp_request_header + 4


; =============================================================================
; EOF
