; -----------------------------------------------------------------
; EthTool v0.1 - Ethernet debugging tool
; Ian Seyler @ Return Infinity
; -----------------------------------------------------------------


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

filetest:
	mov rsi, startstring
	call b_print_string
	
	mov rcx, 4000000
	mov rsi, DataBuffer
	mov rdi, file1
	call b_file_write
	mov rsi, file1
	call b_print_string
	call b_print_newline

	mov rcx, 4000000
	mov rsi, DataBuffer
	mov rdi, file2
	call b_file_write
	mov rsi, file2
	call b_print_string
	call b_print_newline

	mov rcx, 4000000
	mov rsi, DataBuffer
	mov rdi, file3
	call b_file_write
	mov rsi, file3
	call b_print_string
	call b_print_newline

	mov rcx, 4000000
	mov rsi, DataBuffer
	mov rdi, file4
	call b_file_write
	mov rsi, file4
	call b_print_string
	call b_print_newline

	mov rsi, endstring
	call b_print_string

ret
; -----------------------------------------------------------------

startstring: db 'Start', 13, 0
endstring: db 'End', 13, 0
file1: db 'tst1.app', 0
file2: db 'tst2.app', 0
file3: db 'tst3.app', 0
file4: db 'tst4.app', 0

DataBuffer: db 0xCA, 0xFE