; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
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

	mov ax, 0x000A			; Set the cursor to 0,10 (needs to happen before anything is printed to the screen)
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

	; Set up the IRQ handlers (Network IRQ handler is configured in init_net)
	mov rdi, 0x21
	mov rax, keyboard
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
rtc_poll:
	mov al, 0x0A			; Status Register A
	out 0x70, al
	in al, 0x71
	test al, 0x80			; Is there an update in process?
	jne rtc_poll			; If so then keep polling
	mov al, 0x0A			; Status Register A
	out 0x70, al
	mov al, 00101101b		; RTC@32.768KHz (0010), Rate@8Hz (1101)
	out 0x71, al
	mov al, 0x0B			; Status Register B
	out 0x70, al			; Select the address
	in al, 0x71			; Read the current settings
	push rax
	mov al, 0x0B			; Status Register B
	out 0x70, al			; Select the address
	pop rax
	bts ax, 6			; Set Periodic(6)
	out 0x71, al			; Write the new settings
	mov al, 0x0C			; Acknowledge the RTC
	out 0x70, al
	in al, 0x71

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
	mov dx, 0x03C8		; DAC Address Write Mode Register
	out dx, al
	mov dx, 0x03C9		; DAC Data Register
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
	jne nextline		; Set the next 16 colors to the same
	mov eax, 0x14		; Fix for color 6
	mov dx, 0x03c8		; DAC Address Write Mode Register
	out dx, al
	mov dx, 0x03c9		; DAC Data Register
	mov rsi, palette
	add rsi, 18
	lodsb
	out dx, al
	lodsb
	out dx, al
	lodsb
	out dx, al

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	; Grab data from Pure64's infomap
	mov rsi, 0x5008
	lodsd			; Load the BSP ID
	mov ebx, eax		; Save it to EBX
	mov rsi, 0x5012
	lodsw			; Load the number of activated cores
	mov cx, ax		; Save it to CX
	mov rsi, 0x5060
	lodsq
	mov [os_LocalAPICAddress], rax
	lodsq
	mov [os_IOAPICAddress], rax

	mov rsi, 0x5012
	lodsw
	mov [os_NumCores], ax

	mov rsi, 0x5020
	lodsd
	mov [os_MemAmount], eax		; In MiB's

	mov rsi, 0x5040
	lodsq
	mov [os_HPETAddress], rax

	; Build the OS memory table
	call init_memory_map

	; Initialize all AP's to run our reset code. Skip the BSP
	xor rax, rax
	mov rsi, 0x0000000000005100	; Location in memory of the Pure64 CPU data
next_ap:
	cmp cx, 0
	je no_more_aps
	lodsb				; Load the CPU APIC ID
	cmp al, bl
	je skip_ap
	call os_smp_reset		; Reset the CPU
skip_ap:
	sub cx, 1
	jmp next_ap

no_more_aps:

	; Enable specific interrupts
	mov rcx, 1			; Enable Keyboard
	mov rax, 0x21
	call ioapic_entry_write

	mov rcx, 8			; Enable RTC
	mov rax, 0x0100000000000928	; Lowest priority
;	mov rax, 0x28			; Handled by APIC ID 0 (BSP)
	call ioapic_entry_write

	; Set up the HPET (if it exists)
	mov rsi, [os_HPETAddress]
	cmp rsi, 0
	je noHPET

	mov rax, [rsi]			; General Capabilities and ID Register
	shr rax, 32
	mov [os_HPETRate], eax		; Period at which the counter increments in femptoseconds (10^-15 seconds)

	mov rax, [rsi+0x10]		; General Configuration Register
	btc rax, 0			; ENABLE_CNF - Disable the HPET
	mov [rsi+0x10], rax

	xor eax, eax
	mov [rsi+0xF0], rax		; Clear the Main Counter Register

	; Configure and enable Timer 0 (n = 0)
	mov rax, [rsi+0x100]
	bts rax, 1			; Tn_INT_TYPE_CNF - Interrupt Type Level
	bts rax, 3			; Tn_TYPE_CNF - Periodic Enable
	bts rax, 6			; Tn_VAL_SET_CNF
	mov [rsi+0x100], rax

	mov rax, 0xFFFFFFFFFFFFFFFF	; Set the Timer 0 Comparator Register
	mov [rsi+0x108], rax

	mov rax, [rsi+0x10]		; General Configuration Register
	bts rax, 0			; ENABLE_CNF - Enable the HPET
	mov [rsi+0x10], rax

noHPET:

	call os_seed_random		; Seed the RNG

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

; -----------------------------------------------------------------------------
; ioapic_reg_write -- Write to an I/O APIC register
;  IN:	EAX = Value to write
;	ECX = Index of register
; OUT:	Nothing. All registers preserved
ioapic_reg_write:
	push rsi
	mov rsi, [os_IOAPICAddress]
	mov dword [rsi], ecx		; Write index to register selector
	mov dword [rsi + 0x10], eax	; Write data to window register
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; ioapic_entry_write -- Write to an I/O APIC entry in the redirection table
;  IN:	RAX = Data to write to entry
;	ECX = Index of the entry
; OUT:	Nothing. All registers preserved
ioapic_entry_write:
	push rax
	push rcx

	; Calculate index for lower DWORD
	shl rcx, 1				; Quick multiply by 2
	add rcx, 0x10				; IO Redirection tables start at 0x10

	; Write lower DWORD
	call ioapic_reg_write

	; Write higher DWORD
	shr rax, 32
	add rcx, 1
	call ioapic_reg_write

	pop rcx
	pop rax
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
