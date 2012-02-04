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
	push rsi
	push rax

	; Check if reply or request


os_icmp_handler_request:
	; Swap the MAC addresses
	mov rax, [rsi]			; Grab the Destination MAC as 8 bytes even though the MAC is 6 bytes
	mov ax, [rsi+0x0C]		; Store the EtherType in the low 16-bits of RAX
	push rax			; Save the new Source MAC (with EtherType) to the stack
	mov rax, [rsi+0x06]		; Grab the Source MAC as 8 bytes (the last two bytes will be overwritten)
	mov [rsi], rax			; Store the new Destination MAC in the packet
	pop rax				; Restore the new Source MAC + EtherType
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

	pop rax
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
