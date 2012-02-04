; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Broadcom 57XX NIC.
; =============================================================================

align 16
db 'DEBUG: BCM57xx  '
align 16


; -----------------------------------------------------------------------------
; os_net_bcm57xx_init - Initialize a Broadcom 57XX NIC
;  IN:	AL  = Bus number of the Realtek device
;	BL  = Device/Slot number of the Realtek device
os_net_bcm57xx_init:
	push rsi
	push rdx
	push rcx
	push rax

	; Grab the Base I/O Address of the device
	push ax
	mov cl, 0x04				; BAR0 - Lower 32 bits of memory address
	call os_pci_read_reg
;	mov dword [os_NetIOAddress], eax
	pop ax

	; Grab the IRQ of the device
	mov cl, 0x0F				; Get device's IRQ number from PCI Register 15 (IRQ is bits 7-0)
	call os_pci_read_reg
	mov [os_NetIRQ], al			; AL holds the IRQ

	; Grab the MAC address
	mov rsi, [os_NetIOBaseMem]
	mov eax, [rsi+0x410]				; Mac_Address_0 Part 1
	ror eax, 8
	mov [os_NetMAC], al
	rol eax, 8
	mov [os_NetMAC+1], al
	mov eax, [rsi+0x414]				; Mac_Address_0 Part 2
	rol eax, 8
	mov [os_NetMAC+2], al
	rol eax, 8
	mov [os_NetMAC+3], al
	rol eax, 8
	mov [os_NetMAC+4], al
	rol eax, 8
	mov [os_NetMAC+5], al

	; Enable the Network IRQ in the PIC 
	; IRQ value 0-7 set to zero bit 0-7 in 0x21 and value 8-15 set to zero bit 0-7 in 0xa1
	in al, 0x21				; low byte target 0x21
	mov bl, al
	mov al, [os_NetIRQ]
	mov dx, 0x21				; Use the low byte pic
	cmp al, 8
	jl os_net_bcm57xx_init_low
	sub al, 8				; IRQ 8-16
	push ax
	in al, 0xA1				; High byte target 0xA1
	mov bl, al
	pop ax
	mov dx, 0xA1				; Use the high byte pic
os_net_bcm57xx_init_low:
	mov cl, al
	mov al, 1
	shl al, cl
	not al
	and al, bl
	out dx, al

	; Reset the device
	call os_net_bcm57xx_reset

	pop rax
	pop rcx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_bcm57xx_reset - Reset a Broadcom 57XX NIC
;  IN:	Nothing
; OUT:	Nothing, all registers preserved
os_net_bcm57xx_reset:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_bcm57xx_transmit - Transmit a packet via a Broadcom 57XX NIC
;  IN:	RSI = Location of packet
;	RCX = Length of packet
; OUT:	Nothing
;	Uses RAX, RCX, RDX, RSI, RDI
; ToDo:	Check for proper timeout instead of calling os_delay
os_net_bcm57xx_transmit:

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_net_bcm57xx_poll - Polls the Broadcom 57XX NIC for a received packet
;  IN:	RDI = Location to store packet
; OUT:	RCX = Length of packet
;	Uses RAX, RCX, RDX, RSI, RDI
os_net_bcm57xx_poll:

os_net_bcm57xx_ack_int:

	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
