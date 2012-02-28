; Ethernet driver info (v1.0, Feb 9 2010)

[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label
	call b_ethernet_avail
	cmp rax, 0
	je no_network

	mov rdi, ethernet_driver_name
	call b_get_ethernet_driver

	mov rsi, ethernet_driver_msg
	call b_print_string

	mov rsi, ethernet_driver_name
	call b_print_string
	call b_print_newline
	jmp finish

no_network:
	mov rsi, nonet_msg
	call b_print_string

finish:

ret					; Return to OS


nonet_msg:		db 'Network is not enabled', 13, 0

ethernet_driver_msg	db 'Ethernet driver: ', 0
ethernet_driver_name	times 32 db 0
