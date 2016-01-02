; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; Misc Functions
; =============================================================================

align 16
db 'DEBUG: MISC     '
align 16


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
; os_get_argv -- Get the value of an argument that was passed to the program
; IN:	RAX = Argument number
; OUT:	RAX = Start of numbered argument string
os_get_argv:
	push rsi
	push rcx
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
	mov rax, rsi
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_system_config - View or modify system configuration options
; IN:	RDX = Function #
;	RAX = Variable
; OUT:	RAX = Result
;	All other registers preserved
os_system_config:
	cmp rdx, 0
	je os_system_config_timecounter
	cmp rdx, 1
	je os_system_config_argc
	cmp rdx, 2
	je os_system_config_argv
	cmp rdx, 3
	je os_system_config_networkcallback_get
	cmp rdx, 4
	je os_system_config_networkcallback_set
	cmp rdx, 5
	je os_system_config_clockcallback_get
	cmp rdx, 6
	je os_system_config_clockcallback_set
	cmp rdx, 20
	je os_system_config_video_base
	cmp rdx, 21
	je os_system_config_video_x
	cmp rdx, 22
	je os_system_config_video_y
	cmp rdx, 23
	je os_system_config_video_bpp
	cmp rdx, 30
	je os_system_config_mac
	ret

os_system_config_timecounter:
	mov rax, [os_ClockCounter]	; Grab the timer counter value. It increments 8 times a second
	ret

os_system_config_argc:
	xor eax, eax
	mov al, [app_argc]
	ret

os_system_config_argv:
	call os_get_argv
	ret

os_system_config_networkcallback_get:
	mov rax, [os_NetworkCallback]
	ret

os_system_config_networkcallback_set:
	mov qword [os_NetworkCallback], rax
	ret

os_system_config_clockcallback_get:
	mov rax, [os_ClockCallback]
	ret

os_system_config_clockcallback_set:
	mov qword [os_ClockCallback], rax
	ret

os_system_config_video_base:
	mov rax, [os_VideoBase]
	ret

os_system_config_video_x:
	xor eax, eax
	mov ax, [os_VideoX]
	ret

os_system_config_video_y:
	xor eax, eax
	mov ax, [os_VideoY]
	ret

os_system_config_video_bpp:
	xor eax, eax
	mov al, [os_VideoDepth]
	ret

os_system_config_mac:
	call os_ethernet_status
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_system_misc - Call misc OS sub-functions
; IN:	RDX = Function #
;	RAX = Variable 1
;	RCX = Variable 2
; OUT:	RAX = Result 1, dependant on system call
;	RCX = Result 2, dependant on system call
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
	cmp rdx, 6
	je os_system_misc_delay
	cmp rdx, 7
	je os_system_misc_ethernet_status
	cmp rdx, 8
	je os_system_misc_mem_get_free
	cmp rdx, 9
	je os_system_misc_smp_numcores
	cmp rdx, 10
	je os_system_misc_smp_queuelen
	cmp rdx, 256
	je os_system_misc_reset
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
	push rsi
	mov rsi, rax
	call os_debug_dump_mem
	pop rsi
	ret

os_system_misc_debug_dump_rax:
	call os_debug_dump_rax
	ret

os_system_misc_delay:
	call os_delay
	ret

os_system_misc_ethernet_status:
	call os_ethernet_status
	ret

os_system_misc_mem_get_free:
	call os_mem_get_free
	ret

os_system_misc_smp_numcores:
	call os_smp_numcores
	ret

os_system_misc_smp_queuelen:
	call os_smp_queuelen
	ret

os_system_misc_reset:
	xor eax, eax
	mov qword [os_NetworkCallback], rax	; clear callbacks
	mov qword [os_ClockCallback], rax
	mov rdi, cpuqueue		; Clear SMP queue
	mov rcx, 512
	stosq
	call os_smp_get_id		; Reset all other cpu cores
	mov rbx, rax
	mov rsi, 0x0000000000005100	; Location in memory of the Pure64 CPU data
os_system_misc_reset_next_ap:
	cmp cx, 0
	je os_system_misc_reset_no_more_aps
	lodsb				; Load the CPU APIC ID
	cmp al, bl
	je os_system_misc_reset_skip_ap
	call os_smp_reset		; Reset the CPU
os_system_misc_reset_skip_ap:
	sub cx, 1
	jmp os_system_misc_reset_next_ap
os_system_misc_reset_no_more_aps:
	call init_memory_map		; Clear memory table
	mov rax, os_command_line	; Queue up the CLI
	call os_smp_enqueue
	int 0x81			; Reset this core
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
