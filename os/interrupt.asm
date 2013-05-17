; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Interrupts
; =============================================================================

align 16
db 'DEBUG: INTERRUPT'
align 16


; -----------------------------------------------------------------------------
; Default exception handler
exception_gate:
	mov rsi, int_string00
	call os_output
	mov rsi, exc_string
	call os_output
	jmp $				; Hang
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Default interrupt handler
align 16
interrupt_gate:				; handler for all other interrupts
	iretq				; It was an undefined interrupt so return to caller
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Keyboard interrupt. IRQ 0x01, INT 0x21
; This IRQ runs whenever there is input on the keyboard
align 16
keyboard:
	push rdi
	push rbx
	push rax

	xor eax, eax

	in al, 0x60			; Get the scancode from the keyboard
	cmp al, 0x01
	je keyboard_escape
	cmp al, 0x2A			; Left Shift Make
	je keyboard_shift
	cmp al, 0x36			; Right Shift Make
	je keyboard_shift
	cmp al, 0xAA			; Left Shift Break
	je keyboard_noshift
	cmp al, 0xB6			; Right Shift Break
	je keyboard_noshift
	test al, 0x80
	jz keydown
	jmp keyup

keydown:
	cmp byte [key_shift], 0x00
	jne keyboard_lowercase
	jmp keyboard_uppercase

keyboard_lowercase:
	mov rbx, keylayoutupper
	jmp keyboard_processkey

keyboard_uppercase:	
	mov rbx, keylayoutlower

keyboard_processkey:			; Convert the scancode
	add rbx, rax
	mov bl, [rbx]
	mov [key], bl
	mov al, [key]
	jmp keyboard_done

keyboard_escape:
	jmp reboot

keyup:
	jmp keyboard_done

keyboard_shift:
	mov byte [key_shift], 0x01
	jmp keyboard_done

keyboard_noshift:
	mov byte [key_shift], 0x00
	jmp keyboard_done

keyboard_done:
	mov rdi, [os_LocalAPICAddress]	; Acknowledge the IRQ on APIC
	add rdi, 0xB0
	xor eax, eax
	stosd
	call os_smp_wakeup_all		; A terrible hack

	pop rax
	pop rbx
	pop rdi
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Real-time clock interrupt. IRQ 0x08, INT 0x28
; Currently this IRQ runs 8 times per second (As defined in init_64.asm)
; The supervisor lives here
align 16
rtc:
	push rsi
	push rcx
	push rax

	cld				; Clear direction flag
	add qword [os_ClockCounter], 1	; 64-bit counter started at bootup

	cmp byte [os_show_sysstatus], 0
	je rtc_no_sysstatus
	call system_status		; Show System Status information on screen
rtc_no_sysstatus:

	; Check to make sure that at least one core is running something
	cmp word [os_QueueLen], 0	; Check the length of the Queue
	jne rtc_end			; If it is greater than 0 then skip to the end
	mov rcx, 256
	mov rsi, cpustatus
nextcpu:
	lodsb
	dec rcx
	bt ax, 1			; Is bit 1 set? If so then the CPU is running a job
	jc rtc_end
	cmp rcx, 0
	jne nextcpu
	mov rax, os_command_line	; If nothing is running then restart the CLI
	call os_smp_enqueue

rtc_end:
	mov al, 0x0C			; Select RTC register C
	out 0x70, al			; Port 0x70 is the RTC index, and 0x71 is the RTC data
	in al, 0x71			; Read the value in register C
	mov rsi, [os_LocalAPICAddress]	; Acknowledge the IRQ on APIC
	xor eax, eax
	mov dword [rsi+0xB0], eax

	pop rax
	pop rcx
	pop rsi
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Network interrupt.
align 16
network:
	push rdi
	push rsi
	push rcx
	push rax

	cld				; Clear direction flag
	call os_ethernet_ack_int	; Call the driver function to acknowledge the interrupt internally

	bt ax, 0			; TX bit set (caused the IRQ?)
	jc network_tx			; If so then jump past RX section
	bt ax, 7			; RX bit set
	jnc network_end
