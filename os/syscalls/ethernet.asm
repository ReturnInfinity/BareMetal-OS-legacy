; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Ethernet Functions
; =============================================================================

align 16
db 'DEBUG: ETHERNET '
align 16


; Ethernet Type II Frame (64 - 1518 bytes)
; MAC Header (14 bytes)
;	Destination MAC Address (6 bytes)
;	Source MAC Address (6 bytes)
;	EtherType/Length (2 bytes)
; Payload (46 - 1500 bytes)
; CRC (4 bytes)
; Network card handles the Preamble (7 bytes), Start-of-Frame-Delimiter (1 byte), and Interframe Gap (12 bytes) 


; -----------------------------------------------------------------------------
; os_ethernet_avail -- Check if Ethernet is available
;  IN:	Nothing
; OUT:	RAX = MAC Address if Ethernet is enabled, otherwise 0
os_ethernet_avail:
	push rsi
	push rcx

	cld
	xor eax, eax
	cmp byte [os_NetEnabled], 0
	je os_ethernet_avail_end

	mov ecx, 6
	mov rsi, os_NetMAC
os_ethernet_avail_loadMAC:
	shl rax, 8
	lodsb
	sub ecx, 1
	test ecx, ecx
	jnz os_ethernet_avail_loadMAC

os_ethernet_avail_end:
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_tx -- Transmit a packet via Ethernet
;  IN:	RSI = Memory location where data is stored
;	RDI = Pointer to 48 bit destination address
;	 BX = Type of packet (If set to 0 then the EtherType will be set to the length of data)
;	 CX = Length of data
; OUT:	Nothing. All registers preserved
os_ethernet_tx:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	cmp byte [os_NetEnabled], 1
	jne os_ethernet_tx_fail
	cmp cx, 1500				; Fail if more then 1500 bytes
	jg os_ethernet_tx_fail

	mov rax, os_EthernetBusyLock		; Lock the Ethernet so only one send can happen at a time
	call os_smp_lock

	push rsi
	mov rsi, rdi
	mov rdi, os_ethernet_tx_buffer		; Build the packet to transfer at this location
	; TODO: Ask the driver where in memory the packet should be assembled.

	; Copy destination MAC address
	movsd
	movsw

	; Copy source MAC address
	mov rsi, os_NetMAC
	movsd
	movsw

	; Set the EtherType/Length
	cmp bx, 0
	jne os_ethernet_tx_typeset		; If EtherType is not set then use the Data Length instead
	mov bx, cx				; Length of data (Does not include header)
os_ethernet_tx_typeset:
	xchg bl, bh				; x86 is Little-endian but packets use Big-endian
	mov [rdi], bx
	add rdi, 2

	; Copy the packet data
	pop rsi
	mov rax, 0x000000000000FFFF
	and rcx, rax				; Clear the top 48 bits
	push rcx
	rep movsb
	pop rcx

	; Add padding to the packet data if needed
	cmp cx, 46				; Data needs to be at least 46 bytes (if not it needs to be padded)
	jge os_ethernet_tx_nopadding
	mov ax, 46
	sub ax, cx				; Padding needed = 46 - CX
	mov cx, ax
	xor ax, ax
	rep stosb				; Store 0x00 CX times
	mov cx, 46
os_ethernet_tx_nopadding:

	xor eax, eax
	stosd					; Store a blank CRC value

; Call the send function of the ethernet card driver
	add cx, 14				; Add 14 for the header bytes
	mov rsi, os_ethernet_tx_buffer
	call qword [os_net_transmit]

	mov rax, os_EthernetBusyLock
	call os_smp_unlock

os_ethernet_tx_fail:

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_tx_raw -- Transmit a raw frame via Ethernet
;  IN:	RSI = Memory location where raw frame is stored
;	 CX = Length of frame
; OUT:	Nothing. All registers preserved
os_ethernet_tx_raw:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx
	push rax
	
	cmp byte [os_NetEnabled], 1
	jne os_ethernet_tx_raw_fail
	cmp cx, 1500				; Fail if more then 1500 bytes
	jg os_ethernet_tx_raw_fail

	mov rax, os_EthernetBusyLock		; Lock the Ethernet so only one send can happen at a time
	call os_smp_lock

	; Copy the packet data
	mov rdi, os_ethernet_tx_buffer		; Build the packet to transfer at this location
	mov rax, 0x000000000000FFFF
	and rcx, rax				; Clear the top 48 bits
	push rcx
	rep movsb
	pop rcx

	; Add padding to the packet data if needed
	cmp cx, 46				; Data needs to be at least 46 bytes (if not it needs to be padded)
	jge os_ethernet_tx_raw_nopadding
	mov ax, 46
	sub ax, cx				; Padding needed = 46 - CX
	mov cx, ax
	xor ax, ax
	rep stosb				; Store 0x00 CX times
	mov cx, 46
os_ethernet_tx_raw_nopadding:

	xor eax, eax
	stosd					; Store a blank CRC value

; Call the send function of the ethernet card driver
	mov rsi, os_ethernet_tx_buffer
	call qword [os_net_transmit]

	mov rax, os_EthernetBusyLock
	call os_smp_unlock

os_ethernet_tx_raw_fail:

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_ethernet_rx -- Polls the Ethernet card for received data
;  IN:	RDI = Memory location where packet will be stored
; OUT:	RCX = Length of packet
;	All other registers preserved
os_ethernet_rx:
	push rdi
	push rsi
	push rdx
	push rax

	xor ecx, ecx

	cmp byte [os_NetEnabled], 1
	jne os_ethernet_rx_fail

; Is there anything in the ring buffer?
	mov al, byte [os_EthernetBuffer_C1]
	mov dl, byte [os_EthernetBuffer_C2]
	cmp al, dl				; If both counters are equal then the buffer is empty
	je os_ethernet_rx_fail

; Read the packet from the ring buffer to RDI
	mov rsi, os_EthernetBuffer
	xor rax, rax
	mov al, byte [os_EthernetBuffer_C1]
	push rax				; Save the ring element value
	shl rax, 11				; Quickly multiply RAX by 2048
	add rsi, rax				; RSI points to the packet in the ring buffer
	lodsw					; Load the packet length
	mov cx, ax				; Copy the packet length to RCX
	push rcx
	rep movsb				; Copy the packet to RDI
	pop rcx
	pop rax					; Restore the ring element value
	add al, 1
	cmp al, 128				; Max element number is 127
	jne os_ethernet_rx_buffer_nowrap
	xor al, al
os_ethernet_rx_buffer_nowrap:
	mov byte [os_EthernetBuffer_C1], al

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
	push rdx

	call qword [os_net_ack_int]

	pop rdx
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

; Call the poll function of the ethernet card driver
	call qword [os_net_poll]

	pop rax
	pop rdx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
