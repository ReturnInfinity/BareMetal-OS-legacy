; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; The BareMetal OS kernel. Assemble with NASM
; =============================================================================


USE64
ORG 0x0000000000100000

%DEFINE BAREMETALOS_VER 'v0.6.0-pre (XXXXXXX XX, 2013)', 13, 'Copyright (C) 2008-2013 Return Infinity', 13, 0
%DEFINE BAREMETALOS_API_VER 2

kernel_start:
	jmp start		; Skip over the function call index
	nop
	db 'BAREMETAL'

	align 16		; 0x0010
	jmp os_output		; Jump to function
	align 8
	dq os_output		; Memory address of function

	align 8			; 0x0020
	jmp os_output_chars
	align 8
	dq os_output_chars

	align 8			; 0x0030
	jmp os_input
	align 8
	dq os_input

	align 8			; 0x0040
	jmp os_input_key
	align 8
	dq os_input_key

	align 8			; 0x0050
	jmp os_smp_enqueue
	align 8
	dq os_smp_enqueue

	align 8			; 0x0060
	jmp os_smp_dequeue
	align 8
	dq os_smp_dequeue

	align 8			; 0x0070
	jmp os_smp_run
	align 8
	dq os_smp_run

	align 8			; 0x0080
	jmp os_smp_wait
	align 8
	dq os_smp_wait

	align 8			; 0x0090
	jmp os_mem_allocate
	align 8
	dq os_mem_allocate

	align 8			; 0x00A0
	jmp os_mem_release
	align 8
	dq os_mem_release

	align 8			; 0x00B0
	jmp os_ethernet_tx
	align 8
	dq os_ethernet_tx

	align 8			; 0x00C0
	jmp os_ethernet_rx
	align 8
	dq os_ethernet_rx

	align 8			; 0x00D0
	jmp os_file_read
	align 8
	dq os_file_read

	align 8			; 0x00E0
	jmp os_file_write
	align 8
	dq os_file_write

	align 8			; 0x00F0
	jmp os_file_create
	align 8
	dq os_file_create

	align 8			; 0x0100
	jmp os_file_delete
	align 8
	dq os_file_delete

	align 8			; 0x0110
	jmp os_file_query
	align 8
	dq os_file_query

	align 8			; 0x0120
	jmp os_file_list
	align 8
	dq os_file_list

	align 8			; 0x0130
	jmp os_system_config
	align 8
	dq os_system_config


align 16

start:
	call init_64			; After this point we are in a working 64-bit enviroment

	call os_screen_clear		; Clear screen and display cursor

	call init_pci

	call init_hdd			; Initialize the disk

	call init_net			; Initialize the network

	mov ax, 0x0016			; Print the "ready" message
	call os_move_cursor
	mov rsi, readymsg
	call os_output

	mov ax, 0x0018			; Set the hardware cursor to the bottom left-hand corner
	call os_move_cursor

; DEV TESTING
;	mov rbx, hellofunc
;	mov [os_NetworkCallback], rbx

;	mov rax, 0
;	mov rcx, 4192
;	mov rdx, 0
;	mov rdi, 0x200000
;	call readsectors
;	mov rsi, 0x200000
;	mov rcx, 512
;	call os_debug_dump_mem
; DEV TESTING

	; Fall through to ap_clear as align fills the space with No-Ops
	; At this point the BSP is just like one of the AP's


align 16

ap_clear:				; All cores start here on first startup and after an exception

	cli				; Disable interrupts on this core

	; Get local ID of the core
	mov rsi, [os_LocalAPICAddress]
	xor eax, eax			; Clear Task Priority (bits 7:4) and Task Priority Sub-Class (bits 3:0)
	mov dword [rsi+0x80], eax	; APIC Task Priority Register (TPR)
	mov eax, dword [rsi+0x20]	; APIC ID
	shr rax, 24			; Shift to the right and AL now holds the CPU's APIC ID

	; Calculate offset into CPU status table
	mov rdi, cpustatus
	add rdi, rax			; RDI points to this cores status byte (we will clear it later)

	; Set up the stack
	shl rax, 21			; Shift left 21 bits for a 2 MiB stack
	add rax, [os_StackBase]		; The stack decrements when you "push", start at 2 MiB in
	mov rsp, rax

	; Set the CPU status to "Present" and "Ready"
	mov al, 00000001b		; Bit 0 set for "Present", Bit 1 clear for "Ready"
	stosb				; Set status to Ready for this CPU

	sti				; Re-enable interrupts on this core

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
	cli
	push rsi
	push rax
	mov rsi, [os_LocalAPICAddress]
	xor eax, eax
	mov al, 0x10
	mov dword [rsi+0x80], eax	; APIC Task Priority Register (TPR)
	pop rax
	pop rsi
	sti

	push rdi			; Push RDI since it is used temporarily
	push rax			; Push RAX since os_smp_get_id uses it
	mov rdi, cpustatus
	call os_smp_get_id		; Set RAX to the APIC ID
	add rdi, rax
	mov al, 00000011b		; Bit 0 set for "Present", Bit 1 set for "Busy"
	stosb
	pop rax				; Pop RAX (holds the workload code address)
	pop rdi				; Pop RDI (holds the variable/variable address)

	mov r15, rax

	call os_get_argc
	mov rcx, rax
	cmp al, 1
	je noargs

	mov rdi, os_args
	sub rcx, 1
	shl rcx, 3
	add rdi, rcx
	shr rcx, 3
	add rcx, 1
nextargv:
	sub al, 1
	call os_get_argv
	mov [rdi], rsi
	sub rdi, 8
	cmp al, 1
	jne nextargv

noargs:
	mov al, 0
	call os_get_argv
	mov [os_args], rsi
	mov rsi, os_args		; ARGV[0]

	mov rdi, rcx			; ARGC
	mov rax, r15

	call rax			; Run the code

	; Check task list and restart CLI if needed

	jmp ap_clear			; Reset the stack, clear the registers, and wait for something else to work on

;hellofunc:
;	push rsi
;	push rcx
;	push rax
;
;	mov rsi, readymsg
;	call os_output	
;	xor eax, eax
;	mov rsi, os_EthernetBuffer
;	lodsw
;	mov rcx, rax
;	call os_debug_dump_mem
;	call os_print_newline
;	
;	pop rax
;	pop rcx
;	pop rsi
;	ret

; Includes
%include "init.asm"
%include "syscalls.asm"
%include "drivers.asm"
%include "interrupt.asm"
;%include "cli.asm"
%include "sysvar.asm"			; Include this last to keep the read/write variables away from the code

times 16384-($-$$) db 0			; Set the compiled kernel binary to at least this size in bytes

; =============================================================================
; EOF
