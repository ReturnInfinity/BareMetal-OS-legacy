; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; INIT_NET
; =============================================================================

align 16
db 'DEBUG: INIT_NET '
align 16


init_net:
	mov rsi, networkmsg
	call os_output

	; Search for a supported NIC
	xor ebx, ebx			; Clear the Bus number
	xor ecx, ecx			; Clear the Device/Slot number
	mov edx, 2			; Register 2 for Class code/Subclass

init_net_probe_next:
	call os_pci_read_reg
	shr eax, 16			; Move the Class/Subclass code to AX
	cmp ax, 0x0200			; Network Controller (02) / Ethernet (00)
	je init_net_probe_find_driver	; Found a Network Controller... now search for a driver
	add ecx, 1
	cmp ecx, 256			; Maximum 256 devices/functions per bus
	je init_net_probe_next_bus
	jmp init_net_probe_next

init_net_probe_next_bus:
	xor ecx, ecx
	add ebx, 1
	cmp ebx, 256			; Maximum 256 buses
	je init_net_probe_not_found
	jmp init_net_probe_next

init_net_probe_find_driver:
	xor edx, edx				; Register 0 for Device/Vendor ID
	call os_pci_read_reg			; Read the Device/Vendor ID from the PCI device
	mov r8d, eax				; Save the Device/Vendor ID in R8D
	mov rsi, NIC_DeviceVendor_ID
	lodsd					; Load a driver ID - Low half must be 0xFFFF
init_net_probe_find_next_driver:
	mov rdx, rax				; Save the driver ID
init_net_probe_find_next_device:
	lodsd					; Load a device and vendor ID from our list of supported NICs
	cmp eax, 0x00000000			; 0x00000000 means we have reached the end of the list
	je init_net_probe_not_found		; No supported NIC found
	cmp ax, 0xFFFF				; New driver ID?
	je init_net_probe_find_next_driver	; We found the next driver type
	cmp eax, r8d
	je init_net_probe_found			; If Carry is clear then we found a supported NIC
	jmp init_net_probe_find_next_device	; Check the next device

init_net_probe_found:
	cmp edx, 0x8169FFFF
	je init_net_probe_found_rtl8169
	cmp edx, 0x8254FFFF
	je init_net_probe_found_i8254x
	jmp init_net_probe_not_found

init_net_probe_found_rtl8169:
	call os_net_rtl8169_init
	mov rdi, os_net_transmit
	mov rax, os_net_rtl8169_transmit
	stosq
	mov rax, os_net_rtl8169_poll
	stosq
	mov rax, os_net_rtl8169_ack_int
	stosq
	jmp init_net_probe_found_finish

init_net_probe_found_i8254x:
	call os_net_i8254x_init
	mov rdi, os_net_transmit
	mov rax, os_net_i8254x_transmit
	stosq
	mov rax, os_net_i8254x_poll
	stosq
	mov rax, os_net_i8254x_ack_int
	stosq
	jmp init_net_probe_found_finish

init_net_probe_found_finish:
	xor eax, eax
	mov al, [os_NetIRQ]

	add al, 0x20
	mov rdi, rax
	mov rax, network
	call create_gate

	; Enable the Network IRQ
	mov al, [os_NetIRQ]
	call os_pic_mask_clear

	mov byte [os_NetEnabled], 1	; A supported NIC was found. Signal to the OS that networking is enabled
	call os_ethernet_ack_int	; Call the driver function to acknowledge the interrupt internally

	mov cl, 6
	mov rsi, os_NetMAC
nextbyte:
	lodsb
	call os_debug_dump_al
	sub cl, 1
	cmp cl, 0
	jne nextbyte
	mov rsi, closebracketmsg
	call os_output
	ret
	
init_net_probe_not_found:
	mov rsi, namsg
	call os_output
	mov rsi, closebracketmsg
	call os_output
	ret


; =============================================================================
; EOF
