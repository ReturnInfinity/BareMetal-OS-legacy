; MAC adress viewer program (v1.0, Feb 6 2012)

[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:
	mov rdi, mac_addr
	call b_get_mac_addr

	mov rsi, mac_addr
	mov rdi, mac_addr_str
	call b_mac_addr_to_str

	mov rsi, mac_adr_msg
	call b_print_string

	mov rsi, mac_addr_str
	call b_print_string

	call b_print_newline

ret

mac_adr_msg:	db	'Ethernet MAC address is ', 0

mac_addr:	times 6 db 0
mac_addr_str:	times 18 db 0
