; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; COMMAND LINE INTERFACE
; =============================================================================

align 16
db 'DEBUG: CLI      '
align 16


os_command_line:
	mov rsi, prompt			; Prompt for input
	mov bl, 0x09			; Black background, Light Red text
	call os_print_string_with_color

	mov rdi, cli_temp_string
	mov rcx, 250			; Limit the input to 250 characters
	call os_input_string
	call os_print_newline		; The user hit enter so print a new line
	jrcxz os_command_line		; os_input_string stores the number of charaters received in RCX

	mov rsi, rdi
	call os_string_parse		; Remove extra spaces
	jrcxz os_command_line		; os_string_parse stores the number of words in RCX
	mov byte [cli_args], cl		; Store the number of words in the string

; Copy the first word in the string to a new string. This is the command/application to run
	xor rcx, rcx
	mov rsi, cli_temp_string
	mov rdi, cli_command_string
	push rdi			; Push the command string
nextbyte:
	add rcx, 1
	lodsb
	cmp al, ' '			; End of the word
	je endofcommand
	cmp al, 0x00			; End of the string
	je endofcommand
	cmp rcx, 13			; More than 12 bytes
	je endofcommand
	stosb
	jmp nextbyte
endofcommand:
	mov al, 0x00
	stosb				; Terminate the string

; At this point cli_command_string holds at least "a" and at most "abcdefgh.ijk"

	; Break the contents of cli_temp_string into individual strings
	mov rsi, cli_temp_string
	mov al, 0x20
	mov bl, 0x00
	call os_string_change_char

	pop rsi				; Pop the command string
	call os_string_uppercase	; Convert to uppercase for comparison

	mov rdi, cls_string		; 'CLS' entered?
	call os_string_compare
	jc near clear_screen

	mov rdi, dir_string		; 'DIR' entered?
	call os_string_compare
	jc near dir

	mov rdi, ver_string		; 'VER' entered?
	call os_string_compare
	jc near print_ver

	mov rdi, date_string		; 'DATE' entered?
	call os_string_compare
	jc near date

	mov rdi, exit_string		; 'EXIT' entered?
	call os_string_compare
	jc near exit

	mov rdi, help_string		; 'HELP' entered?
	call os_string_compare
	jc near print_help

	mov rdi, node_string		; 'NODE' entered?
	call os_string_compare
	jc near node

	mov rdi, time_string		; 'TIME' entered?
	call os_string_compare
	jc near time

	mov rdi, debug_string		; 'DEBUG' entered?
	call os_string_compare
	jc near debug

	mov rdi, reboot_string		; 'REBOOT' entered?
	call os_string_compare
	jc near reboot

	mov rdi, testzone_string	; 'TESTZONE' entered?
	call os_string_compare
	jc near testzone

	mov rdi, ipconfig_string	; 'IP' entered?
	call os_string_compare
	jc near ipconfig

; At this point it is not one of the built-in CLI functions. Prepare to check the filesystem.
	mov al, '.'
	call os_string_find_char	; Check for a '.' in the string
	cmp rax, 0
	jne full_name			; If there was a '.' then a suffix is present

; No suffix was present so we add the default application suffix of ".APP"
add_suffix:
	call os_string_length
	cmp rcx, 8
	jg fail				; If the string is longer than 8 chars we can't add a suffix

	mov rdi, cli_command_string
	mov rsi, appextension		; '.APP'
	call os_string_append		; Append the extension to the command string

; cli_command_string now contains a full filename
full_name:
	mov rsi, cli_command_string
	mov rdi, programlocation	; We load the program to this location in memory (currently 0x00100000 : at the 2MB mark)
	call os_file_read		; Read the file into memory
	jc fail				; If carry is set then the file was not found

	mov rax, programlocation	; 0x00100000 : at the 2MB mark
	xor rbx, rbx			; No arguements required (The app can get them with os_get_argc and os_get_argv)
	call os_smp_enqueue		; Queue the application to run on the next available core
	jmp exit			; The CLI can quit now. IRQ 8 will restart it when the program is finished

fail:					; We didn't get a valid command or program name
	mov rsi, not_found_msg
	call os_print_string
	jmp os_command_line

print_help:
	mov rsi, help_text
	call os_print_string
	jmp os_command_line

clear_screen:
	call os_screen_clear
	mov ax, 0x0018
	call os_move_cursor
	jmp os_command_line

print_ver:
	mov rsi, version_msg
	call os_print_string
	jmp os_command_line

