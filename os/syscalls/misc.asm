; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Misc Functions
; =============================================================================

align 16
db 'DEBUG: MISC     '
align 16


; -----------------------------------------------------------------------------
; Display Core activity with flashing blocks on screen
; Blocks flash every quarter of a second
system_status:
	push rsi
	push rdi
	push rdx
	push rcx
	push rax

	; Display the dark grey bar
	mov ax, 0x8720			; 0x87 for dark grey background/white foreground, 0x20 for space (blank) character
	mov rdi, os_screen		; Draw to screen buffer
	push rdi
	mov rcx, 80
	rep stosw
	pop rdi

	; Display CPU status
	mov al, '['
	stosb
	add rdi, 1			; Skip the attribute byte
	mov rax, 0x8F208F758F708F63	; ' upc'
	stosq

	xor ecx, ecx
	xor edx, edx
	mov rsi, cpustatus
system_status_cpu_next:
	cmp cx, 256
	je system_status_cpu_calc
	add rcx, 1
	lodsb
	bt ax, 0			; Check to see if the Core is Present
	jnc system_status_cpu_next	; If not then check the next
	bt ax, 1
	jnc system_status_cpu_next
	add edx, 1
	jmp system_status_cpu_next

system_status_cpu_calc:
	mov rax, rdx			; Cores in use

	call system_status_print_string

	mov al, '/'
	stosb
	add rdi, 1

	xor eax, eax
	mov ax, word [os_NumCores]	; Total system memory in MiBs

	call system_status_print_string

system_status_cpu_done:
	mov al, ']'
	stosb
	add rdi, 1

	; Display memory status
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1			; Skip the attribute byte
	mov rax, 0x8F208F6D8F658F6D	; ' mem'
	stosq

	; Calculate % of memory that is in use
	call os_mem_get_free		; Free system memory in 2 MiB pages
	shl rcx, 1			; Quick multiply by 2 to get MiBs
	xor eax, eax
	mov eax, dword [os_MemAmount]	; Total system memory in MiBs
	push rax			; Save total MiBs
	sub rax, rcx			; Get MiB's in use

	call system_status_print_string

	mov al, '/'
	stosb
	add rdi, 1

	pop rax				; Restore total MiBs

	call system_status_print_string

system_status_mem_finish:
	mov al, ']'
	stosb
	add rdi, 1

	; Display network status
	cmp byte [os_NetEnabled], 1	; Print network details (if a supported NIC was initialized)
	jne system_status_no_network
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1
	mov rax, 0x8F208F748F658F6E	; ' ten'
	stosq
	mov al, 'T'
	stosb
	add rdi, 1
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x87			; Light Gray on Dark Gray (No Activity)
	cmp byte [os_NetActivity_TX], 1
	jne tx_idle
	mov al, 0x8F
	mov byte [os_NetActivity_TX], 0
tx_idle:
	stosb
	mov al, 'R'
	stosb
	add rdi, 1
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x87			; Light Gray on Dark Gray (No Activity)
	cmp byte [os_NetActivity_RX], 1
	jne rx_idle
	mov al, 0x8F
	mov byte [os_NetActivity_RX], 0
rx_idle:
	stosb
	mov al, ']'
	stosb
	add rdi, 1
system_status_no_network:

	; Display disk status
	cmp byte [os_DiskEnabled], 1	; Show disk activity (if a supported disk was initialized)
	jne system_status_no_disk
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1
	mov rax, 0x8F208F648F648F68	; ' ddh'
	stosq
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x87			; Light Gray on Dark Gray
	cmp byte [os_DiskActivity], 1
	jne hdd_idle
	mov al, 0x8F
hdd_idle:
	stosb
	mov al, ']'
	stosb
	add rdi, 1
system_status_no_disk:

	; Display the RTC pulse
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1
	mov rax, 0x8F208F638F748F72	; ' ctr'
	stosq
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov rax, [os_ClockCounter]
	bt rax, 0			; Check bit 0. Store bit 0 in CF
	jc system_status_rtc_flash_hi
	mov al, 0x87			; Light Gray on Dark Gray (Active Core Low)
	jmp system_status_rtc_flash_lo
system_status_rtc_flash_hi:
	mov al, 0x8F			; White on Dark Gray (Active Core High)
system_status_rtc_flash_lo:
	stosb				; Store the color (attribute) byte
	mov al, ']'
	stosb
	add rdi, 1

	; Display header text
	mov rdi, os_screen
	add rdi, 0x80
	mov rsi, system_status_header
	mov rcx, 16
