; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; AHCI Driver
; =============================================================================

align 16
db 'DEBUG: AHCI     '
align 16


; -----------------------------------------------------------------------------
init_ahci:
	mov rsi, diskmsg
	call os_output

; Probe for an AHCI hard drive controller
	xor ebx, ebx			; Clear the Bus number
	xor ecx, ecx			; Clear the Device/Slot number
	mov edx, 2			; Register 2 for Class code/Subclass
	
init_ahci_probe_next:
	call os_pci_read_reg
	shr eax, 16			; Move the Class/Subclass code to AX
	cmp ax, 0x0106			; Mass Storage Controller (01) / SATA Controller (06)
	je init_ahci_found		; Found a SATA Controller
	add ecx, 1
	cmp ecx, 256			; Maximum 256 devices/functions per bus
	je init_ahci_probe_next_bus
	jmp init_ahci_probe_next
	
init_ahci_probe_next_bus:
	xor ecx, ecx
	add ebx, 1
	cmp ebx, 256			; Maximum 256 buses
	je init_ahci_err_noahci
	jmp init_ahci_probe_next

init_ahci_found:
	mov dl, 9
	xor eax, eax
	call os_pci_read_reg		; BAR5 (AHCI Base Address Register)
	mov [ahci_base], rax

; Basic config of the controller, port 0
	mov rsi, rax			; RSI holds the ABAR
	mov rdi, rsi

; Search the implemented ports for a drive
	mov eax, [rsi+0x0C]		; PI – Ports Implemented
	mov edx, eax
	xor ecx, ecx
	mov ebx, 0x128			; Offset to Port 0 Serial ATA Status
nextport:
	bt edx, 0			; Valid port?
	jnc nodrive
	mov eax, [rsi+rbx]
	cmp eax, 0
	je nodrive
	jmp founddrive

nodrive:
	add ecx, 1
	shr edx, 1
	add ebx, 0x80			; Each port has a 128 byte memory space
	cmp ecx, 32
	je hdd_setup_err_nodisk
	jmp nextport

; Configure the first port found with a drive attached
founddrive:
	mov [ahci_port], ecx
	mov rdi, rsi
	add rdi, 0x100			; Offset to port 0
	push rcx			; Save port number
	shl rcx, 7			; Quick multiply by 0x80
	add rdi, rcx
	pop rcx				; Restore port number
	mov rax, ahci_cmdlist		; 1024 bytes per port
	stosd				; Offset 00h: PxCLB – Port x Command List Base Address
	xor eax, eax
	stosd				; Offset 04h: PxCLBU – Port x Command List Base Address Upper 32-bits
	mov rax, ahci_cmdlist + 0x1000	; 256 or 4096 bytes per port
	stosd				; Offset 08h: PxFB – Port x FIS Base Address
	xor eax, eax
	stosd				; Offset 0Ch: PxFBU – Port x FIS Base Address Upper 32-bits
	stosd				; Offset 10h: PxIS – Port x Interrupt Status
	stosd				; Offset 14h: PxIE – Port x Interrupt Enable

	; Query drive
	mov rdi, 0x200000
	call iddrive
	mov rsi, 0x200000
	mov eax, [rsi+200]		; Max LBA Extended
	shr rax, 11			; rax = rax * 512 / 1048576	MiB
;	shr rax, 21			; rax = rax * 512 / 1073741824	GiB
	mov [hd1_size], eax		; in mebibytes (MiB)
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output
	mov rsi, mibmsg
	call os_output

	; Found a bootable drive
	mov byte [os_DiskEnabled], 0x01

	ret

init_ahci_err_noahci:
hdd_setup_err_nodisk:
	mov rsi, namsg
	call os_output

	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; iddrive -- Identify a SATA drive
