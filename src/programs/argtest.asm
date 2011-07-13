; Argument Test Program (v1.0, July 6 2010)
; Written by Ian Seyler
;
; BareMetal compile:
; nasm argtest.asm -o argtest.app


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label

	call b_get_argc			; Get the number of arguments that were passed
	cmp al, 1			; Was the number 1?
	je noargs			; If so then bail out. The first argument is the program name
	mov rsi, hello_message		; Load RSI with memory address of string
	call b_print_string		; Print the string that RSI points to
	mov al, 1			; Argument values start at 0 so we want the second one
	call b_get_argv			; Set RSI to point to the second argument
	call b_print_string		; Print the string
	call b_print_newline		; Print a new line
	jmp fin				; Skip to the end
	
noargs:
	mov rsi, noargs_message		; Print the error message
	call b_print_string

fin:

ret					; Return to OS

hello_message: db 'Hello, ', 0
noargs_message: db 'Abort: No arguments supplied.', 13, 0
