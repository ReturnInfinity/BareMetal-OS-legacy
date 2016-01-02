; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; SMP Functions
; =============================================================================

align 16
db 'DEBUG: SMP      '
align 16


; -----------------------------------------------------------------------------
; os_smp_reset -- Resets a CPU Core
;  IN:	AL = CPU #
; OUT:	Nothing. All registers preserved.
; Note:	This code resets an AP
;	For set-up use only.
os_smp_reset:
	push rdi
	push rax

	mov rdi, [os_LocalAPICAddress]
	shl eax, 24		; AL holds the CPU #, shift left 24 bits to get it into 31:24, 23:0 are reserved
	mov [rdi+0x0310], eax	; Write to the high bits first
	xor eax, eax		; Clear EAX, namely bits 31:24
	mov al, 0x81		; Execute interrupt 0x81
	mov [rdi+0x0300], eax	; Then write to the low bits

	pop rax
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_wakeup -- Wake up a CPU Core
;  IN:	AL = CPU #
; OUT:	Nothing. All registers preserved.
os_smp_wakeup:
	push rdi
	push rax

	mov rdi, [os_LocalAPICAddress]
	shl eax, 24		; AL holds the CPU #, shift left 24 bits to get it into 31:24, 23:0 are reserved
	mov [rdi+0x0310], eax	; Write to the high bits first
	xor eax, eax		; Clear EAX, namely bits 31:24
	mov al, 0x80		; Execute interrupt 0x80
	mov [rdi+0x0300], eax	; Then write to the low bits

	pop rax
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_wakeup_all -- Wake up all CPU Cores
;  IN:	Nothing.
; OUT:	Nothing. All registers preserved.
os_smp_wakeup_all:
	push rdi
	push rax

	mov rdi, [os_LocalAPICAddress]
	xor eax, eax
	mov [rdi+0x0310], eax	; Write to the high bits first
	mov eax, 0x000C0080	; Execute interrupt 0x80
	mov [rdi+0x0300], eax	; Then write to the low bits

	pop rax
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_get_id -- Returns the APIC ID of the CPU that ran this function
;  IN:	Nothing
; OUT:	RAX = CPU's APIC ID number, All other registers preserved.
os_smp_get_id:
	push rsi

	xor eax, eax
	mov rsi, [os_LocalAPICAddress]
	add rsi, 0x20		; Add the offset for the APIC ID location
	lodsd			; APIC ID is stored in bits 31:24
	shr rax, 24		; AL now holds the CPU's APIC ID (0 - 255)

	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_enqueue -- Add a workload to the processing queue
;  IN:	RAX = Address of code to execute
;	RSI = Variable
; OUT:	Nothing
os_smp_enqueue:
	push rdi
	push rsi
	push rcx
	push rax

os_smp_enqueue_spin:
	bt word [os_QueueLock], 0	; Check if the mutex is free
	jc os_smp_enqueue_spin		; If not check it again
	lock bts word [os_QueueLock], 0	; The mutex was free, lock the bus. Try to grab the mutex
	jc os_smp_enqueue_spin		; Jump if we were unsuccessful

	cmp word [os_QueueLen], 256	; aka cpuqueuemax
	je os_smp_enqueue_fail

	xor ecx, ecx
	mov rdi, cpuqueue
	mov cx, [cpuqueuefinish]
	shl rcx, 4			; Quickly multiply RCX by 16
	add rdi, rcx

	stosq				; Store the code address from RAX
	mov rax, rsi
	stosq				; Store the variable

	add word [os_QueueLen], 1
	shr rcx, 4			; Quickly divide RCX by 16
	add cx, 1
	cmp cx, [cpuqueuemax]
	jne os_smp_enqueue_end
	xor cx, cx			; We wrap around

os_smp_enqueue_end:
	mov [cpuqueuefinish], cx
	pop rax
	pop rcx
	pop rsi
	pop rdi
	btr word [os_QueueLock], 0	; Release the lock
	call os_smp_wakeup_all
	clc				; Carry clear for success
	ret

