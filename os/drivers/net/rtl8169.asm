; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Realtek 8169 NIC. http://wiki.osdev.org/RTL8169
; =============================================================================

align 16
db 'DEBUG: RTL8169  '
align 16


; -----------------------------------------------------------------------------
; Initialize a Realtek 8169 NIC
;  IN:	BL  = Bus number of the Realtek device
;	CL  = Device/Slot number of the Realtek device
os_net_rtl8169_init:
	push rsi
	push rdx
	push rcx
	push rax

	; Grab the Base I/O Address of the device
	mov dl, 0x04				; BAR0
	call os_pci_read_reg
	and eax, 0xFFFFFFFC			; EAX now holds the Base IO Address (clear the low 2 bits)
	mov word [os_NetIOAddress], ax

	; Grab the IRQ of the device
	mov dl, 0x0F				; Get device's IRQ number from PCI Register 15 (IRQ is bits 7-0)
	call os_pci_read_reg
	mov [os_NetIRQ], al			; AL holds the IRQ

	; Grab the MAC address
	mov dx, word [os_NetIOAddress]
	in al, dx
	mov [os_NetMAC], al
	add dx, 1
	in al, dx
	mov [os_NetMAC+1], al
	add dx, 1
	in al, dx
	mov [os_NetMAC+2], al
	add dx, 1
	in al, dx
	mov [os_NetMAC+3], al
	add dx, 1
	in al, dx
	mov [os_NetMAC+4], al
	add dx, 1
	in al, dx
	mov [os_NetMAC+5], al

	; Reset the device
	call os_net_rtl8169_reset

	pop rax
	pop rcx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_rtl8136_reset - Reset a Realtek 8169 NIC
;  IN:	Nothing
; OUT:	Nothing, all registers preserved
os_net_rtl8169_reset:
	push rdx
	push rcx
	push rax

	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_COMMAND
	mov al, 0x10				; Bit 4 set for Reset
	out dx, al
	mov cx, 1000				; Wait no longer for the reset to complete
wait_for_8169_reset:
	in al, dx
	test al, 0x10
	jz reset_8169_completed			; RST remains 1 during reset, Reset complete when 0
	dec cx
	jns wait_for_8169_reset
