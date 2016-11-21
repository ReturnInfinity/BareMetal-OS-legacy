; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
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
	inc ecx
	cmp ecx, 256			; Maximum 256 devices/functions per bus
	je init_ahci_probe_next_bus
	jmp init_ahci_probe_next

init_ahci_probe_next_bus:
	xor ecx, ecx
	inc ebx
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

; Enable AHCI
	xor eax, eax
	bts eax, 31
	mov [rsi+AHCI_GHC], eax

; Search the implemented ports for a drive
	mov eax, [rsi+AHCI_PI]		; PI – Ports Implemented
	mov edx, eax
	xor ecx, ecx
	mov ebx, 0x128			; Offset to Port 0 Serial ATA Status
nextport:
	bt edx, 0			; Valid port?
	jnc nodrive
	mov eax, [rsi+rbx]
	test eax, eax
	jnz founddrive

nodrive:
	inc ecx
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

	mov eax, [rdi+AHCI_PxCMD]	; Stop the port
	btr eax, 4			; FRE
	btr eax, 0			; ST
	mov [rdi+AHCI_PxCMD], eax

	xor eax, eax
	mov [rdi+AHCI_PxCI], eax	; Clear all command slots

	mov rax, ahci_cmdlist		; 1024 bytes per port
	stosd				; Offset 00h: PxCLB – Port x Command List Base Address
	shr rax, 32			; 63..32 bits of address
	stosd				; Offset 04h: PxCLBU – Port x Command List Base Address Upper 32-bits
	mov rax, ahci_receivedfis	; 256 or 4096 bytes per port
	stosd				; Offset 08h: PxFB – Port x FIS Base Address
	shr rax, 32			; 63..32 bits of address
	stosd				; Offset 0Ch: PxFBU – Port x FIS Base Address Upper 32-bits
	stosd				; Offset 10h: PxIS – Port x Interrupt Status
	stosd				; Offset 14h: PxIE – Port x Interrupt Enable

	; Query drive
	pop rcx				; Restore port number
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
	push rdi			; Save the destination memory address

	mov rsi, [ahci_base]
	shl rcx, 7			; Quick multiply by 0x80
	add rcx, 0x100			; Offset to port 0
	add rsi, rcx

	; Build the Command List Header
	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	mov eax, 0x00010005		; 1 PRDTL Entry, Command FIS Length = 20 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov rax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	shr rax, 32			; 63..32 bits of address
	stosd				; DW 3 - Command Table Base Address Upper
	xor eax, eax
	stosq				; DW 4-7 are reserved
	stosq

	; Build the Command Table
	mov rdi, ahci_cmdtable		; Build a command table for Port 0
	mov eax, 0x00EC8027		; EC identify, bit 15 set, fis 27 H2D
	stosd				; feature 7:0, command, c, fis
	xor eax, eax
	stosq				; the rest of the table can be clear
	stosq

	; PRDT - pysical region descriptor table
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the destination memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	xor eax, eax
	stosd				; Reserved
	mov eax, 0x000001FF		; 512 - 1
	stosd				; Description Information

	xor eax, eax
	mov [rsi+AHCI_PxIS], eax	; Port x Interrupt Status

	mov eax, 0x00000001		; Execute Command Slot 0
	mov [rsi+AHCI_PxCI], eax

	xor eax, eax
	bts eax, 4			; FIS Recieve Enable (FRE)
	bts eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax	; Offset to port 0 Command and Status

