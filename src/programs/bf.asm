; =============================================================================
; Brainf*ck -- A 64-bit Brainf*ck interpreter
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; http://en.wikipedia.org/wiki/Brainfuck
; =============================================================================

[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

bf_start:
	; clear memory here

bf_run:
	mov rsi, [codepointer]
	lodsb
	add qword [codepointer], 1
	cmp al, '>'
	je incptr
	cmp al, '<'
	je decptr
	cmp al, '+'
	je incdata
	cmp al, '-'
	je decdata
	cmp al, '.'
	je outchar
	cmp al, ','
	je inchar
	cmp al, '['
	je startloop
	cmp al, ']'
	je endloop
	ret

incptr:
	add qword [datapointer], 8
	jmp bf_run

decptr:
	sub qword [datapointer], 8
	jmp bf_run

incdata:
	mov rax, [datapointer]
	mov rsi, rax
	mov rdi, rax
	lodsq
	add rax, 1
	stosq
	jmp bf_run

decdata:
	mov rax, [datapointer]
	mov rsi, rax
	mov rdi, rax
	lodsq
	sub rax, 1
	stosq
	jmp bf_run

outchar:
	mov rsi, [datapointer]
	lodsq
	call b_print_char
	jmp bf_run

inchar:
	mov rdi, [datapointer]
	xor rax, rax
	call b_input_key_wait
	stosq
	jmp bf_run

startloop:
	mov rsi, [datapointer]
	lodsq
	cmp rax, 0
	jne bf_run
	mov rsi, [codepointer]
startloop_next:
	lodsb
	cmp al, ']'
	jne startloop_next
	mov qword [codepointer], rsi
	jmp bf_run

endloop:
	xchg bx, bx
	mov rsi, [datapointer]
	lodsq
	cmp rax, 0
	je bf_run
	mov rsi, [codepointer]
	std
endloop_next:
	lodsb
	cmp al, '['
	jne endloop_next
	add rsi, 1
	mov qword [codepointer], rsi
	cld
	jmp bf_run	

align 16	
datapointer: dq data
codepointer: dq code

code:
db '>+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.>>>++++++++[<++++>-]<.>>>++++++++++[<+++++++++>-]<---.<<<<.+++.------.--------.>>+.', 0

align 16
data: