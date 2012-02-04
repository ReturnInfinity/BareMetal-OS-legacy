; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; PC Speaker Sound Functions
; =============================================================================

align 16
db 'DEBUG: SOUND    '
align 16


; -----------------------------------------------------------------------------
; os_speaker_tone -- Generate a tone on the PC speaker
; IN:	RAX = note frequency
; OUT:	All registers preserved
; Note:	Call os_speaker_off to stop the tone
os_speaker_tone:
	push rax
	push rcx

	mov cx, ax		; Store note value for now
	mov al, 182
	out 0x43, al		; System timers..
	mov ax, cx		; Set up frequency
	out 0x42, al
	mov al, ah		; 64-bit mode.... AH allowed????
	out 0x42, al
	in al, 0x61		; Switch PC speaker on
	or al, 0x03
	out 0x61, al

	pop rcx
	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN:	Nothing
; OUT:	All registers preserved
os_speaker_off:
	push rax

	in al, 0x61		; Switch PC speaker off
	and al, 0xFC
	out 0x61, al

	pop rax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_speaker_beep -- Create a standard OS beep
; IN:	Nothing
; OUT:	All registers preserved
os_speaker_beep:
	push rax
	push rcx

	xor eax, eax
	mov ax, 0x0C80
	call os_speaker_tone
	mov ax, 2		; A quarter of a second
	call os_delay
	call os_speaker_off

	pop rcx
	pop rax
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
