; Put Pixel Test Program (v1.0, Jan 7 2014)
; Written by Ian Seyler
;
; BareMetal compile:
; nasm putpixel.asm -o putpixel.app


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label
	mov rdx, 20			; Address for start of video memory
	call [b_system_config]
	cmp rax, 0
	je novideo			; Bail out if graphics aren't enabled
	mov [VideoBase], rax
	mov rdx, 21			; Screen X dimension
	call [b_system_config]
	mov [VideoX], rax
	mov rdx, 22			; Screen Y dimension
	call [b_system_config]
	mov [VideoY], rax
	mov rdx, 23			; Screen BPP
	call [b_system_config]
	mov [VideoBPP], rax

	mov ebx, 0x00200020		; Packet pixel location
	mov eax, 0x00ffffff		; Pixel color
	call put_pixel

	ret				; Return to OS

novideo:
	mov rsi, NoVideoMsg
	call [b_output]
	ret

; -----------------------------------------------------------------------------
; put_pixel -- Put a pixel on the screen
;  IN:	EBX = Packed X & Y coordinates (YYYYXXXX)
;	EAX = Pixel Details (AARRGGBB)
; OUT:	All registers preserved
put_pixel:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

; TODO - Add checks to make sure the pixel should actually be on screen.

	movzx ecx, word [VideoX]
	movzx edi, byte [VideoBPP]
	mov edx, ebx
	shr ebx, 16			; Isolate Y coord
	movzx edx, dl			; Isolate X coord
	mul ecx, ebx			; Multiply Y by os_VideoX
	mov rdx, [VideoBase]
	add ecx, edx			; Add X

	lea edx, [ecx+ecx*4]		; EDX=5*ECX
	shl ecx, 2			; ECX=4*ECX
	mov ebx, eax
	and eax, 0x00FFFFFF		
	cmp dil, 32
	cmove eax, ebx
	cmovne ecx, edx
	mov [rdx+rcx], eax

put_pixel_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------

NoVideoMsg: db 'Video mode is required for this program.', 13, 0
VideoBase: dq 0
VideoX: dq 0
VideoY: dq 0
VideoBPP: dq 0

