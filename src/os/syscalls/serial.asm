; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Serial Port Functions
; =============================================================================

align 16
db 'DEBUG: SERIAL   '
align 16


; -----------------------------------------------------------------------------
; os_serial_send -- Send a byte over the primary serial port
; IN:	AL  = Byte to send over serial port
; OUT:	All registers preserved
os_serial_send:
	push rdx

	push rax		; Save RAX since the serial line status check clobbers AL
	mov dx, 0x03FD		; Serial Line Status register
os_serial_send_wait:
	in al, dx
	bt ax, 5		; Copy bit 5 (THR is empty) to the Carry Flag
	jnc os_serial_send_wait	; If the bit is not set then the queue isn't ready for another byte
	pop rax			; Get the byte back from the stack
	mov dx, 0x03F8		; Serial data register
	out dx, al		; Send the byte

	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_serial_recv -- Receive a byte from the primary serial port
; IN:	Nothing 
; OUT:	AL  = Byte recevied
;	Carry flag is set if a byte was received, otherwise AL is trashed
;	All other registers preserved
os_serial_recv:
	push rdx

	mov dx, 0x03FD		; Serial Line Status register
	in al, dx
	bt ax, 0		; Copy bit 0 (Data available) to the Carry Flag
	jnc os_serial_recv_no_data
	mov dx, 0x03F8		; Serial data register
	in al, dx		; Grab the byte

os_serial_recv_no_data:
	pop rdx
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