; IN:	RCX = Port # to query
;	RDI = memory location to store details (512 bytes)
; OUT:	Nothing, all registers preserved
iddrive:
	push rdi
	push rsi
	push rcx
	push rax

	shl rcx, 7			; Quick multiply by 0x80
	add rcx, 0x100			; Offset to port 0

	push rdi			; Save the destination memory address

	mov rsi, [ahci_base]

	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	xor eax, eax
	mov eax, 0x00010005 ;4		; 1 PRDTL Entry, Command FIS Length = 16 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov eax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	xor eax, eax
	stosd				; DW 3 - Command Table Base Address Upper
	stosd
	stosd
	stosd
	stosd
	; DW 4 - 7 are reserved

	; command table
	mov rdi, ahci_cmdtable		; Build a command table for Port 0
	mov eax, 0x00EC8027		; EC identify, bit 15 set, fis 27 H2D
	stosd				; feature 7:0, command, c, fis
	xor eax, eax
	stosd				; device, lba 23:16, lba 15:8, lba 7:0
	stosd				; feature 15:8, lba 47:40, lba 39:32, lba 31:24
	stosd				; control, ICC, count 15:8, count 7:0
;	stosd				; reserved
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the destination memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	xor eax, eax
	stosd				; Reserved
	mov eax, 0x000001FF		; 512 - 1
	stosd				; Description Information

	add rsi, rcx

	mov rdi, rsi
	add rdi, 0x10			; Port x Interrupt Status
	xor eax, eax
	stosd

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0 Command and Status
	mov eax, [rdi]
	bts eax, 4			; FRE
	bts eax, 0			; ST
	stosd

	mov rdi, rsi
	add rdi, 0x38			; Command Issue
	mov eax, 0x00000001		; Execute Command Slot 0
	stosd

iddrive_poll:
	mov eax, [rsi+0x38]
	cmp eax, 0
	jne iddrive_poll

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	btc eax, 4			; FRE
	btc eax, 0			; ST
	stosd

	pop rax
	pop rcx
	pop rsi
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; readsectors -- Read data from a SATA hard drive
; IN:	RAX = starting sector # to read
;	RCX = number of sectors to read (up to 8192 = 4MiB)
;	RDX = disk #
;	RDI = memory location to store sectors
; OUT:	RAX = RAX + number of sectors that were read
;	RCX = number of sectors that were read (0 on error)
;	RDI = RDI + (number of sectors read * 512)
;	All other registers preserved
readsectors:
	push rbx
	push rdi
	push rsi
	push rcx
	push rax

	push rcx			; Save the sector count
	push rdi			; Save the destination memory address
	push rax			; Save the block number
	push rax

	shl rdx, 7			; Quick multiply by 0x80
	add rdx, 0x100			; Offset to port 0

	mov rsi, [ahci_base]

	; Command list setup
	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	xor eax, eax
	mov eax, 0x00010005		; 1 PRDTL Entry, Command FIS Length = 20 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov eax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	xor eax, eax
	stosd				; DW 3 - Command Table Base Address Upper
	stosd
	stosd
	stosd
	stosd
	; DW 4 - 7 are reserved

	; Command FIS setup
	mov rdi, ahci_cmdtable		; Build a command table for Port 0
	mov eax, 0x00258027		; 25 READ DMA EXT, bit 15 set, fis 27 H2D
	stosd				; feature 7:0, command, c, fis
	pop rax				; Restore the start sector number
	shl rax, 36
	shr rax, 36			; Upper 36 bits cleared
	bts rax, 30			; bit 30 set for LBA
	stosd				; device, lba 23:16, lba 15:8, lba 7:0
	pop rax				; Restore the start sector number
	shr rax, 24
	stosd				; feature 15:8, lba 47:40, lba 39:32, lba 31:24
	mov rax, rcx			; Read the number of sectors given in rcx
	stosd				; control, ICC, count 15:8, count 7:0
	mov rax, 0x00000000
	stosd				; reserved

	; PRDT setup
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the destination memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	stosd				; Reserved
	pop rax				; Restore the sector count
	shl rax, 9			; multiply by 512 for bytes
	sub rax, 1			; subtract 1 (4.2.3.3, DBC is number of bytes - 1)
	stosd				; Description Information

	add rsi, rdx

	mov rdi, rsi
	add rdi, 0x10			; Port x Interrupt Status
	xor eax, eax
	stosd

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	bts eax, 4			; FRE
	bts eax, 0			; ST
	stosd

	mov rdi, rsi
	add rdi, 0x38			; Command Issue
	mov eax, 0x00000001		; Execute Command Slot 0
	stosd

