; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2015 Return Infinity -- see LICENSE.TXT
;
; The BareMetal OS kernel. Assemble with NASM
; =============================================================================


USE64
ORG 0x0000000000100000

%DEFINE BAREMETALOS_VER 'v0.6.1 (August 19, 2013)', 13, 'Copyright (C) 2008-2015 Return Infinity', 13, 0
%DEFINE BAREMETALOS_API_VER 2

kernel_start:
	jmp start			; Skip over the function call index
	nop
	db 'BAREMETAL'

	align 16
	dq os_output			; 0x0010
	dq os_output_chars		; 0x0018
	dq os_input			; 0x0020
	dq os_input_key			; 0x0028
	dq os_smp_enqueue		; 0x0030
	dq os_smp_dequeue		; 0x0038
	dq os_smp_run			; 0x0040
	dq os_smp_wait			; 0x0048
	dq os_mem_allocate		; 0x0050
	dq os_mem_release		; 0x0058
	dq os_ethernet_tx		; 0x0060
	dq os_ethernet_rx		; 0x0068
	dq os_file_open			; 0x0070
	dq os_file_close		; 0x0078
	dq os_file_read			; 0x0080
	dq os_file_write		; 0x0088
	dq os_file_seek			; 0x0090
	dq os_file_query		; 0x0098
	dq os_file_create		; 0x00A0
	dq os_file_delete		; 0x00A8
	dq os_system_config		; 0x00B0
	dq os_system_misc		; 0x00B8
	align 16

start:
	call init_64			; After this point we are in a working 64-bit environment
	call init_pci			; Initialize the PCI bus
	call init_hdd			; Initialize the disk
	call init_net			; Initialize the network

	mov ax, [os_Screen_Rows]	; Display the "ready" message and reset cursor to bottom left
	push ax
	sub ax, 3
	mov word [os_Screen_Cursor_Row], ax
	mov word [os_Screen_Cursor_Col], 0
	mov rsi, readymsg
	call os_output
	pop ax
	sub ax, 1
	mov word [os_Screen_Cursor_Row], ax
	mov word [os_Screen_Cursor_Col], 0

	mov rax, os_command_line	; Start the CLI
	call os_smp_enqueue

	; Fall through to ap_clear as align fills the space with No-Ops
	; At this point the BSP is just like one of the AP's


align 16

ap_clear:				; All cores start here on first start-up and after an exception

	cli				; Disable interrupts on this core

	; Get local ID of the core
	mov rsi, [os_LocalAPICAddress]	; We can't use os_smp_get_id as no configured stack yet
	xor eax, eax			; Clear Task Priority (bits 7:4) and Task Priority Sub-Class (bits 3:0)
	mov dword [rsi+0x80], eax	; APIC Task Priority Register (TPR)
	mov eax, dword [rsi+0x20]	; APIC ID in upper 8 bits
	shr rax, 24			; Shift to the right and AL now holds the CPU's APIC ID

	; Calculate offset into CPU status table
	mov rdi, cpustatus
	add rdi, rax			; RDI points to this cores status byte (we will clear it later)

	; Set up the stack
	shl rax, 21			; Shift left 21 bits for a 2 MiB stack
	add rax, [os_StackBase]		; The stack decrements when you "push", start at 2 MiB in
	sub rax, 8
	mov rsp, rax

	; Set the CPU status to "Present" and "Ready"
	mov al, 00000001b		; Bit 0 set for "Present", Bit 1 clear for "Ready"
	stosb				; Set status to Ready for this CPU

	sti				; Enable interrupts on this core

	; Clear registers. Gives us a clean slate to work with
	xor rax, rax			; aka r0
	xor rcx, rcx			; aka r1
	xor rdx, rdx			; aka r2
	xor rbx, rbx			; aka r3
	xor rbp, rbp			; aka r5, We skip RSP (aka r4) as it was previously set
	xor rsi, rsi			; aka r6
	xor rdi, rdi			; aka r7
	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15

ap_spin:				; Spin until there is a workload in the queue
	cmp word [os_QueueLen], 0	; Check the length of the queue
	je ap_halt			; If the queue was empty then jump to the HLT
	call os_smp_dequeue		; Try to pull a workload out of the queue
	jnc ap_process			; Carry clear if successful, jump to ap_process

ap_halt:				; Halt until a wakeup call is received
	hlt				; If carry was set we fall through to the HLT
	jmp ap_spin			; Try again

ap_process:				; Set the status byte to "Busy" and run the code
	push rdi			; Push RDI since it is used temporarily
	push rax			; Push RAX since os_smp_get_id uses it
	mov rdi, cpustatus
	call os_smp_get_id		; Set RAX to the APIC ID
	add rdi, rax
	mov al, 00000011b		; Bit 0 set for "Present", Bit 1 set for "Busy"
	stosb
	pop rax				; Pop RAX (holds the workload code address)
	pop rdi				; Pop RDI (holds the variable/variable address)

	call rax			; Run the code

	jmp ap_clear			; Reset the stack, clear the registers, and wait for something else to work on


; Includes
%include "init.asm"
%include "syscalls.asm"
%include "drivers.asm"
%include "interrupt.asm"
%include "cli.asm"
%include "font.asm"
%include "sysvar.asm"			; Include this last to keep the read/write variables away from the code

times 16384-($-$$) db 0			; Set the compiled kernel binary to at least this size in bytes

; =============================================================================
; EOF
