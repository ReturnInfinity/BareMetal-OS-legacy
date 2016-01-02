; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; INIT_PCI
; =============================================================================

align 16
db 'DEBUG: INIT_PCI '
align 16


init_pci:
	mov eax, 0x80000000		; Bit 31 set for 'Enabled'
	mov ebx, eax
	mov dx, PCI_CONFIG_ADDRESS
	out dx, eax
	in eax, dx
	xor edx, edx
	cmp eax, ebx
	sete dl				; Set byte if equal, otherwise clear
	mov byte [os_PCIEnabled], dl
	ret


; =============================================================================
; EOF
