; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Ethernet Functions
; =============================================================================

align 16
db 'DEBUG: ETHERNET '
align 16


; -----------------------------------------------------------------------------
; os_ethernet_status -- Check if Ethernet is available
;  IN:	Nothing
; OUT:	RAX = MAC Address if Ethernet is enabled, otherwise 0
os_ethernet_status:
	push rsi
	push rcx

	cld
	xor eax, eax
	cmp byte [os_NetEnabled], 0
	je os_ethernet_status_end

	mov ecx, 6
	mov rsi, os_NetMAC
os_ethernet_status_loadMAC:
	shl rax, 8
	lodsb
	sub ecx, 1
	test ecx, ecx
	jnz os_ethernet_status_loadMAC

os_ethernet_status_end:
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_tx -- Transmit a packet via Ethernet
;  IN:	RSI = Memory location where packet is stored
;	RCX = Length of packet
; OUT:	Nothing. All registers preserved
os_ethernet_tx:
	push rsi
	push rdi
	push rcx
	push rax

	cmp byte [os_NetEnabled], 1		; Check if networking is enabled
	jne os_ethernet_tx_fail
	cmp rcx, 64				; An Ethernet packet must be at least 64 bytes
	jge os_ethernet_tx_maxcheck
	mov rcx, 64				; If it was below 64 then set to 64
	; FIXME - OS should pad the packet with 0's before sending if less than 64

os_ethernet_tx_maxcheck:	
	cmp rcx, 1522				; Fail if more than 1522 bytes
	jg os_ethernet_tx_fail

	mov rax, os_EthernetBusyLock		; Lock the Ethernet so only one send can happen at a time
	call os_smp_lock

	add qword [os_net_TXPackets], 1
	add qword [os_net_TXBytes], rcx
	call qword [os_net_transmit]

	mov rax, os_EthernetBusyLock
	call os_smp_unlock

os_ethernet_tx_fail:
	pop rax
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_rx -- Polls the Ethernet card for received data
;  IN:	RDI = Memory location where packet will be stored
; OUT:	RCX = Length of packet, 0 if no data
;	All other registers preserved
os_ethernet_rx:
	push rdi
	push rsi
	push rdx
	push rax

	xor ecx, ecx

	cmp byte [os_NetEnabled], 1
	jne os_ethernet_rx_fail

	mov rsi, os_EthernetBuffer
	mov ax, word [rsi]		; Grab the packet length
	cmp ax, 0			; Anything there?
	je os_ethernet_rx_fail		; If not, bail out
	mov word [rsi], cx		; Clear the packet length
	mov cx, ax			; Save the count
	add rsi, 2			; Skip the packet length word
	push rcx
	rep movsb
	pop rcx

os_ethernet_rx_fail:

	pop rax
	pop rdx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_ack_int -- Acknowledge an interrupt within the NIC
;  IN:	Nothing
; OUT:	RAX = Type of interrupt trigger
;	All other registers preserved
os_ethernet_ack_int:
	call qword [os_net_ack_int]

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_rx_from_interrupt -- Polls the Ethernet card for received data
;  IN:	RDI = Memory location where packet will be stored
; OUT:	RCX = Length of packet
;	All other registers preserved
os_ethernet_rx_from_interrupt:
	push rdi
	push rsi
	push rdx
	push rax

	xor ecx, ecx

; Call the poll function of the Ethernet card driver
	call qword [os_net_poll]
	add qword [os_net_RXPackets], 1
	add qword [os_net_RXBytes], rcx

	pop rax
	pop rdx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
