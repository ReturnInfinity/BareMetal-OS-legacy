; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; INIT_64
; =============================================================================

align 16
db 'DEBUG: INIT_64  '
align 16


init_64:
	; Make sure that memory range 0x110000 - 0x200000 is cleared
	mov rdi, os_SystemVariables
	xor rcx, rcx
	xor rax, rax
clearmem:
	stosq
	add rcx, 1
	cmp rcx, 122880	; Clear 960 KiB
	jne clearmem

	mov ax, 0x000A			; Set the cursor to 0,10 and clear the screen (needs to happen before anything is printed to the screen)
	call os_move_cursor

	xor rdi, rdi 			; create the 64-bit IDT (at linear address 0x0000000000000000) as defined by Pure64

	; Create exception gate stubs (Pure64 has already set the correct gate markers)
	mov rcx, 32
	mov rax, exception_gate
make_exception_gate_stubs:
	call create_gate
	add rdi, 1
	sub rcx, 1
	jnz make_exception_gate_stubs

	; Create interrupt gate stubs (Pure64 has already set the correct gate markers)
	mov rcx, 256-32
	mov rax, interrupt_gate
make_interrupt_gate_stubs:
	call create_gate
	add rdi, 1
	sub rcx, 1
	jnz make_interrupt_gate_stubs

	; Set up the exception gates for all of the CPU exceptions
	mov rcx, 20
	xor rdi, rdi
	mov rax, exception_gate_00
make_exception_gates:
	call create_gate
	add rdi, 1
	add rax, 16			; The exception gates are aligned at 16 bytes
	sub rcx, 1
	jnz make_exception_gates

	; Set up the IRQ handlers
	mov rdi, 0x21
	mov rax, keyboard
	call create_gate
	mov rdi, 0x22
	mov rax, cascade
	call create_gate
	mov rdi, 0x28
	mov rax, rtc
	call create_gate
	mov rdi, 0x80
	mov rax, ap_wakeup
	call create_gate
	mov rdi, 0x81
	mov rax, ap_reset
	call create_gate

	; Set up RTC
	; Rate defines how often the RTC interrupt is triggered
	; Rate is a 4-bit value from 1 to 15. 1 = 32768Hz, 6 = 1024Hz, 15 = 2Hz
	; RTC value must stay at 32.768KHz or the computer will not keep the correct time
	; http://wiki.osdev.org/RTC
	mov al, 0x0a
	out 0x70, al
	mov al, 00101101b		; RTC@32.768KHz (0010), Rate@8Hz (1101)
	out 0x71, al
	mov al, 0x0b
	out 0x70, al
	mov al, 01000010b		; Periodic(6), 24H clock(2)
	out 0x71, al
	mov al, 0x0C			; Acknowledge the RTC
	out 0x70, al
	in al, 0x71

	mov al, 0x0B			; Set RTC to binary mode
	out 0x70, al
	in al, 0x71
	bts ax, 2
	mov bl, al
	mov al, 0x0B
	out 0x70, al
	mov al, bl
	out 0x71, al

	; Disable blink
	mov dx, 0x3DA
	in al, dx
	mov dx, 0x3C0
	mov al, 0x30
	out dx, al
	add dx, 1
	in al, dx
	and al, 0xF7
	sub dx, 1
	out dx, al

	; Set color palette
	xor eax, eax
	mov dx, 0x03c8
	out dx, al
	mov dx, 0x03c9
	mov rbx, 16		; 16 lines
nextline:
	mov rcx, 16		; 16 colors
	mov rsi, palette
nexttritone:
	lodsb
	out dx, al
	lodsb
	out dx, al
	lodsb
	out dx, al
	dec rcx
	cmp rcx, 0
	jne nexttritone
	dec rbx
	cmp rbx, 0
	jne nextline

	; Grab data from Pure64's infomap
	mov rsi, 0x5000
	lodsq
	mov [os_LocalAPICAddress], rax
	lodsq
	mov [os_IOAPICAddress], rax

	mov rsi, 0x5012
	lodsw
	mov [os_NumCores], ax

	mov rsi, 0x5020
	lodsw
	mov [os_MemAmount], ax		; In MiB's

	; Build the OS memory table
	call init_memory_map

	; Initialize all AP's to run our reset code. Skip the BSP
	xor rax, rax
	xor rcx, rcx
	mov rsi, 0x0000000000005700	; Location in memory of the Pure64 CPU data

next_ap:
	cmp rsi, 0x0000000000005800	; Enable up to 256 CPU Cores
	je no_more_aps
	lodsb				; Load the CPU parameters
	bt rax, 0			; Check if the CPU is enabled
	jnc skip_ap
	bt rax, 1			; Test to see if this is the BSP (Do not init!)
	jc skip_ap
	mov rax, rcx
	call os_smp_reset		; Reset the CPU
skip_ap:
	add rcx, 1
	jmp next_ap

no_more_aps:

	; Enable specific interrupts
	in al, 0x21
	mov al, 11111001b		; Enable Cascade, Keyboard
	out 0x21, al
	in al, 0xA1
	mov al, 11111110b		; Enable RTC
	out 0xA1, al

	call os_seed_random		; Seed the RNG

	; Reset keyboard and empty the buffer
	mov al, 0x20			; Command to read byte of keyboard controller RAM
	out 0x64, al			; Send command
	in al, 0x60			; Grab the keyboard controller command byte
	or al, 00000001b		; Enable interrupts
	and al, 11101111b		; Enable keyboard
	push rax
	mov al, 0x60			; Command to write byte of keyboard controller RAM
	out 0x64, al			; Send command
	pop rax
	out 0x60, al			; Send new keyboard controller command byte

ret

; create_gate
; rax = address of handler
; rdi = gate # to configure
create_gate:
	push rdi
	push rax
	
	shl rdi, 4	; quickly multiply rdi by 16
	stosw		; store the low word (15..0)
	shr rax, 16
	add rdi, 4	; skip the gate marker
	stosw		; store the high word (31..16)
	shr rax, 16
	stosd		; store the high dword (63..32)

	pop rax
	pop rdi
ret


init_memory_map:	; Build the OS memory table
	push rax
	push rcx
	push rdi 

	; Build a fresh memory map for the system
	mov rdi, os_MemoryMap
	push rdi
	xor rcx, rcx
	mov cx, [os_MemAmount]
	shr cx, 1			; Divide actual memory by 2
	mov al, 1
	rep stosb
	pop rdi
	mov al, 2
	stosb				; Mark the first 2 MiB as in use (by Kernel and system buffers)
	stosb				; As well as the second 2 MiB (by loaded application)
	; The CLI should take care of the Application memory

	; Allocate memory for CPU stacks (2 MiB's for each core)
	xor rcx, rcx
	mov cx, [os_NumCores]		; Get the amount of cores in the system
	call os_mem_allocate		; Allocate a page for each core
	cmp rcx, 0			; os_mem_allocate returns 0 on failure
	je system_failure
	add rax, 2097152
	mov [os_StackBase], rax		; Store the Stack base address

	pop rdi
	pop rcx
	pop rax
ret


system_failure:
	mov ax, 0x0016
	call os_move_cursor
	mov rsi, memory_message
	mov bl, 0xF0
	call os_print_string_with_color
system_failure_hang:
	hlt
	jmp system_failure_hang
ret

; =============================================================================
; EOF