os_smp_enqueue_fail:
	pop rax
	pop rcx
	pop rsi
	pop rdi
	btr word [os_QueueLock], 0	; Release the lock
	stc				; Carry set for failure (Queue full)
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_dequeue -- Dequeue a workload from the processing queue
;  IN:	Nothing
; OUT:	RAX = Address of code to execute (Set to 0 if queue is empty)
;	RDI = Variable
os_smp_dequeue:
	push rsi
	push rcx

os_smp_dequeue_spin:
	bt word [os_QueueLock], 0	; Check if the mutex is free
	jc os_smp_dequeue_spin		; If not check it again
	lock bts word [os_QueueLock], 0	; The mutex was free, lock the bus. Try to grab the mutex
	jc os_smp_dequeue_spin		; Jump if we were unsuccessful

	cmp word [os_QueueLen], 0
	je os_smp_dequeue_fail

	xor ecx, ecx
	mov rsi, cpuqueue
	mov cx, [cpuqueuestart]
	shl rcx, 4			; Quickly multiply RCX by 16
	add rsi, rcx

	lodsq				; Load the code address into RAX
	push rax
	lodsq				; Load the variable
	mov rdi, rax
	pop rax

	sub word [os_QueueLen], 1
	shr rcx, 4			; Quickly divide RCX by 16
	add cx, 1
	cmp cx, [cpuqueuemax]
	jne os_smp_dequeue_end
	xor cx, cx			; We wrap around

os_smp_dequeue_end:
	mov word [cpuqueuestart], cx
	pop rcx
	pop rsi
	btr word [os_QueueLock], 0	; Release the lock
	clc				; If we got here then ok
	ret

os_smp_dequeue_fail:
	xor rax, rax
	pop rcx
	pop rsi
	btr word [os_QueueLock], 0	; Release the lock
	stc
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_run -- Call the code address stored in RAX
;  IN:	RAX = Address of code to execute
; OUT:	Nothing
os_smp_run:
	call rax			; Run the code
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_queuelen -- Returns the number of items in the processing queue
;  IN:	Nothing
; OUT:	RAX = number of items in processing queue
os_smp_queuelen:
	xor eax, eax
	mov ax, [os_QueueLen]
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_numcores -- Returns the number of cores in this computer
;  IN:	Nothing
; OUT:	RAX = number of cores in this computer
os_smp_numcores:
	xor eax, eax
	mov ax, [os_NumCores]
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_wait -- Wait until all other CPU Cores are finished processing
;  IN:	Nothing
; OUT:	Nothing. All registers preserved.
os_smp_wait:
	push rsi
	push rcx
	push rbx
	push rax

	call os_smp_get_id
	mov rbx, rax

	xor eax, eax
	xor ecx, ecx
	mov rsi, cpustatus

checkit:
	lodsb
	cmp rbx, rcx		; Check to see if it is looking at itself
	je skipit		; If so then skip as it should be marked as busy
	bt ax, 0		; Check the Present bit
	jnc skipit		; If carry is not set then the CPU does not exist
	bt ax, 1		; Check the Ready/Busy bit
	jnc skipit		; If carry is not set then the CPU is Ready
	sub rsi, 1
	jmp checkit		; Core is marked as Busy, check it again
skipit:
	add rcx, 1
	cmp rcx, 256
	jne checkit

	pop rax
	pop rbx
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_lock -- Attempt to lock a mutex
;  IN:	RAX = Address of lock variable
; OUT:	Nothing. All registers preserved.
os_smp_lock:
	bt word [rax], 0	; Check if the mutex is free (Bit 0 cleared to 0)
	jc os_smp_lock		; If not check it again
	lock bts word [rax], 0	; The mutex was free, lock the bus. Try to grab the mutex
	jc os_smp_lock		; Jump if we were unsuccessful
	ret			; Lock acquired. Return to the caller
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_smp_unlock -- Unlock a mutex
;  IN:	RAX = Address of lock variable
; OUT:	Nothing. All registers preserved.
os_smp_unlock:
	btr word [rax], 0	; Release the lock (Bit 0 cleared to 0)
	ret			; Lock released. Return to the caller
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