headernext:
	lodsb
	stosb
	inc rdi
	dec rcx
	cmp rcx, 0
	jne headernext

	; Copy the system status to the screen
	mov rsi, os_screen
	mov rdi, 0xB8000
	mov rcx, 80
	rep movsw

	pop rax
	pop rcx
	pop rdx
	pop rdi
	pop rsi
	ret

system_status_print_string:
	push rdi
	mov rdi, os_temp
	mov rsi, rdi
	call os_int_to_string
	pop rdi
system_status_print_string_nextchar:
	lodsb
	cmp al, 0
	je system_status_print_string_finish
	stosb
	add rdi, 1
	jmp system_status_print_string_nextchar
system_status_print_string_finish:
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_delay -- Delay by X eights of a second
; IN:	RAX = Time in eights of a second
; OUT:	All registers preserved
; A value of 8 in RAX will delay 1 second and a value of 1 will delay 1/8 of a second
; This function depends on the RTC (IRQ 8) so interrupts must be enabled.
os_delay:
	push rcx
	push rax

	mov rcx, [os_ClockCounter]	; Grab the initial timer counter. It increments 8 times a second
	add rax, rcx			; Add RCX so we get the end time we want
os_delay_loop:
	cmp qword [os_ClockCounter], rax	; Compare it against our end time
	jle os_delay_loop		; Loop if RAX is still lower

	pop rax
	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_argc -- Return the number arguments passed to the program
; IN:	Nothing
; OUT:	AL = Number of arguments
os_get_argc:
	xor eax, eax
	mov al, [cli_args]
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_argv -- Get the value of an argument that was passed to the program
; IN:	AL = Argument number
; OUT:	RSI = Start of numbered argument string
os_get_argv:
	push rcx
	push rax
	mov rsi, cli_temp_string
	cmp al, 0x00
	je os_get_argv_end
	mov cl, al

os_get_argv_nextchar:
	lodsb
	cmp al, 0x00
	jne os_get_argv_nextchar
	dec cl
	cmp cl, 0
	jne os_get_argv_nextchar

os_get_argv_end:
	pop rax
	pop rcx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_system_config - View or modify system configuration options
; IN:	RDX = Function #
;	RAX = Variable
; OUT:	RAX = Result
os_system_config:
;	cmp rdx, X
;	je os_system_config_
	cmp rdx, 0
	je os_system_config_timecounter
	cmp rdx, 1
	je os_system_config_networkcallback_get
	cmp rdx, 2
	je os_system_config_networkcallback_set
	cmp rdx, 10
	je os_system_config_statusbar_hide
	cmp rdx, 11
	je os_system_config_statusbar_show
	ret

os_system_config_timecounter:
	mov rax, [os_ClockCounter]	; Grab the timer counter value. It increments 8 times a second
	ret

os_system_config_networkcallback_get:
	mov rax, [os_NetworkCallback]
	ret

os_system_config_networkcallback_set:
	mov qword [os_NetworkCallback], rax
	ret

os_system_config_statusbar_hide:
	mov byte [os_show_sysstatus], 0
	ret
	
os_system_config_statusbar_show:
	mov byte [os_show_sysstatus], 1
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_system_misc - Call misc OS sub-functions
; IN:	RDX = Function #
;	RAX = Variable 1
;	RCX = Variable 2
; OUT:	Dependant on system call
os_system_misc:
;	cmp rdx, X
;	je os_system_misc_
	cmp rdx, 1
	je os_system_misc_smp_get_id
	cmp rdx, 2
	je os_system_misc_smp_lock
	cmp rdx, 3
	je os_system_misc_smp_unlock
	cmp rdx, 4
	je os_system_misc_debug_dump_mem
	cmp rdx, 5
	je os_system_misc_debug_dump_rax
	ret

os_system_misc_smp_get_id:
	call os_smp_get_id
	ret

os_system_misc_smp_lock:
	call os_smp_lock
	ret

os_system_misc_smp_unlock:
	call os_smp_unlock
	ret

os_system_misc_debug_dump_mem:
	call os_debug_dump_mem
	ret

os_system_misc_debug_dump_rax:
	call os_debug_dump_rax
	ret
; -----------------------------------------------------------------------------



; -----------------------------------------------------------------------------
; reboot -- Reboot the computer
reboot:
	in al, 0x64
	test al, 00000010b		; Wait for an empty Input Buffer
	jne reboot
	mov al, 0xFE
	out 0x64, al			; Send the reboot call to the keyboard controller
	jmp reboot
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
