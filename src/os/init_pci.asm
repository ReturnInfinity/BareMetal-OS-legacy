; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; INIT_PCI
; =============================================================================

align 16
db 'DEBUG: INIT_PCI '
align 16


init_pci:
	; 
	mov eax, 0x80000000
	mov dx, PCI_CONFIG_ADDRESS
	out dx, eax
	in eax, dx
	cmp eax, 0x80000000
	jne init_pci_not_found
	mov byte [os_PCIEnabled], 1

init_pci_not_found:

ret


; =============================================================================
; EOF
