; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
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
	mov rdi, os_screen
	push rdi
	mov rcx, 80
	rep stosw
	pop rdi

	; Display CPU status
	mov al, '['
	stosb
	add rdi, 1			; Skip the attribute byte
	mov rax, 0x8F3A8F758F708F63	; ':upc'
	stosq
	add rdi, 2			; Skip to the next char

	xor ecx, ecx
	mov rsi, cpustatus
system_status_cpu_next:
	cmp cx, 256
	je system_status_cpu_done
	add rcx, 1
	lodsb
	bt ax, 0			; Check to see if the Core is Present
	jnc system_status_cpu_next	; If not then check the next
	ror ax, 8			; Exchange AL and AH
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	rol ax, 8			; Exchange AL and AH
	bt ax, 1			; Check to see if the Core is Ready or Busy
	jc system_status_cpu_busy	; Jump if it is Busy.. otherwise fall through for Idle
	mov al, 0x80			; Black on Dark Gray (Idle Core)
	jmp system_status_cpu_color

system_status_cpu_busy:
	mov rax, [os_ClockCounter]
	bt rax, 0			; Check bit 0. Store bit 0 in CF
	jc system_status_cpu_flash_hi
	mov al, 0x87			; Light Gray on Dark Gray (Active Core Low)
	jmp system_status_cpu_color
system_status_cpu_flash_hi:
	mov al, 0x8F			; White on Dark Gray (Active Core High)
system_status_cpu_color:
	stosb				; Store the color (attribute) byte
	jmp system_status_cpu_next	; Check the next Core

system_status_cpu_done:
	mov al, ']'
	stosb
	add rdi, 1

	; Display memory status
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1			; Skip the attribute byte
	mov rax, 0x8F3A8F6D8F658F6D	; ':mem'
	stosq
	add rdi, 2			; Skip to the next char

	call os_mem_get_free		; Store number of free 2 MiB pages in RCX
	xor rax, rax
	mov ax, word [os_MemAmount]
	shr ax, 1			; Divide actual memory by 2 (RAX now holds total pages)
	push rax
	sub rax, rcx			; RAX holds inuse pages (ex 6)
	pop rcx				; RCX holds total pages (ex 512)
	shr rcx, 3			; Quickly divide RCX by 8, RCX now holds pages/block (ex 64)
	xor rdx, rdx
	div rcx				; Divide inuse pages by pages/block
	mov rcx, rax
	mov ax, 8
	cmp cx, 0
	jne notzero
	add cx, 1
notzero:
	sub ax, cx
	push rax

system_status_mem_used:
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x8F			; Light Gray on Blue
	stosb				; Put the block character on the screen
	sub rcx, 1
	jrcxz system_status_mem_used_finish
	jmp system_status_mem_used

system_status_mem_used_finish:

	pop rcx
system_status_mem_free:
	jrcxz system_status_mem_finish
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x80			; Light Gray on Blue
	stosb				; Put the block character on the screen
	sub rcx, 1
	jrcxz system_status_mem_finish
	jmp system_status_mem_free

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
	mov rax, 0x8F3A8F748F658F6E	; ':ten'
	stosq
	add rdi, 2
	mov al, 'T'
	stosb
	add rdi, 1
	mov al, 0xFE			; Ascii block character
	stosb				; Put the block character on the screen
	mov al, 0x80			; Black on Dark Gray (No Activity)
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
	mov al, 0x80			; Black on Dark Gray (No Activity)
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

	; Display the RTC pulse
	add rdi, 4
	mov al, '['
	stosb
	add rdi, 1
	mov rax, 0x8F3A8F638F748F72	; ':ctr'
	stosq
	add rdi, 2
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
; os_seed_random -- Seed the RNG based on the current date and time
; IN:	Nothing
; OUT:	All registers preserved
os_seed_random:
	push rdx
	push rbx
	push rax

	xor rbx, rbx
	mov al, 0x09		; year
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 8
	mov al, 0x08		; month
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 8
	mov al, 0x07		; day
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 8
	mov al, 0x04		; hour
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 8
	mov al, 0x02		; minute
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 8
	mov al, 0x00		; second
	out 0x70, al
	in al, 0x71
	mov bl, al
	shl rbx, 16
	rdtsc			; Read the Time Stamp Counter in EDX:EAX
	mov bx, ax		; Only use the last 2 bytes

	mov [os_RandomSeed], rbx	; Seed will be something like 0x091229164435F30A

	pop rax
	pop rbx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_random -- Return a random integer
; IN:	Nothing
; OUT:	RAX = Random number
;	All other registers preserved
os_get_random:
	push rdx
	push rbx

	mov rax, [os_RandomSeed]
	mov rdx, 0x23D8AD1401DE7383	; The magic number (random.org)
	mul rdx				; RDX:RAX = RAX * RDX
	mov [os_RandomSeed], rax

	pop rbx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_random_integer -- Return a random integer between Low and High (incl)
; IN:	RAX = Low integer
;	RBX = High integer
; OUT:	RCX = Random integer
os_get_random_integer:
	push rdx
	push rbx
	push rax

	sub rbx, rax		; We want to look for a number between 0 and (High-Low)
	call os_get_random
	mov rdx, rbx
	add rdx, 1
	mul rdx
	mov rcx, rdx

	pop rax
	pop rbx
	pop rdx
	add rcx, rax		; Add the low offset back
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
; os_get_timecounter -- Get the current RTC clock couter value
; IN:	Nothing
; OUT:	RAX = Time in eights of a second since clock started
; This function depends on the RTC (IRQ 8) so interrupts must be enabled.
os_get_timecounter:
	mov rax, [os_ClockCounter]	; Grab the timer counter value. It increments 8 times a second
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_hide_statusbar -- Hide the system status bar
; IN:
os_hide_statusbar:
	mov byte [os_show_sysstatus], 0
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_show_statusbar -- Show the system status bar
; IN:
os_show_statusbar:
	mov byte [os_show_sysstatus], 1
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
