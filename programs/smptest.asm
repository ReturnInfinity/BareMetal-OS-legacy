; -----------------------------------------------------------------------------
; SMP Test Program (v1.1, May 14 2013)
; Ian Seyler @ Return Infinity
;
; Demo the ability to spawn multiple workloads for CPU cores to work on
;
; BareMetal compile:
; nasm smptest.asm -o smptest.app
; -----------------------------------------------------------------------------


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:				; Start of program label

	mov rax, ap_print_id	; Our code to run on all CPUs
	xor rbx, rbx		; Clear RBX as there is no argument
	mov rcx, 64		; Number of instances to spawn

spawn:
	call [b_smp_enqueue]
	sub rcx, 1
	cmp rcx, 0
	jne spawn

bsp:
	call [b_smp_dequeue]	; Try to dequeue a workload
	cmp eax, 0
	je emptyqueue		; If 0 is returned then the queue is empty
	call [b_smp_run]	; Otherwise run the workload
	jmp bsp			; Try to do another workload

emptyqueue:
	call [b_smp_wait]	; Wait for all other processors to finish
	mov rsi, endstring
	call [b_output]

	ret			; Return to OS

endstring: db 13, 0
spacestring: db ' ', 0

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

	lock btr word [mutex], 0	; The mutex was free, lock the bus, try to grab the mutex
	jnc grablock		; Jump if we were unsuccessful

	mov rdx, 1		; Get the local APIC ID
	call [b_system_misc]
	mov rdx, 5		; Print the APIC ID
	call [b_system_misc]
	mov rsi, spacestring
	call [b_output]

	bts word [mutex], 0	; Release the mutex
	ret

	mutex dw 1		; The MUTual-EXclustion flag

; EOF
