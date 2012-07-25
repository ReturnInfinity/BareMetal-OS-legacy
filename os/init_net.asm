; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; INIT_NET
; =============================================================================

align 16
db 'DEBUG: INIT_NET '
align 16


init_net:
	; Initialize the ARP table to zero
	push rdi
	push rcx
	push rax
	mov rdi, arp_table
	mov rcx, 256
	xor rax, rax
	rep stosq
	pop rax
	pop rcx
	pop rdi

	; Search for a supported NIC
	mov rsi, NIC_DeviceVendor_ID

init_net_probe_next:
	lodsd					; Load a driver ID - Low half must be 0xFFFF
init_net_probe_next_driver:
	mov rdx, rax				; Save the driver ID
init_net_probe_next_device:
	lodsd					; Load a device and vendor ID from our list of supported NICs
	cmp eax, 0x00000000			; 0x00000000 means we have reached the end of the list
	je init_net_probe_not_found		; No suported NIC found
	cmp ax, 0xFFFF				; New driver ID?
	je init_net_probe_next_driver		; We found the next driver type
	call os_pci_find_device			; Returns BL = Bus number (8-bit value) and CL = Device/Slot number (5-bit value) if NIC was found
	jnc init_net_probe_found		; If Carry is clear then we found a supported NIC
	jmp init_net_probe_next_device		; Check the next device

init_net_probe_found:
%ifndef DISABLE_RTL8169
	cmp edx, 0x8169FFFF
	je init_net_probe_found_rtl8169
%endif
%ifndef DISABLE_I8254X
	cmp edx, 0x8254FFFF
	je init_net_probe_found_i8254x
%endif
	jmp init_net_probe_not_found

%ifndef DISABLE_RTL8169
init_net_probe_found_rtl8169:
	call os_net_rtl8169_init
	mov rdi, NIC_name_ptr
	mov rax, device_name_rtl8169
	mov [rdi], rax
	mov rdi, os_net_transmit
	mov rax, os_net_rtl8169_transmit
	stosq
	mov rax, os_net_rtl8169_poll
	stosq
	mov rax, os_net_rtl8169_ack_int
	stosq
	jmp init_net_probe_found_finish
%endif

%ifndef DISABLE_I8254X
init_net_probe_found_i8254x:
	call os_net_i8254x_init
	mov rdi, NIC_name_ptr
	mov rax, device_name_i8254x
	stosq
	mov rdi, os_net_transmit
	mov rax, os_net_i8254x_transmit
	stosq
	mov rax, os_net_i8254x_poll
	stosq
	mov rax, os_net_i8254x_ack_int
	stosq
	jmp init_net_probe_found_finish
%endif

init_net_probe_found_finish:
	xor eax, eax
	mov al, [os_NetIRQ]
	push rax			; Save the IRQ
	add al, 0x20
	mov rdi, rax
	mov rax, network
	call create_gate
	pop rax				; Restore the IRQ
	mov rcx, rax
	add rax, 0x20
	bts rax, 13			; 1=Low active
	bts rax, 15			; 1=Level sensitive
	call ioapic_entry_write

	mov byte [os_NetEnabled], 1	; A supported NIC was found. Signal to the OS that networking is enabled
	call os_ethernet_ack_int	; Call the driver function to acknowledge the interrupt internally

init_net_probe_not_found:

ret


; =============================================================================
; EOF