network_rx_as_well:
	mov byte [os_NetActivity_RX], 1
	mov rdi, os_EthernetBuffer	; Raw packet is copied here
	push rdi
	add rdi, 2
	call os_ethernet_rx_from_interrupt
	pop rdi
	mov rax, rcx
	stosw				; Store the size of the packet
	cmp qword [os_NetworkCallback], 0	; Is it valid?
	je network_end			; If not then bail out.

	; We could do a 'call [os_NetworkCallback]' here but that would not be ideal.
	; A defective callback would hang the system if it never returned back to the
	; interrupt handler. Instead, we modify the stack so that the callback is
	; executed after the interrupt handler has finished. Once the callback has
	; finished, the execution flow will pick up back in the program.
	mov rcx, [os_NetworkCallback]	; RCX stores the callback address
	mov rsi, rsp			; Copy the current stack pointer to RSI
	sub rsp, 8			; Subtract 8 since we will copy 8 registers
	mov rdi, rsp			; Copy the 'new' stack pointer to RDI
	lodsq				; RAX
	stosq
	lodsq				; RCX
	stosq
	lodsq				; RSI
	stosq
	lodsq				; RDI
	stosq
	lodsq				; RIP
	xchg rax, rcx
	stosq				; Callback address
	lodsq				; CS
	stosq
	lodsq				; Flags
	stosq
	lodsq				; RSP
	sub rax, 8
	stosq
	lodsq				; SS
	stosq
	xchg rax, rcx
	stosq				; Original program address
	jmp network_end

network_tx:
	mov byte [os_NetActivity_TX], 1
	bt ax, 7
	jc network_rx_as_well

network_end:
	mov rdi, [os_LocalAPICAddress]	; Acknowledge the IRQ on APIC
	add rdi, 0xB0
	xor eax, eax
	stosd

	pop rax
	pop rcx
	pop rsi
	pop rdi
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; A simple interrupt that just acknowledges an IPI. Useful for getting an AP past a 'hlt' in the code.
align 16
ap_wakeup:
	push rdi
	push rax

	mov rdi, [os_LocalAPICAddress]	; Acknowledge the IPI
	add rdi, 0xB0
	xor eax, eax
	stosd

	pop rax
	pop rdi
	iretq				; Return from the IPI.
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Resets a CPU to execute ap_clear
align 16
ap_reset:
	mov rax, ap_clear		; Set RAX to the address of ap_clear
	mov [rsp], rax			; Overwrite the return address on the CPU's stack
	mov rdi, [os_LocalAPICAddress]	; Acknowledge the IPI
	add rdi, 0xB0
	xor eax, eax
	stosd
	iretq				; Return from the IPI. CPU will execute code at ap_clear
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; CPU Exception Gates
align 16
exception_gate_00:
	push rax
	mov al, 0x00
	jmp exception_gate_main

align 16
exception_gate_01:
	push rax
	mov al, 0x01
	jmp exception_gate_main

align 16
exception_gate_02:
	push rax
	mov al, 0x02
	jmp exception_gate_main

align 16
exception_gate_03:
	push rax
	mov al, 0x03
	jmp exception_gate_main

align 16
exception_gate_04:
	push rax
	mov al, 0x04
	jmp exception_gate_main

align 16
exception_gate_05:
	push rax
	mov al, 0x05
	jmp exception_gate_main

align 16
exception_gate_06:
	push rax
	mov al, 0x06
	jmp exception_gate_main

align 16
exception_gate_07:
	push rax
	mov al, 0x07
	jmp exception_gate_main

align 16
exception_gate_08:
	push rax
	mov al, 0x08
	jmp exception_gate_main

align 16
exception_gate_09:
	push rax
	mov al, 0x09
	jmp exception_gate_main

align 16
exception_gate_10:
	push rax
	mov al, 0x0A
	jmp exception_gate_main

align 16
exception_gate_11:
	push rax
	mov al, 0x0B
	jmp exception_gate_main

align 16
exception_gate_12:
	push rax
	mov al, 0x0C
	jmp exception_gate_main