.poll:
	mov eax, [rsi+0x38]
	cmp eax, 0
	jne .poll

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	btc eax, 4			; FRE
	btc eax, 0			; ST
	stosd

	pop rax				; rax = start
	pop rcx				; rcx = number of sectors read
	add rax, rcx			; rax = start + number of sectors read
	pop rsi
	pop rdi
	mov rbx, rcx			; rdi = dest addr + number of bytes read
	shl rbx, 9
	add rdi, rbx
	pop rbx
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; writesectors -- Write data tp a SATA hard drive
; IN:	RAX = starting sector # to write
;	RCX = number of sectors to write (up to 8192 = 4MiB)
;	RDX = disk #
;	RSI = memory location of sectors
; OUT:	RAX = RAX + number of sectors that were written
;	RCX = number of sectors that were written (0 on error)
;	RSI = RSI + (number of sectors written * 512)
;	All other registers preserved
writesectors:
	push rbx
	push rdi
	push rsi
	push rcx
	push rax

	push rcx			; Save the sector count
	push rsi			; Save the source memory address
	push rax			; Save the block number
	push rax

	shl rdx, 7			; Quick multiply by 0x80
	add rdx, 0x100			; Offset to port 0

	mov rsi, [ahci_base]

	; Command list setup
	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	xor eax, eax
	mov eax, 0x00010045		; 1 PRDTL Entry, write flag, Command FIS Length = 20 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov eax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	xor eax, eax
	stosd				; DW 3 - Command Table Base Address Upper
	stosd
	stosd
	stosd
	stosd
	; DW 4 - 7 are reserved

	; Command FIS setup
	mov rdi, ahci_cmdtable		; Build a command table for Port 0
	mov eax, 0x00358027		; 35 WRITE DMA EXT, bit 15 set, fis 27 H2D
	stosd				; feature 7:0, command, c, fis
	pop rax				; Restore the start sector number
	shl rax, 36
	shr rax, 36			; Upper 36 bits cleared
	bts rax, 30			; bit 30 set for LBA
	stosd				; device, lba 23:16, lba 15:8, lba 7:0
	pop rax				; Restore the start sector number
	shr rax, 24
	stosd				; feature 15:8, lba 47:40, lba 39:32, lba 31:24
	mov rax, rcx			; Read the number of sectors given in rcx
	stosd				; control, ICC, count 15:8, count 7:0
	mov rax, 0x00000000
	stosd				; reserved

	; PRDT setup
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the source memory address

	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	stosd				; Reserved
	pop rax				; Restore the sector count
	shl rax, 9			; multiply by 512 for bytes
	add rax, -1			; subtract 1 (4.2.3.3, DBC is number of bytes - 1)
	stosd				; Description Information

	add rsi, rdx

	mov rdi, rsi
	add rdi, 0x10			; Port x Interrupt Status
	xor eax, eax
	stosd

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	bts eax, 4			; FRE
	bts eax, 0			; ST
	stosd

	mov rdi, rsi
	add rdi, 0x38			; Command Issue
	mov eax, 0x00000001		; Execute Command Slot 0
	stosd

.poll:
	mov eax, [rsi+0x38]
	cmp eax, 0
	jne .poll

	mov rdi, rsi
	add rdi, 0x18			; Offset to port 0
	mov eax, [rdi]
	btc eax, 4			; FRE
	btc eax, 0			; ST
	stosd

	pop rax				; rax = start
	pop rcx				; rcx = number of sectors read
	add rax, rcx			; rax = start + number of sectors written
	pop rsi
	pop rdi
	mov rbx, rcx			; rdi = dest addr + number of bytes written
	shl rbx, 9
	add rdi, rbx
	pop rbx
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
