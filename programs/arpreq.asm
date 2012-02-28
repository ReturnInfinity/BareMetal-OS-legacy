; ARP request sender (v1.0, Feb 6 2012)
;


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label

	call b_get_argc			; Get the number of arguments that were passed
	cmp al, 1			; Was the number 1?
	je noargs			; If so then bail out. The first argument is the program name

	mov al, 1			; Get the second command line argument (the IP address)
	call b_get_argv			; Set RSI to point to the second argument

	mov rdi, ip_addr
	call b_parse_ip_addr		; Convert argv[1] to numerical IP address
	mov rsi, ip_addr
	lodsd
	cmp eax, 0
	je invalid_ip

	call b_arp_request		; Send an ARP request to resolve EAX IP address
	jmp finish			; Skip to the end

invalid_ip:
	mov rsi, invalid_ip_msg		; Print the error message
	call b_print_string
	jmp finish
	
noargs:
	mov rsi, noargs_message		; Print the error message
	call b_print_string

finish:

ret					; Return to OS

ip_addr:	db 0,0,0,0

noargs_message:	db 'Usage: arpreq <ip>', 13, 0
invalid_ip_msg:	db 'Invalid IP address', 13, 0
