; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
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
	push rbx
	push rax
	pushfq

	xor eax, eax

	in al, 0x60			; Get the scan code from the keyboard
	cmp al, 0x2A			; Left Shift Make
	je keyboard_shift
	cmp al, 0x36			; Right Shift Make
	je keyboard_shift
	cmp al, 0xAA			; Left Shift Break
	je keyboard_noshift
	cmp al, 0xB6			; Right Shift Break
	je keyboard_noshift
	test al, 0x80			; Test for 'Make' code
	jnz keyboard_done

keyboard_press:
	cmp byte [key_shift], 0x00
	je keyboard_lowercase

keyboard_uppercase:
	mov rbx, keylayoutupper
	jmp keyboard_processkey

keyboard_lowercase:	
	mov rbx, keylayoutlower

keyboard_processkey:			; Convert the scan code
	add rbx, rax
	mov bl, [rbx]
	mov [key], bl
	jmp keyboard_done

keyboard_shift:
	mov byte [key_shift], 0x01
	jmp keyboard_done

keyboard_noshift:
	mov byte [key_shift], 0x00
	jmp keyboard_done

keyboard_done:
	mov al, 0x20			; Acknowledge the IRQ
	out 0x20, al
	call os_smp_wakeup_all		; A terrible hack

	popfq
	pop rax
	pop rbx
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Cascade interrupt. IRQ 0x02, INT 0x22
align 16
cascade:
	push rax

	mov al, 0x20			; Acknowledge the IRQ
	out 0x20, al

	pop rax
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Real-time clock interrupt. IRQ 0x08, INT 0x28
; Currently this IRQ runs 8 times per second (As defined in init_64.asm)
align 16
rtc:
	push rax
	pushfq

	add qword [os_ClockCounter], 1	; 64-bit counter started at boot-up

	cmp qword [os_ClockCallback], 0	; Is it valid?
	je rtc_end			; If not then bail out.

	; We could do a 'call [os_ClockCallback]' here but that would not be ideal.
	; A defective callback would hang the system if it never returned back to the
	; interrupt handler. Instead, we modify the stack so that the callback is
	; executed after the interrupt handler has finished. Once the callback has
	; finished, the execution flow will pick up back in the program.
	push rdi
	push rsi
	push rcx
	mov rcx, clock_callback		; RCX stores the callback function address
	mov rsi, rsp			; Copy the current stack pointer to RSI
	sub rsp, 8			; Subtract 8 since we add a 64-bit value to the stack
	mov rdi, rsp			; Copy the 'new' stack pointer to RDI
	movsq				; RCX
	movsq				; RSI
	movsq				; RDI
	movsq				; Flags
	movsq				; RAX
	lodsq				; RIP
	xchg rax, rcx
	stosq				; Callback address
	movsq				; CS
	movsq				; Flags
	lodsq				; RSP
	sub rax, 8
	stosq
	movsq				; SS
	mov [rax], rcx			; Original RIP
	pop rcx
	pop rsi
	pop rdi

rtc_end:
	mov al, 0x0C			; Select RTC register C
	out 0x70, al			; Port 0x70 is the RTC index, and 0x71 is the RTC data
	in al, 0x71			; Read the value in register C

	mov al, 0x20			; Acknowledge the IRQ
	out 0xA0, al
	out 0x20, al

	popfq
	pop rax
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
	pushfq

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
	mov rcx, network_callback	; RCX stores the callback function address
	mov rsi, rsp			; Copy the current stack pointer to RSI
	sub rsp, 8			; Subtract 8 since we add a 64-bit value to the stack
	mov rdi, rsp			; Copy the 'new' stack pointer to RDI
	movsq				; Flags
	movsq				; RAX
	movsq				; RCX
	movsq				; RSI
	movsq				; RDI
	lodsq				; RIP
	xchg rax, rcx
	stosq				; Callback address
	movsq				; CS
	movsq				; Flags
	lodsq				; RSP
	sub rax, 8
	stosq
	movsq				; SS
	mov [rax], rcx			; Original RIP
	jmp network_end

network_tx:
	mov byte [os_NetActivity_TX], 1
	bt ax, 7
	jc network_rx_as_well

network_end:
	mov al, 0x20			; Acknowledge the IRQ on the PIC(s)
	cmp byte [os_NetIRQ], 8
	jl network_ack_only_low		; If the network IRQ is less than 8 then the other PIC does not need to be ack'ed
	out 0xA0, al
network_ack_only_low:
	out 0x20, al

	popfq
	pop rax
	pop rcx
	pop rsi
	pop rdi
	iretq
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Network interrupt.
align 16
network_callback:
	pushfq
	call [os_NetworkCallback]
	popfq
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; Network interrupt.
align 16
clock_callback:
	pushfq
	call [os_ClockCallback]
	popfq
	ret
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
	mov qword [os_ClockCallback], 0		; Reset the clock callback
	mov qword [os_NetworkCallback], 0	; Reset the network callback
	push rbx
	push rdi
	push rsi
	push rax			; Save RAX since os_smp_get_id clobbers it
	call os_print_newline
	mov rsi, int_string00
	call os_output
	call os_smp_get_id		; Get the local CPU ID and print it
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output
	mov rsi, int_string01
	call os_output
	mov rsi, exc_string00
	pop rax
	and rax, 0x00000000000000FF	; Clear out everything in RAX except for AL
	push rax
	mov bl, 32			; Length of each message
	mul bl				; AX = AL x BL
	add rsi, rax			; Use the value in RAX as an offset to get to the right message
	pop rax
	mov bl, 0x0F
	call os_output
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
	mov rax, [rsp+0x08] 		; RIP of caller
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
