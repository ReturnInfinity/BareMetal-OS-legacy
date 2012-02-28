; IP configuration tool (v1.0, Feb 12 2012)
; Command line syntax:
;	ipconfig ip_addr/mask [gateway]


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label

	; First load the current ip config
	mov rdi, ip_config
	call b_get_ip_config

	call b_get_argc			; Get the number of arguments that were passed
	mov bl, al
	cmp al, 1
	je print_ip_addr		; If no argument is given, print current config
	cmp al, 3			; At least two arguments is needed
	jl print_usage
	cmp al, 4			; At most three arguments can be passed
	jg print_usage

	mov al, 1			; Get the first command line argument (the IP address)
	call b_get_argv			; Set RSI to point to the first argument
	mov rdi, ip_addr
	call b_parse_ip_addr		; Convert argv[1] to IP address
	mov rsi, ip_addr
	lodsd
	cmp eax, 0
	je invalid_ip

	; Convert argv[2] to network mask
	mov al, 2
	call b_get_argv
	mov rdi, subnet_mask
	call b_parse_ip_addr
	mov rsi, subnet_mask
	lodsd
	cmp eax, 0
	je invalid_ip

	; Check if gateway is given in command line arguments
	cmp bl, 4
	jne update_ipconfig

	; Convert argv[3] to gateway address
	mov al, 3
	call b_get_argv
	mov rdi, gateway
	call b_parse_ip_addr
	mov rsi, gateway
	lodsd
	cmp eax, 0
	je invalid_ip
	
update_ipconfig:
	mov rsi, ip_config
	call b_set_ip_config

print_ip_addr:
	mov rsi, ip_addr
	mov rdi, ip_addr_str
	call b_ip_addr_to_str

	mov rsi, subnet_mask
	mov rdi, net_mask_str
	call b_ip_addr_to_str

	mov rsi, gateway
	mov rdi, gateway_str
	call b_ip_addr_to_str

	mov rsi, ip_addr_msg
	call b_print_string
	call b_print_newline

	mov rsi, net_mask_msg
	call b_print_string
	call b_print_newline

	mov rsi, gateway_msg
	call b_print_string
	call b_print_newline

	jmp finish

invalid_ip:
	mov rsi, invalid_ip_msg		; Print the error message
	call b_print_string
	jmp finish
	
print_usage:
	mov rsi, usage_message		; Print the error message
	call b_print_string

finish:

ret					; Return to OS


ip_config		times 12 db 0

ip_addr:		equ ip_config
subnet_mask		equ ip_config + 4
gateway			equ ip_config + 8

ip_addr_msg:		db 'IP Address:   255.255.255.255', 0
net_mask_msg:		db 'Network mask: 255.255.255.255', 0
gateway_msg:		db 'Gateway:      255.255.255.255', 0

ip_addr_str:		equ ip_addr_msg  + 14
net_mask_str:		equ net_mask_msg + 14
gateway_str:		equ gateway_msg  + 14

usage_message:		db 'Usage: ipconfig ip mask [gateway]', 13, 0
invalid_ip_msg:		db 'Invalid IP address', 13, 0
invalid_netmask_msg:	db 'Invalid network mask', 13, 0
invalid_gateway_msg:	db 'Invalid gateway address', 13, 0
