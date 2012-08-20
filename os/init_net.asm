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
	; Search for a supported NIC
	xor ebx, ebx			; Clear the Bus number
	xor ecx, ecx			; Clear the Device/Slot number
	mov edx, 2			; Register 2 for Class code/Subclass

init_net_probe_next:
	call os_pci_read_reg
	shr eax, 24			; Move the Class code to AL
	cmp al, 0x02			; Network Controller Class Code
	je init_net_probe_find_driver	; Found a Network Controller... now search for a driver
	add ecx, 1
	cmp ecx, 32			; Maximum 32 devices per bus
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
	je init_net_probe_not_found		; No suported NIC found
	cmp ax, 0xFFFF				; New driver ID?
	je init_net_probe_find_next_driver	; We found the next driver type
	cmp eax, r8d
	je init_net_probe_found			; If Carry is clear then we found a supported NIC
	jmp init_net_probe_find_next_device	; Check the next device

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
