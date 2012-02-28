; Ping program (v1.0, Feb 20 2012)
; Sends ICMP Echo request


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

	xor rdx, rdx
	mov edx, eax
	mov rax, 8			; Echo request code
	xor rcx, rcx
next_ping:
	mov rdi, ping_callback
	mov dword [ping_seqno], ecx
	call b_icmp_send_request
	cmp bl, 1
	je destination_unreachable
	jmp icmp_send_ok
destination_unreachable:
	mov rsi, destination_unreachable_msg
	call b_print_string
	jmp increase_counter
icmp_send_ok:
	mov rsi, success_msg
	call b_print_string
increase_counter:
	inc rcx
	cmp rcx, 4
	je finish
	push rcx
	mov rcx, 8
	call b_delay
	pop rcx
	jmp next_ping

invalid_ip:
	mov rsi, invalid_ip_msg		; Print the error message
	call b_print_string
	jmp finish
	
noargs:
	mov rsi, noargs_message		; Print the error message
	call b_print_string
	jmp finish

finish:
	ret

ping_callback:
	push rsi
	mov rsi, receive_msg
	call b_print_string
	pop rsi
	ret

ip_addr:			dw 0x00000000
ping_seqno:			dw 0x00000000

noargs_message:			db 'Usage: ping <ip>', 13, 0
invalid_ip_msg:			db 'Invalid IP address', 13, 0
destination_unreachable_msg:	db 'Destination unreachable', 13, 0
success_msg			db 'Send OK -- ', 0
receive_msg			db 'Echo received', 13, 0