reset_8169_completed:

	; Unlock config registers
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_9346CR
	mov al, 0xC0				; Unlock
	out dx, al

	; Set the C+ Command
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_CCR
	in ax, dx
	bts ax, 3				; Enable PCI Multiple Read/Write
	btc ax, 9				; Little-endian mode
	out dx, ax

	; Power management?

	; Recieve configuration
	mov dx, word [os_NetIOAddress]
	add edx, RTL8169_REG_RCR
	mov eax, 0x0000E70A			; Set bits 1 (APM), 3 (AB), 8-10 (Unlimited), 13-15 (No limit)
	out dx, eax

	; Set up TCR
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_TCR
	mov eax, 0x03000700
	out dx, eax

	; Setup max RX size
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_MAXRX
	mov ax, 0x3FFF				; 16384 - 1
	out dx, ax

	; Setup max TX size
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_MAXTX
	mov al, 0x3B
	out dx, al

	; Set the Transmit Normal Priority Descriptor Start Address
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_TNPDS
	mov rax, os_eth_tx_buffer
	out dx, eax				; Write the low bits
	shr rax, 32
	add dx, 4
	out dx, eax				; Write the high bits
	mov eax, 0x70000000			; Set bit 30 (End of Descriptor Ring), 29 (FS), and 28 (LS)
	mov [os_eth_tx_buffer], eax

	; Set the Receive Descriptor Start Address
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_RDSAR
	mov rax, os_eth_rx_buffer
	out dx, eax				; Write the low bits
	shr rax, 32
	add dx, 4
	out dx, eax				; Write the high bits
	mov eax, 0x80001FF8			; Set bits 31 (Ownership), also buffer size (Max 0x1FF8)
	mov [os_eth_rx_buffer], eax
	mov rax, os_ethernet_rx_buffer
	mov [os_eth_rx_buffer+8], rax
	mov eax, 0xC0001FF8			; Set bits 31 (Ownership) and 30 (End of Descriptor Ring), also buffer size (Max 0x1FF8)
	mov [os_eth_rx_buffer+16], eax
	mov rax, os_ethernet_rx_buffer
	mov [os_eth_rx_buffer+24], rax

	; Initialize multicast registers (no filtering)
	mov eax, 0xFFFFFFFF
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_MAR0
	out dx, eax
	add dx, 4				; MAR4
	out dx, eax

	; Enable Rx/Tx in the Command register
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_COMMAND
	mov al, (1 << RTL8169_BIT_RE) | (1 << RTL8169_BIT_TE) ;0x0C				; Set bits 2 (TE) and 3 (RE)
	out dx, al

	; Enable Receive and Transmit interrupts
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_IMR
	mov ax, 0x0005				; Set bits 0 (RX OK) and 2 (TX OK)
	out dx, ax

	; Lock config register
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_9346CR
	mov al, 0x00				; Lock
	out dx, al

	pop rax
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_rtl8169_transmit - Transmit a packet via a Realtek 8169 NIC
;  IN:	RSI = Location of packet
;	RCX = Length of packet
; OUT:	Nothing
;	Uses RAX, RCX, RDX, RSI, RDI
; ToDo:	Check for proper timeout
os_net_rtl8169_transmit:
	mov rdi, os_eth_tx_buffer
	mov rax, rcx
	stosw					; Store the frame length
	add rdi, 6				; Should the other data be cleared here?
	mov rax, rsi
	stosq					; Store the packet location
	or dword [os_eth_tx_buffer], 0xF0000000	; Set bit 31 (OWN), 30 (EOR), 29 (FS), and 28 (LS)
	mov dx, word [os_NetIOAddress]
	add dx, RTL8169_REG_TPPOLL
	mov al, 0x40
	out dx, al				; Set up TX Polling
os_net_rtl8169_transmit_sendloop:
	mov eax, [os_eth_tx_buffer]
	and eax, 0x80000000			; Check the ownership bit (BT command instead?)
	cmp eax, 0x80000000			; If the ownership bit is clear then the NIC sent the packet
	je os_net_rtl8169_transmit_sendloop
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_rtl8169_poll - Polls the Realtek 8169 NIC for a received packet
;  IN:	RDI = Location to store packet
; OUT:	RCX = Length of packet
;	Uses RAX, RCX, RDX, RSI, RDI
os_net_rtl8169_poll:
	xor ecx, ecx
	mov cx, [os_eth_rx_buffer]
	and cx, 0x3FFF				; Clear the two high bits as length is bits 13-0
	cmp cx, 0x1FF8
	jne os_net_rtl8169_poll_first_descriptor
	mov cx, [os_eth_rx_buffer+16]
	and cx, 0x3FFF				; Clear the two high bits as length is bits 13-0
os_net_rtl8169_poll_first_descriptor:
	mov rsi, os_ethernet_rx_buffer
	push rcx
	rep movsb				; Copy the packet to the lacation stored in RDI
	pop rcx
	mov eax, 0x80001FF8			; Set bits 31 (Ownership), also buffer size (Max 0x1FF8)
	mov [os_eth_rx_buffer], eax
	mov rax, os_ethernet_rx_buffer
	mov [os_eth_rx_buffer+8], rax
	mov eax, 0xC0001FF8			; Set bits 31 (Ownership) and 30 (End of Descriptor Ring), also buffer size (Max 0x1FF8)
	mov [os_eth_rx_buffer+16], eax
	mov rax, os_ethernet_rx_buffer
	mov [os_eth_rx_buffer+24], rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_rtl8169_ack_int - Acknowledge an internal interrupt of the Realtek 8169 NIC
;  IN:	Nothing
; OUT:	RAX = Ethernet status
;	Uses RDI
os_net_rtl8169_ack_int:
	push rdx
	mov dx, word [os_NetIOAddress]		; Clear active interrupt sources
	add dx, RTL8169_REG_ISR
	in ax, dx
	out dx, ax
	shr eax, 2
	pop rdx
	ret