dir:
	mov rdi, cli_temp_string
	mov rsi, rdi
	call os_file_get_list
	call os_print_string
	jmp os_command_line

date:
	mov rdi, cli_temp_string
	mov rsi, rdi
	call os_get_date_string
	call os_print_string
	call os_print_newline
	jmp os_command_line

time:
	mov rdi, cli_temp_string
	mov rsi, rdi
	call os_get_time_string
	call os_print_string
	call os_print_newline
	jmp os_command_line

node:
	jmp os_command_line		; Nothing here yet...

align 16
testzone:
	xchg bx, bx			; Bochs Magic Breakpoint

;	call os_ethernet_avail
;	call os_debug_dump_rax
	
;	mov rdi, cli_temp_string
;	mov rsi, rdi
;	mov rcx, 12
;	call os_input_string
;	call os_file_get_size
;	mov rax, rcx
;	call os_print_newline
;	call os_debug_dump_rax

;	cli
;	xor eax, eax			; Out-of-order execution can cause RDTSC to be executed later than expected
;	cpuid				; Execute a serializing instruction to force every preceding instruction to complete before allowing the program to continue
;	rdtsc
;	mov r15d, eax
	; Benchmark code start

;	sub rsp, 0x28
;	mov [rsp + 0x20], rax
;	mov [rsp + 0x18], rax
;	mov [rsp + 0x10], rax
;	mov [rsp + 0x8], rax
;	mov [rsp], rax
;	mov rax, [rsp]
;	mov rax, [rsp + 0x8]
;	mov rax, [rsp + 0x10]
;	mov rax, [rsp + 0x18]
;	mov rax, [rsp + 0x20]
;	add rsp, 0x28

;	push rax
;	push rax
;	push rax
;	push rax
;	push rax
;	pop rax
;	pop rax
;	pop rax
;	pop rax
;	pop rax

	; Benchmark code finish
;	xor eax, eax			; Out-of-order execution can cause RDTSC to be executed later than expected
;	cpuid				; Execute a serializing instruction to force every preceding instruction to complete before allowing the program to continue
;	rdtsc
;	sti
;	sub eax, r15d
;	call os_debug_dump_eax
;	call os_print_newline


;	call os_mem_get_free
;	mov rax, rcx
;	call os_debug_dump_rax
;	call os_print_newline

;	mov rcx, 16
;	call os_mem_allocate
;	push rax
;	call os_mem_get_free
;	mov rax, rcx
;	call os_debug_dump_rax
;	call os_print_newline

;	pop rax
;	mov rcx, 16
;	call os_mem_release
;	call os_mem_get_free
;	mov rax, rcx
;	call os_debug_dump_rax
;	mov al, ' '
;	call os_print_char
;	mov rax, rcx
;	call os_debug_dump_rax

;	call os_mem_get_free
;	mov rax, rcx
;	call os_debug_dump_rax
;	mov al, ' '
;	call os_print_char
;	xor eax, eax
;	mov ax, word [os_MemAmount]
;	shr ax, 1			; Divide actual memory by 2 (RAX now holds total pages)
;	call os_debug_dump_rax
;	call os_print_newline
;	mov rcx, 2			; 2 pages = 4 MiB
;	call os_mem_allocate
;	call os_debug_dump_rax
;	call os_print_newline

;	mov rax, 0x400000
;	call os_get_time_data

	mov rax, [os_HPETAddress + 0xF0]
	call os_debug_dump_rax
	call os_print_newline


;	ud2

;	xor rax, rax
;	xor rbx, rcx
;	xor rcx, rcx
;	xor rdx, rdx
;	div rax

	jmp os_command_line

ipconfig:
	call os_get_argc
	cmp al, 1
	je ipconfig_display
	cmp al, 3
	jl ipconfig_help
	cmp al, 4
	jg ipconfig_help

	; Filter the IP '.'s and the potential subnet '/'
	xchg bx, bx
	mov rsi, cli_temp_string
	add rsi, 9			; skip past 'ipconfig '. Will need updating if command name changes
	mov al, '/'
	mov bl, 0x00
	call os_string_change_char
	mov al, '.'
	mov bl, 0x00
	call os_string_change_char	; At this point the input is '192 168 0 2 24 192.168.0.1'

	; Parse the Host IP
	xor ebx, ebx
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	call os_string_parse_next_word
	bswap ebx
	mov [ip], ebx

	; Parse the Subnet
	call os_string_to_int
	mov ecx, 32
	sub ecx, eax
	mov ebx, 0xFFFFFFFF
	shl ebx, cl
	bswap ebx
	mov [sn], ebx
	call os_string_parse_next_word
	
	; Parse the Gateway IP
	mov al, '.'
	mov bl, 0x00
	call os_string_change_char	; Filter the Gateway IP '.'s
	xor ebx, ebx
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	shl ebx, 8
	call os_string_parse_next_word
	call os_string_to_int
	mov bl, al
	call os_string_parse_next_word
	bswap ebx
	mov [gw], ebx

	jmp os_command_line
	
