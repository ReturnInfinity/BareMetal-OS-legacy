; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Hard Drive Functions
; =============================================================================

align 16
db 'DEBUG: HDD      '
align 16


; NOTE:	These functions use LBA28. Maximum visible drive size is 128GiB
;	LBA48 would be needed to access sectors over 128GiB (up to 128PiB)
;	These functions are hard coded to access the Primary Master HDD


; -----------------------------------------------------------------------------
; readsectors -- Read sectors on the hard drive
; IN:	RAX = starting sector to read
;	RCX = number of sectors to read (1 - 256)
;	RDI = memory location to store sectors
; OUT:	RAX = RAX + number of sectors that were read
;	RCX = number of sectors that were read (0 on error)
;	RDI = RDI + (number of sectors * 512)
;	All other registers preserved
readsectors:
	push rdx
	push rcx
	push rbx
	push rax

	push rcx		; Save RCX for use in the read loop
	mov rbx, rcx		; Store number of sectors to read
	cmp rcx, 256
	jg readsectors_fail	; Over 256? Fail!
	jne readsectors_skip	; Not 256? No need to modify CL
	xor rcx, rcx		; 0 translates to 256
readsectors_skip:

	push rax		; Save RAX since we are about to overwrite it
	mov dx, 0x01F2		; 0x01F2 - Sector count Port 7:0
	mov al, cl		; Read CL sectors
	out dx, al
	pop rax			; Restore RAX which is our sector number
	inc dx			; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx			; 0x01F4 - LBA Mid Port 15:8
	shr rax, 8
	out dx, al
	inc dx			; 0x01F5 - LBA High Port 23:16
	shr rax, 8
	out dx, al
	inc dx			; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr rax, 8
	and al, 00001111b 	; Clear bits 4-7 just to be safe
	or al, 01000000b	; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx			; 0x01F7 - Command Port
	mov al, 0x20		; Read sector(s). 0x24 if LBA48
	out dx, al

	mov rcx, 4
readsectors_wait:
	in al, dx		; Read status from 0x01F7
	test al, 0x80		; BSY flag set?
	jne readsectors_retry
	test al, 0x08		; DRQ set?
	jne readsectors_dataready
readsectors_retry:
	dec rcx
	jg readsectors_wait
readsectors_nextsector:
	in al, dx		; Read status from 0x01F7
	test al, 0x80		; BSY flag set?
	jne readsectors_nextsector
	test al, 0x21		; ERR or DF set?
	jne readsectors_fail

readsectors_dataready:
	sub dx, 7		; Data port (0x1F0)
	mov rcx, 256		; Read 
	rep insw		; Copy a 512 byte sector to RDI
	add dx, 7		; Set DX back to status register (0x01F7)
	in al, dx		; Delay ~400ns to allow drive to set new values of BSY and DRQ
	in al, dx
	in al, dx
	in al, dx

	dec rbx			; RBX is the "sectors to read" counter
	cmp rbx, 0
	jne readsectors_nextsector

	pop rcx
	pop rax
	pop rbx
	add rax, rcx
	pop rcx
	pop rdx
ret

readsectors_fail:
	pop rcx
	pop rax
	pop rbx
	pop rcx
	pop rdx
	xor rcx, rcx		; Set RCX to 0 since nothing was read
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; writesectors -- Write sectors on the hard drive
; IN:	RAX = starting sector to write
;	RCX = number of sectors to write (1 - 256)
;	RSI = memory location of sectors
; OUT:	RAX = RAX + number of sectors that were written
;	RCX = number of sectors that were written (0 on error)
;	RSI = RSI + (number of sectors * 512)
;	All other registers preserved
writesectors:
	push rdx
	push rcx
	push rbx
	push rax

	push rcx		; Save RCX for use in the write loop
	mov rbx, rcx		; Store number of sectors to write
	cmp rcx, 256
	jg writesectors_fail	; Over 256? Fail!
	jne writesectors_skip	; Not 256? No need to modify CL
	xor rcx, rcx		; 0 translates to 256
writesectors_skip:
	
	push rax		; Save RAX since we are about to overwrite it
	mov dx, 0x01F2		; 0x01F2 - Sector count Port 7:0
	mov al, cl		; Write CL sectors
	out dx, al
	pop rax			; Restore RAX which is our sector number
	inc dx			; 0x01F3 - LBA Low Port 7:0
	out dx, al
	inc dx			; 0x01F4 - LBA Mid Port 15:8
	shr rax, 8
	out dx, al
	inc dx			; 0x01F5 - LBA High Port 23:16
	shr rax, 8
	out dx, al
	inc dx			; 0x01F6 - Device Port. Bit 6 set for LBA mode, Bit 4 for device (0 = master, 1 = slave), Bits 3-0 for LBA "Extra High" (27:24)
	shr rax, 8		; Bits 7 and 5 are obsolete in LBA mode so set to 0
	and al, 00001111b 	; Clear bits 4-7 just to be safe
	or al, 01000000b	; Turn bit 6 on since we want to use LBA addressing, leave device at 0 (master)
	out dx, al
	inc dx			; 0x01F7 - Command Port
	mov al, 0x30		; Write sector(s). 0x34 if LBA48
	out dx, al

	mov rcx, 4
writesectors_wait:
	in al, dx		; Read status from 0x01F7
	test al, 0x80		; BSY flag set?
	jne writesectors_retry
	test al, 0x08		; DRQ set?
	jne writesectors_dataready
writesectors_retry:
	dec rcx
	jg writesectors_wait
writesectors_nextsector:
	in al, dx		; Read status from 0x01F7
	test al, 0x80		; BSY flag set?
	jne writesectors_nextsector
	test al, 0x21		; ERR or DF set?
	jne writesectors_fail

writesectors_dataready:
	sub dx, 7		; Data port (0x01F0)
	mov rcx, 256		; Write 256 words (512 bytes)
writesectors_nextword:
	outsw			; Cannot use rep as a small delay is needed between each out
	sub rcx, 1
	cmp rcx, 0
	jne writesectors_nextword
	add dx, 7		; Set DX back to Command / Status Register (0x01F7)
	mov al, 0xE7		; Cache Flush command
	out dx, al
	in al, dx		; Delay ~400ns to allow drive to set new values of BSY and DRQ
	in al, dx
	in al, dx
	in al, dx

	dec rbx			; RBX is the "sectors to write" counter
	cmp rbx, 0
	jne writesectors_nextsector

	pop rcx
	pop rax
	pop rbx
	add rax, rcx
	pop rcx
	pop rdx
ret

writesectors_fail:
	pop rcx
	pop rax
	pop rbx
	pop rcx
	pop rdx
	xor rcx, rcx		; Set RCX to 0 since nothing was written
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