; -----------------------------------------------------------------------------


; Register Descriptors
	RTL8169_REG_IDR0	equ 0x00	; ID Register 0
	RTL8169_REG_IDR1	equ 0x01	; ID Register 1
	RTL8169_REG_IDR2	equ 0x02	; ID Register 2
	RTL8169_REG_IDR3	equ 0x03	; ID Register 3
	RTL8169_REG_IDR4	equ 0x04	; ID Register 4
	RTL8169_REG_IDR5	equ 0x05	; ID Register 5
	RTL8169_REG_MAR0	equ 0x08	; Multicast Register 0
	RTL8169_REG_MAR1	equ 0x09	; Multicast Register 1
	RTL8169_REG_MAR2	equ 0x0A	; Multicast Register 2
	RTL8169_REG_MAR3	equ 0x0B	; Multicast Register 3
	RTL8169_REG_MAR4	equ 0x0C	; Multicast Register 4
	RTL8169_REG_MAR5	equ 0x0D	; Multicast Register 5
	RTL8169_REG_MAR6	equ 0x0E	; Multicast Register 6
	RTL8169_REG_MAR7	equ 0x0F	; Multicast Register 7
	RTL8169_REG_TNPDS	equ 0x20	; Transmit Normal Priority Descriptors: Start address (64-bit). (256-byte alignment) 
	RTL8169_REG_COMMAND	equ 0x37	; Command Register
	RTL8169_REG_TPPOLL	equ 0x38	; Transmit Priority Polling Register
	RTL8169_REG_IMR		equ 0x3C	; Interrupt Mask Register
	RTL8169_REG_ISR		equ 0x3E	; Interrupt Status Register
	RTL8169_REG_TCR		equ 0x40	; Transmit (Tx) Configuration Register
	RTL8169_REG_RCR		equ 0x44	; Receive (Rx) Configuration Register
	RTL8169_REG_9346CR	equ 0x50	; 93C46 (93C56) Command Register
	RTL8169_REG_CONFIG0	equ 0x51	; Configuration Register 0
	RTL8169_REG_CONFIG1	equ 0x52	; Configuration Register 1
	RTL8169_REG_CONFIG2	equ 0x53	; Configuration Register 2
	RTL8169_REG_CONFIG3	equ 0x54	; Configuration Register 3
	RTL8169_REG_CONFIG4	equ 0x55	; Configuration Register 4
	RTL8169_REG_CONFIG5	equ 0x56	; Configuration Register 5
	RTL8169_REG_PHYAR	equ 0x60	; PHY Access Register 
	RTL8169_REG_PHYStatus	equ 0x6C	; PHY(GMII, MII, or TBI) Status Register 
	RTL8169_REG_MAXRX	equ 0xDA	; Mac Receive Packet Size Register
	RTL8169_REG_CCR		equ 0xE0	; C+ Command Register
	RTL8169_REG_RDSAR	equ 0xE4	; Receive Descriptor Start Address Register (256-byte alignment)
	RTL8169_REG_MAXTX	equ 0xEC	; Max Transmit Packet Size Register

; Command Register (Offset 0037h, R/W)	
	RTL8169_BIT_RST		equ 4		; Reset
	RTL8169_BIT_RE		equ 3		; Receiver Enable
	RTL8169_BIT_TE		equ 2		; Transmitter Enable

; Receive Configuration (Offset 0044h-0047h, R/W)
	RTL8169_BIT_AER		equ 5		; Accept Error
	RTL8169_BIT_AR		equ 4		; Accept Runt
	RTL8169_BIT_AB		equ 3		; Accept Broadcast Packets
	RTL8169_BIT_AM		equ 2		; Accept Multicast Packets
	RTL8169_BIT_APM		equ 1		; Accept Physical Match Packets
	RTL8169_BIT_AAP		equ 0		; Accept All Packets with Destination Address

; PHY Register Table
; BMCR (address 0x00) 
	RTL8169_BIT_ANE		equ 12		; Auto-Negotiation Enable


; =============================================================================
; EOF