os_string_parse_next_word:
	lodsb
	cmp al, 0
	jne os_string_parse_next_word

	ret

ipconfig_display:
	mov rsi, ip_ip
	call os_print_string
	mov rdi, cli_temp_string
	mov eax, [ip]
	call ipv4addr_to_string
	mov rsi, cli_temp_string
	call os_print_string

	mov rsi, ip_sn
	call os_print_string
	mov rdi, cli_temp_string
	mov eax, [sn]
	call ipv4addr_to_string
	mov rsi, cli_temp_string
	call os_print_string
	
	mov rsi, ip_gw
	call os_print_string
	mov rdi, cli_temp_string
	mov eax, [gw]
	call ipv4addr_to_string
	mov rsi, cli_temp_string
	call os_print_string
	
	mov rsi, ip_mc
	call os_print_string
	call os_debug_dump_MAC
	call os_print_newline
	jmp os_command_line

ipconfig_help:
	mov rsi, ipconfig_help_msg
	call os_print_string
	jmp os_command_line

reboot:
	in al, 0x64
	test al, 00000010b		; Wait for an empty Input Buffer
	jne reboot
	mov al, 0xFE
	out 0x64, al			; Send the reboot call to the keyboard controller
	jmp reboot

debug:
	call os_get_argc		; Check the argument number
	cmp al, 1
	je debug_dump_reg		; If it is only one then do a register dump
	mov rcx, 16	
	cmp al, 3			; Did we get at least 3?
	jl noamount			; If not no amount was specified
	mov al, 2
	call os_get_argv		; Get the amount of bytes to display
	call os_string_to_int		; Convert to an integer
	mov rcx, rax
noamount:
	mov al, 1
	call os_get_argv		; Get the starting memory address
	call os_hex_string_to_int
	mov rsi, rax
debug_default:
	call os_debug_dump_mem
	call os_print_newline

	jmp os_command_line

debug_dump_reg:
	call os_debug_dump_reg
	jmp os_command_line

exit:
	ret

; Strings
	help_text		db 'Built-in commands: CLS, DATE, DEBUG, DIR, HELP, IPCONFIG, REBOOT, TIME, VER', 13, 0
	not_found_msg		db 'Command or program not found', 13, 0
	version_msg		db 'BareMetal OS ', BAREMETALOS_VER, 13, 0

	cls_string		db 'CLS', 0
	dir_string		db 'DIR', 0
	ver_string		db 'VER', 0
	date_string		db 'DATE', 0
	exit_string		db 'EXIT', 0
	help_string		db 'HELP', 0
	node_string		db 'NODE', 0
	time_string		db 'TIME', 0
	debug_string		db 'DEBUG', 0
	reboot_string		db 'REBOOT', 0
	testzone_string		db 'TESTZONE', 0
	ipconfig_string		db 'IPCONFIG', 0
	ip_ip			db 'IP:       ', 0
	ip_sn			db 13, 'Subnet:   ', 0
	ip_gw			db 13, 'Gateway:  ', 0
	ip_mc			db 13, 'Physical: 0x', 0
	ipconfig_help_msg	db 'Invalid parameters.', 13, 'Usage is ipconfig IPAddress SubnetMask Gateway', 13, 'Example: ipconfig 192.168.0.2 24 192.168.0.1', 13, 0


ipv4addr_to_string:
	push rbx
	
	mov ebx, eax
	xor eax, eax
	mov al, bl
	call os_int_to_string
	mov al, '.'
	sub rdi, 1
	stosb
	shr ebx, 8
	mov al, bl
	call os_int_to_string
	mov al, '.'
	sub rdi, 1
	stosb
	shr ebx, 8
	mov al, bl
	call os_int_to_string
	mov al, '.'
	sub rdi, 1
	stosb
	shr ebx, 8
	mov al, bl
	call os_int_to_string

	pop rbx
ret

; =============================================================================
; EOF
