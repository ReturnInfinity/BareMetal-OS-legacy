; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; Debug functions
; =============================================================================

align 16
db 'DEBUG: DEBUG    '
align 16


; -----------------------------------------------------------------------------
; os_debug_dump_reg -- Dump the values on the registers to the screen (For debug purposes)
;  IN:	Nothing
; OUT:	Nothing, all registers preserved
os_debug_dump_reg:
	pushfq						; Push the registers used by this function
	push rsi
	push rbx
	push rax

	pushfq						; Push the flags to the stack
	push r15					; Push all of the registers to the stack
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rsp
	push rbp
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax

	mov byte [os_debug_dump_reg_stage], 0x00	; Reset the stage to 0 since we are starting
os_debug_dump_reg_next:
	mov rsi, os_debug_dump_reg_string00
	xor rax, rax
	xor rbx, rbx
	mov al, [os_debug_dump_reg_stage]
	mov bl, 5					; Each string is 5 bytes
	mul bl						; AX = BL x AL
	add rsi, rax					; Add the offset to get to the correct string
	call os_print_string				; Print the register name
	pop rax						; Pop the register from the stack
	call os_debug_dump_rax				; Print the hex string value of RAX
	inc byte [os_debug_dump_reg_stage]
	cmp byte [os_debug_dump_reg_stage], 0x11	; Check to see if all 16 registers as well as the flags are displayed
	jne os_debug_dump_reg_next

	mov rbx, rax					; Store the flags in RBX

	mov rsi, os_debug_dump_flag_string0		; Print the Carry flag
	call os_print_string
	bt rbx, 0
	jc carry_1
carry_0:
	mov al, '0'
	jmp print_carry
carry_1:
	mov al, '1'
print_carry:
	call os_print_char

	mov rsi, os_debug_dump_flag_string1		; Print the Zero flag
	call os_print_string
	bt rbx, 6
	jc zero_1
zero_0:
	mov al, '0'
	jmp print_zero
zero_1:
	mov al, '1'
print_zero:
	call os_print_char	

	mov rsi, os_debug_dump_flag_string2		; Print the Sign flag
	call os_print_string
	bt rbx, 7
	jc sign_1
sign_0:
	mov al, '0'
	jmp print_sign
sign_1:
	mov al, '1'
print_sign:
	call os_print_char	

	mov rsi, os_debug_dump_flag_string3		; Print the Direction flag
	call os_print_string
	bt rbx, 10
	jc dir_1
dir_0:
	mov al, '0'
	jmp print_dir
dir_1:
	mov al, '1'
print_dir:
	call os_print_char	

	mov rsi, os_debug_dump_flag_string4		; Print the Overflow flag
	call os_print_string
	bt rbx, 11
	jc over_1
over_0:
	mov al, '0'
	jmp print_over
over_1:
	mov al, '1'
print_over:
	call os_print_char	

	
os_debug_dump_reg_done:
	call os_print_newline
	pop rax
	pop rbx
	pop rsi
	popfq
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_debug_dump_mem -- Dump some memory content to the screen
;  IN:	RSI = Start of memory address to dump
;	RCX = number of bytes to dump
; OUT:	Nothing, all registers preserved
os_debug_dump_mem:
	push rsi
	push rcx		; counter
	push rdx		; total number of bytes to display
	push rbx		; color attribute
	push rax
	mov bl, 0x07		; Default of light grey on black

	cmp rcx, 0
	je os_debug_dump_mem_done
	mov rdx, rcx		; Save the total number of bytes to display
	add rdx, 15
	and rdx, 0xFFFFFFF0
	and rsi, 0xFFFFFFF0

os_debug_dump_mem_print_address:
	mov rax, rsi
	call os_debug_dump_rax
	push rsi
	mov rsi, divider
	call os_print_string
	pop rsi
	xor rcx, rcx		; Clear the counter

os_debug_dump_mem_next_byte_hex:
	lodsb
	call os_print_char_hex_with_color
	xor bl, 10000000b	; Toggle between light grey on black and light grey on dark grey
	add rcx, 1
	cmp rcx, 16
	jne os_debug_dump_mem_next_byte_hex

	push rsi
	mov rsi, divider
	call os_print_string
	pop rsi
	sub rsi, 0x10
	xor rcx, rcx		; Clear the counter

os_debug_dump_mem_next_byte_ascii:
	lodsb
	call os_print_char_with_color
	xor bl, 10000000b	; Toggle between light grey on black and light grey on dark grey
	add rcx, 1
	cmp rcx, 16
	jne os_debug_dump_mem_next_byte_ascii
	
	sub rdx, 16
	cmp rdx, 0
	je os_debug_dump_mem_done
	call os_print_newline
	jmp os_debug_dump_mem_print_address

os_debug_dump_mem_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret

divider: db ' | ', 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_debug_dump_(rax|eax|ax|al) -- Dump content of RAX, EAX, AX, or AL to the screen in hex format
;  IN:	RAX = content to dump
; OUT:	Nothing, all registers preserved
os_debug_dump_rax:
	ror rax, 56
	call os_print_char_hex
	rol rax, 8
	call os_print_char_hex
	rol rax, 8
	call os_print_char_hex
	rol rax, 8
	call os_print_char_hex
	rol rax, 32
os_debug_dump_eax:
	ror rax, 24
	call os_print_char_hex
	rol rax, 8
	call os_print_char_hex
	rol rax, 16
os_debug_dump_ax:
	ror rax, 8
	call os_print_char_hex
	rol rax, 8
os_debug_dump_al:
	call os_print_char_hex
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_debug_get_ip -- Dump content of RIP into RAX
;  IN:	Nothing
; OUT:	RAX = RIP
os_debug_get_ip:
	mov rax, qword [rsp]
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_debug_dump_MAC -- Dump MAC address to screen
;  IN:	Nothing
; OUT:	Nothing, all registers preserved
os_debug_dump_MAC:
	push rsi
	push rcx
	push rax

	mov ecx, 6
	mov rsi, os_NetMAC
os_debug_dump_MAC_display:
	lodsb
	call os_debug_dump_al
	sub ecx, 1
	test ecx, ecx
	jnz os_debug_dump_MAC_display

	pop rax
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
