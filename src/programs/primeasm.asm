[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

primestart:				; Start of program label

	call b_get_timecounter
	mov [start], rax

; Calc
;	xor ecx, ecx
;loop1:

;The DIV instruction returns the quotient in AX and the remainder in DX. The modulus is the remainder.

;	mov ecx, 2
	
;	div rax, rcx
;	test rdx, rdx
;	jz meh
;	add rcx, 1
;	cmp rcx, blah
;	jne loop1
;	add qword [primes], 1
	

;	cmp rcx, [maxn]
;	add rcx, 1
;	jle loop1
	

	call b_get_timecounter
	mov [finish], rax

ret					; Return to OS


i: dq 0
j: dq 0
maxn: dq 400000
primes: dq 0
start: dq 0
finish: dq 0