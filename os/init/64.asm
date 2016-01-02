; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; INIT_64
; =============================================================================

align 16
db 'DEBUG: INIT_64  '
align 16


init_64:
	; Make sure that memory range 0x110000 - 0x200000 is cleared
	mov rdi, os_SystemVariables
	mov rcx, 122880            ; Clear 960 KiB
	xor rax, rax
	rep stosq                  ; Store rax to [rdi], rcx - 1, rdi + 8, if rcx > 0 then do it again

	mov word [os_Screen_Rows], 25
	mov word [os_Screen_Cols], 80
	mov rsi, 0x5080
	lodsd
	cmp eax, 0
	je nographics
	call init_screen
nographics:

	mov word [os_Screen_Cursor_Row], 0
	mov word [os_Screen_Cursor_Col], 0
	call os_screen_clear		; Clear screen and display cursor

	; Display CPU information
	mov ax, [os_Screen_Rows]
	sub ax, 5
	mov word [os_Screen_Cursor_Row], ax
	mov word [os_Screen_Cursor_Col], 0
	mov rsi, cpumsg
	call os_output
	xor eax, eax
	mov rsi, 0x5012
	lodsw
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output
	mov rsi, coresmsg
	call os_output
	mov rsi, 0x5010
	lodsw
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output
	mov rsi, mhzmsg
	call os_output

	xor rdi, rdi 			; Create the 64-bit IDT (at linear address 0x0000000000000000) as defined by Pure64

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

	; Set color palette
	xor eax, eax
	mov dx, 0x03C8			; DAC Address Write Mode Register
	out dx, al
	mov dx, 0x03C9			; DAC Data Register
	mov rbx, 16			; 16 lines
nextline:
	mov rcx, 16			; 16 colors
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
	jne nextline			; Set the next 16 colors to the same
	mov eax, 0x14			; Fix for color 6
	mov dx, 0x03c8			; DAC Address Write Mode Register
	out dx, al
	mov dx, 0x03c9			; DAC Data Register
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
	lodsd				; Load the BSP ID
	mov ebx, eax			; Save it to EBX
	mov rsi, 0x5012
	lodsw				; Load the number of activated cores
	mov cx, ax			; Save it to CX
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

	; Display memory information
	mov rsi, memmsg
	call os_output
	mov eax, [os_MemAmount]		; In MiB's
	mov rdi, os_temp_string
	mov rsi, rdi
	call os_int_to_string
	call os_output
	mov rsi, mibmsg
	call os_output

	; Enable specific interrupts
	mov al, 0x01			; Keyboard IRQ
	call os_pic_mask_clear
	mov al, 0x02			; Cascade IRQ
	call os_pic_mask_clear
	mov al, 0x08			; RTC IRQ
	call os_pic_mask_clear

	ret

; create_gate
; rax = address of handler
; rdi = gate # to configure
create_gate:
	push rdi
	push rax

	shl rdi, 4			; quickly multiply rdi by 16
	stosw				; store the low word (15..0)
	shr rax, 16
	add rdi, 4			; skip the gate marker
	stosw				; store the high word (31..16)
	shr rax, 16
	stosd				; store the high dword (63..32)

	pop rax
	pop rdi
	ret


init_memory_map:			; Build the OS memory table
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
;	stosb				; As well as the second 2 MiB (by loaded application)
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
	mov rsi, memory_message
	call os_output
system_failure_hang:
	hlt
	jmp system_failure_hang
	ret


; -----------------------------------------------------------------------------
init_screen:
	mov rsi, 0x5080
	xor eax, eax
	lodsd				; VIDEO_BASE
	mov [os_VideoBase], rax
	xor eax, eax
	xor ecx, ecx

	lodsw				; VIDEO_X
	mov [os_VideoX], ax		; ex: 1024

	xor edx, edx
	mov cl, [font_width]
	div cx
	mov [os_Screen_Cols], ax

	lodsw				; VIDEO_Y
	mov [os_VideoY], ax		; ex: 768

	xor edx, edx
	mov cl, [font_height]
	div cx
	mov [os_Screen_Rows], ax

	lodsb				; VIDEO_DEPTH
	mov [os_VideoDepth], al

	xor eax, eax
	xor ecx, ecx
	mov ax, [os_VideoX]
	mov cx, [os_VideoY]
	mul ecx
	mov [os_Screen_Pixels], eax
	xor ecx, ecx
	mov cl, [os_VideoDepth]
	shr cl, 3
	mul ecx
	mov [os_Screen_Bytes], eax

	xor eax, eax
	xor ecx, ecx
	mov ax, [os_VideoX]
	mov cl, [font_height]
	mul cx
	mov cl, [os_VideoDepth]
	shr cl, 3
	mul ecx
	mov dword [os_Screen_Row_2], eax

	mov eax, 0x00FFFFFF
	mov [os_Font_Color], eax

	mov al, 1
	mov [os_VideoEnabled], al

	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
