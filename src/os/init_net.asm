; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; INIT_NET
; =============================================================================

align 16
db 'DEBUG: INIT_NET '
align 16


init_net:
	; Search for a supported NIC
	mov rsi, NIC_DeviceVendor_ID

init_net_probe_next:
	lodsd					; Load a device and vendor ID from our list of supported NICs
	cmp eax, 0x00000000			; 0x00000000 means we have reached the end of the list
	je init_net_probe_not_found		; No suported NIC found
	call os_pci_find_device			; Returns BL = Bus number (8-bit value) and CL = Device/Slot number (5-bit value) if NIC was found
	jnc init_net_probe_found		; If Carry is clear then we found a supported NIC
	add rsi, 4				; Skip the device type
	jmp init_net_probe_next

init_net_probe_found:
	lodsd					; Load the device type
	cmp eax, 0x00008169
	je init_net_probe_found_rtl8169
	cmp eax, 0x00008254
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
	xor rax, rax
	mov al, [os_NetIRQ]
	add al, 0x20
	mov rdi, rax
	mov rax, network
	call create_gate
	mov byte [os_NetEnabled], 1		; A supported NIC was found. Signal to the OS that networking is enabled

init_net_probe_not_found:

ret


; =============================================================================
; EOF
