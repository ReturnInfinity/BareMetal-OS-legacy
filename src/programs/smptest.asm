; SMP Test Program (v1.0, July 6 2010)
; Written by Ian Seyler
;
; BareMetal compile:
; nasm smptest.asm -o smptest.app


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:				; Start of program label

	mov rax, ap_print_id	; Our code to run on all CPUs
	xor rbx, rbx		; Clear RBX as there is no argument
	mov rcx, 64		; Number of instances to spawn

spawn:
	call b_smp_enqueue
	sub rcx, 1
	cmp rcx, 0
	jne spawn

bsp:
	call b_smp_dequeue	; Try to dequeue a workload
	jc emptyqueue		; If carry is set then the queue is empty
	call b_smp_run		; Otherwise run the workload
	jne bsp			; If it is not empty try to do another workload

emptyqueue:
	call b_smp_wait		; Wait for all other processors to finish
	call b_print_newline

ret				; Return to OS


; This procedure will be executed by each of the processors
; It requires mutually exclusive access while it creates the string and prints to the screen
; We must insure that only one CPU at a time can execute this code, so we employ a 'spinlock'.
ap_print_id:
	mov rcx, 0x1FFFFF
delay:
	dec rcx
	cmp rcx, 0
	jne delay

grablock:
	bt word [mutex], 0	; Check if the mutex is free
	jnc grablock		; If not check it again

	lock			; The mutex was free, lock the bus
	btr word [mutex], 0	; Try to grab the mutex
	jnc grablock		; Jump if we were unsuccessful

	call b_smp_get_id	; Get the local APIC ID
	call b_debug_dump_al	; Print the APIC ID
	mov al, ' '
	call b_print_char

	bts word [mutex], 0	; Release the mutex
ret

	mutex dw 1		; The MUTual-EXclustion flag