iddrive_poll:
	mov eax, [rsi+AHCI_PxCI]	; Read Command Slot 0 status
	test eax, eax
	jnz iddrive_poll

	mov eax, [rsi+AHCI_PxCMD]	; Offset to port 0
	btr eax, 4			; FIS Receive Enable (FRE)
	btr eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax

	pop rax
	pop rcx
	pop rsi
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; readsectors -- Read data from a SATA hard drive
; IN:	RAX = starting sector # to read (48-bit LBA address)
;	RCX = number of sectors to read (up to 8192 = 4MiB)
;	RDX = disk #
;	RDI = memory location to store sectors
; OUT:	RAX = RAX + number of sectors that were read
;	RCX = number of sectors that were read (0 on error)
;	RDI = RDI + (number of sectors read * 512)
;	All other registers preserved
readsectors:
	push rdx
	push rbx
	push rdi
	push rsi
	push rcx
	push rax

	mov rbx, 0xFFFFFFFFFFFF		; Check for invalid starting sector
	cmp rax, rbx
	jg readsectors_error

	push rcx			; Save the sector count
	push rdi			; Save the destination memory address
	push rax			; Save the block number
	push rax

	mov rsi, [ahci_base]
	shl rdx, 7			; Quick multiply by 0x80
	add rdx, 0x100			; Offset to port 0
	add rsi, rdx

	; Build the Command List Header
	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	xor eax, eax
	mov eax, 0x00010005		; 1 PRDTL Entry, Command FIS Length = 20 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov eax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	shr rax, 32			; 63..32 bits of address
	stosd				; DW 3 - Command Table Base Address Upper
	xor eax, eax
	stosq				; DW 4 - 7 are reserved
	stosq

	; Build the Command Table
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
	xor eax, eax
	stosd				; reserved

	; PRDT setup
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the destination memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	xor eax, eax
	stosd				; Reserved
	pop rax				; Restore the sector count
	shl rax, 9			; multiply by 512 for bytes
	dec rax				; subtract 1 (4.2.3.3, DBC is number of bytes - 1)
	stosd				; Description Information

	xor eax, eax
	mov [rsi+AHCI_PxIS], eax	; Port x Interrupt Status

	mov eax, 0x00000001		; Execute Command Slot 0
	mov [rsi+AHCI_PxCI], eax

	xor eax, eax
	bts eax, 4			; FIS Recieve Enable (FRE)
	bts eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax	; Offset to port 0 Command and Status

readsectors_poll:
	mov eax, [rsi+AHCI_PxCI]
	test eax, eax
	jnz readsectors_poll

	mov eax, [rsi+AHCI_PxCMD]	; Offset to port 0
	btr eax, 4			; FIS Receive Enable (FRE)
	btr eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax

	pop rax				; rax = start
	pop rcx				; rcx = number of sectors read
	add rax, rcx			; rax = start + number of sectors read
	pop rsi
	pop rdi
	mov rbx, rcx			; rdi = dest addr + number of bytes read
	shl rbx, 9
	add rdi, rbx
	pop rbx
	pop rdx
	ret

readsectors_error:
	pop rax
	pop rcx
	pop rsi
	pop rdi
	pop rbx
	pop rdx
	xor ecx, ecx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; writesectors -- Write data to a SATA hard drive
; IN:	RAX = starting sector # to write (48-bit LBA Address)
;	RCX = number of sectors to write (up to 8192 = 4MiB)
;	RDX = disk #
;	RSI = memory location of sectors
; OUT:	RAX = RAX + number of sectors that were written
;	RCX = number of sectors that were written (0 on error)
;	RSI = RSI + (number of sectors written * 512)
;	All other registers preserved
writesectors:
	push rdx
	push rbx
	push rdi
	push rsi
	push rcx
	push rax

	mov rbx, 0xFFFFFFFFFFFF		; Check for invalid starting sector
	cmp rax, rbx
	jg writesectors_error

	push rcx			; Save the sector count
	push rsi			; Save the source memory address
	push rax			; Save the block number
	push rax

	mov rsi, [ahci_base]
	shl rdx, 7			; Quick multiply by 0x80
	add rdx, 0x100			; Offset to port 0
	add rsi, rdx

	; Build the Command List Header
	mov rdi, ahci_cmdlist		; command list (1K with 32 entries, 32 bytes each)
	xor eax, eax
	mov eax, 0x00010045		; 1 PRDTL Entry, write flag (bit 6), Command FIS Length = 20 bytes
	stosd				; DW 0 - Description Information
	xor eax, eax
	stosd				; DW 1 - Command Status
	mov rax, ahci_cmdtable
	stosd				; DW 2 - Command Table Base Address
	shr rax, 32			; 63..32 bits of address
	stosd				; DW 3 - Command Table Base Address Upper
	xor eax, eax
	stosq				; DW 4 - 7 are reserved
	stosq

	; Build the Command Table
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
	xor eax, eax
	stosd				; reserved

	; PRDT setup
	mov rdi, ahci_cmdtable + 0x80
	pop rax				; Restore the source memory address
	stosd				; Data Base Address
	shr rax, 32
	stosd				; Data Base Address Upper
	xor eax, eax
	stosd				; Reserved
	pop rax				; Restore the sector count
	shl rax, 9			; multiply by 512 for bytes
	dec rax				; subtract 1 (4.2.3.3, DBC is number of bytes - 1)
	stosd				; Description Information

	xor eax, eax
	mov [rsi+AHCI_PxIS], eax	; Port x Interrupt Status

	mov eax, 0x00000001		; Execute Command Slot 0
	mov [rsi+AHCI_PxCI], eax

	xor eax, eax
	bts eax, 4			; FIS Recieve Enable (FRE)
	bts eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax	; Offset to port 0 Command and Status