align 16
exception_gate_13:
	push rax
	mov al, 0x0D
	jmp exception_gate_main

align 16
exception_gate_14:
	push rax
	mov al, 0x0E
	jmp exception_gate_main

align 16
exception_gate_15:
	push rax
	mov al, 0x0F
	jmp exception_gate_main

align 16
exception_gate_16:
	push rax
	mov al, 0x10
	jmp exception_gate_main

align 16
exception_gate_17:
	push rax
	mov al, 0x11
	jmp exception_gate_main

align 16
exception_gate_18:
	push rax
	mov al, 0x12
	jmp exception_gate_main

align 16
exception_gate_19:
	push rax
	mov al, 0x13
	jmp exception_gate_main

align 16
exception_gate_main:
	push rbx
	push rdi
	push rsi
	push rax			; Save RAX since os_smp_get_id clobers it
	call os_print_newline
	mov bl, 0x0F
	mov rsi, int_string00
	call os_output_with_color
	call os_smp_get_id		; Get the local CPU ID and print it
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output_with_color
	mov rsi, int_string01
	call os_output_with_color
	mov rsi, exc_string00
	pop rax
	and rax, 0x00000000000000FF	; Clear out everything in RAX except for AL
	push rax
	mov bl, 32			; Length of each message
	mul bl				; AX = AL x BL
	add rsi, rax			; Use the value in RAX as an offset to get to the right message
	pop rax
	mov bl, 0x0F
	call os_output_with_color
	call os_print_newline
	pop rsi
	pop rdi
	pop rbx
	pop rax
	call os_print_newline
	call os_debug_dump_reg
	mov rsi, rip_string
	call os_output
	push rax
	mov rax, [rsp+0x08] 	; RIP of caller
	call os_debug_dump_rax
	pop rax
	call os_print_newline
	push rax
	push rcx
	push rsi
	mov rsi, stack_string
	call os_output
	mov rsi, rsp
	add rsi, 0x18
	mov rcx, 4
next_stack:
	lodsq
	call os_debug_dump_rax
	mov al, ' '
	call os_output_char
;	call os_print_char
;	call os_print_char
;	call os_print_char
	loop next_stack
	call os_print_newline
	pop rsi
	pop rcx
	pop rax
;	jmp $				; For debugging
	call init_memory_map
	jmp ap_clear			; jump to AP clear code


int_string00 db 'BareMetal OS - CPU ', 0
int_string01 db ' - Interrupt ', 0
; Strings for the error messages
exc_string db 'Unknown Fatal Exception!', 0
exc_string00 db '00 - Divide Error (#DE)        ', 0
exc_string01 db '01 - Debug (#DB)               ', 0
exc_string02 db '02 - NMI Interrupt             ', 0
exc_string03 db '03 - Breakpoint (#BP)          ', 0
exc_string04 db '04 - Overflow (#OF)            ', 0
exc_string05 db '05 - BOUND Range Exceeded (#BR)', 0
exc_string06 db '06 - Invalid Opcode (#UD)      ', 0
exc_string07 db '07 - Device Not Available (#NM)', 0
exc_string08 db '08 - Double Fault (#DF)        ', 0
exc_string09 db '09 - Coprocessor Segment Over  ', 0	; No longer generated on new CPU's
exc_string10 db '10 - Invalid TSS (#TS)         ', 0
exc_string11 db '11 - Segment Not Present (#NP) ', 0
exc_string12 db '12 - Stack Fault (#SS)         ', 0
exc_string13 db '13 - General Protection (#GP)  ', 0
exc_string14 db '14 - Page-Fault (#PF)          ', 0
exc_string15 db '15 - Undefined                 ', 0
exc_string16 db '16 - x87 FPU Error (#MF)       ', 0
exc_string17 db '17 - Alignment Check (#AC)     ', 0
exc_string18 db '18 - Machine-Check (#MC)       ', 0
exc_string19 db '19 - SIMD Floating-Point (#XM) ', 0
rip_string db ' IP:', 0
stack_string db ' ST:', 0



; =============================================================================
; EOF
