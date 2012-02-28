; ARP utility program sender (v1.0, Feb 6 2012)
;


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label

	mov rdi, arp_table
	call b_get_arp_table

	mov rsi, arp_table
	
next_entry:
	cmp rcx, 0
	je finish
	mov rdi, ip_addr_str
	call b_ip_addr_to_str
	add rsi, 4
	mov rdi, mac_addr_str
	call b_mac_addr_to_str
	add rsi, 6
	mov rdi, rsi
	mov rsi, ip_addr_str
	call b_print_string
	mov al, ' ' 
	call b_print_char
	mov rsi, mac_addr_str
	call b_print_string
	call b_print_newline
	mov rsi, rdi
	dec rcx
	jmp next_entry

finish:

ret					; Return to OS

arp_table:	times 1024 db 0

ip_addr_str:	times 16 db 0
mac_addr_str:	times 18 db 0