writesectors_poll:
	mov eax, [rsi+AHCI_PxCI]
	test eax, eax
	jnz writesectors_poll

	mov eax, [rsi+AHCI_PxCMD]	; Offset to port 0
	btr eax, 4			; FIS Receive Enable (FRE)
	btr eax, 0			; Start (ST)
	mov [rsi+AHCI_PxCMD], eax

	pop rax				; rax = start
	pop rcx				; rcx = number of sectors read
	add rax, rcx			; rax = start + number of sectors written
	pop rsi
	pop rdi
	mov rbx, rcx			; rdi = dest addr + number of bytes written
	shl rbx, 9
	add rdi, rbx
	pop rbx
	pop rdx
	ret

writesectors_error:
	pop rax
	pop rcx
	pop rsi
	pop rdi
	pop rbx
	pop rdx
	xor ecx, ecx
	ret
; -----------------------------------------------------------------------------


; HBA Memory Registers
; 0x0000 - 0x002B	Generic Host Control
; 0x002C - 0x005F	Reserved
; 0x0060 - 0x009F	Reserved for NVMHCI
; 0x00A0 - 0x00FF	Vendor Specific Registers
; 0x0100 - 0x017F	Port 0
; 0x0180 - 0x01FF	Port 1
; ...
; 0x1000 - 0x107F	Port 30
; 0x1080 - 0x10FF	Port 31

; Generic Host Control
AHCI_CAP		equ 0x0000 ; HBA Capabilities
AHCI_GHC		equ 0x0004 ; Global HBA Control
AHCI_IS			equ 0x0008 ; Interrupt Status Register
AHCI_PI			equ 0x000C ; Ports Implemented
AHCI_VS			equ 0x0010 ; AHCI Version
AHCI_CCC_CTL		equ 0x0014 ; Command Completion Coalescing Control
AHCI_CCC_PORTS		equ 0x0018 ; Command Completion Coalescing Ports
AHCI_EM_LOC		equ 0x001C ; Enclosure Management Location
AHCI_EM_CTL		equ 0x0020 ; Enclosure Management Control
AHCI_CAP2		equ 0x0024 ; HBA Capabilities Extended
AHCI_BOHC		equ 0x0028 ; BIOS/OS Handoff Control and Status

; Port Registers
; Port 0 starts at 100h, port 1 starts at 180h, port 2 starts at 200h, port 3 at 280h, etc.
AHCI_PxCLB		equ 0x0000 ; Port x Command List Base Address
AHCI_PxCLBU		equ 0x0004 ; Port x Command List Base Address Upper 32-bits
AHCI_PxFB		equ 0x0008 ; Port x FIS Base Address
AHCI_PxFBU		equ 0x000C ; Port x FIS Base Address Upper 32-bits
AHCI_PxIS		equ 0x0010 ; Port x Interrupt Status
AHCI_PxIE		equ 0x0014 ; Port x Interrupt Enable
AHCI_PxCMD		equ 0x0018 ; Port x Command and Status
AHCI_PxTFD		equ 0x0020 ; Port x Task File Data
AHCI_PxSIG		equ 0x0024 ; Port x Signature
AHCI_PxSSTS		equ 0x0028 ; Port x Serial ATA Status (SCR0: SStatus)
AHCI_PxSCTL		equ 0x002C ; Port x Serial ATA Control (SCR2: SControl)
AHCI_PxSERR		equ 0x0030 ; Port x Serial ATA Error (SCR1: SError)
AHCI_PxSACT		equ 0x0034 ; Port x Serial ATA Active (SCR3: SActive)
AHCI_PxCI		equ 0x0038 ; Port x Command Issue
AHCI_PxSNTF		equ 0x003C ; Port x Serial ATA Notification (SCR4: SNotification)
AHCI_PxFBS		equ 0x0040 ; Port x FIS-based Switching Control
AHCI_PxDEVSLP		equ 0x0044 ; Port x Device Sleep
; 0x0048 - 0x006F	Reserved
; 0x0070 - 0x007F	Port x Vendor Specific


; =============================================================================
; EOF
