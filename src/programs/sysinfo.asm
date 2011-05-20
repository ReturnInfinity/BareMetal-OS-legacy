; System Information Program (v1.0, July 6 2010)
; Written by Ian Seyler
;
; BareMetal compile:
; nasm sysinfo.asm -o sysinfo.app


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:				; Start of program label

	mov rsi, startmessage	; Load RSI with memory address of string
	call b_print_string	; Print the string that RSI points to

;Get processor brand string
	xor rax, rax
	mov rdi, tstring
	mov eax, 0x80000002
	cpuid
	stosd
	mov eax, ebx
	stosd
	mov eax, ecx
	stosd
	mov eax, edx
	stosd
	mov eax, 0x80000003
	cpuid
	stosd
	mov eax, ebx
	stosd
	mov eax, ecx
	stosd
	mov eax, edx
	stosd
	mov eax, 0x80000004
	cpuid
	stosd
	mov eax, ebx
	stosd
	mov eax, ecx
	stosd
	mov eax, edx
	stosd
	xor al, al
	stosb			; Terminate the string
	mov rsi, tstring
	call b_string_parse
	mov rsi, cpustringmsg
	call b_print_string
	mov rsi, tstring
	call b_print_string

; Number of cores
	call b_print_newline
	mov rsi, numcoresmsg
	call b_print_string
	xor rax, rax
	mov rsi, 0x5012
	lodsw
	mov rdi, tstring
	call b_int_to_string
	mov rsi, tstring
	call b_print_string

; Speed 
	call b_print_newline
	mov rsi, speedmsg
	call b_print_string
	xor rax, rax
	mov rsi, 0x5010
	lodsw
	mov rdi, tstring
	call b_int_to_string
	mov rsi, tstring
	call b_print_string
	mov rsi, mhzmsg
	call b_print_string

; L1 code/data cache info
	call b_print_newline
	mov eax, 0x80000005	; L1 cache info
	cpuid
	mov eax, edx		; EDX bits 31 - 24 store code L1 cache size in KBs
	shr eax, 24
	mov rdi, tstring
	call b_int_to_string
	mov rsi, l1ccachemsg
	call b_print_string
	mov rsi, tstring
	call b_print_string
	mov rsi, kbmsg
	call b_print_string
	call b_print_newline	
	mov eax, ecx		; ECX bits 31 - 24 store data L1 cache size in KBs
	shr eax, 24
	mov rdi, tstring
	call b_int_to_string
	mov rsi, l1dcachemsg
	call b_print_string
	mov rsi, tstring
	call b_print_string
	mov rsi, kbmsg
	call b_print_string

; L2/L3 cache info
	call b_print_newline
	mov eax, 0x80000006	; L2/L3 cache info
	cpuid
	mov eax, ecx		; ecx bits 31 - 16 store unified L2 cache size in KBs
	shr eax, 16
	mov rdi, tstring
	call b_int_to_string
	mov rsi, l2ucachemsg
	call b_print_string
	mov rsi, tstring
	call b_print_string
	mov rsi, kbmsg
	call b_print_string

	call b_print_newline
	mov eax, edx		; edx bits 31 - 18 store unified L3 cache size in 512 KB chunks
	shr eax, 18
	and eax, 0x3FFFF	; Clear bits 18 - 31
	shl eax, 9		; Convert the value for 512 KB chunks to KBs (Multiply by 512)
	mov rdi, tstring
	call b_int_to_string
	mov rsi, l3ucachemsg
	call b_print_string
	mov rsi, tstring
	call b_print_string
	mov rsi, kbmsg
	call b_print_string

;CPU features
	call b_print_newline
	mov rsi, cpufeatures
	call b_print_string
	mov rax, 1
	cpuid

checksse:
	test edx, 00000010000000000000000000000000b
	jz checksse2
	mov rsi, sse
	call b_print_string

checksse2:
	test edx, 00000100000000000000000000000000b
	jz checksse3
	mov rsi, sse2
	call b_print_string

checksse3:
	test ecx, 00000000000000000000000000000001b
	jz checkssse3
	mov rsi, sse3
	call b_print_string

checkssse3:
	test ecx, 00000000000000000000001000000000b
	jz checksse41
	mov rsi, ssse3
	call b_print_string

checksse41:
	test ecx, 00000000000010000000000000000000b
	jz checksse42
	mov rsi, sse41
	call b_print_string

checksse42:
	test ecx, 00000000000100000000000000000000b
	jz checkaes
	mov rsi, sse42
	call b_print_string

checkaes:
	test ecx, 00000010000000000000000000000000b
	jz checkavx
	mov rsi, aes
	call b_print_string

checkavx:
	test ecx, 00010000000000000000000000000000b
	jz endit
	mov rsi, avx
	call b_print_string

endit:
;RAM
	call b_print_newline
	mov rsi, memmessage
	call b_print_string
	xor rax, rax
	mov rsi, 0x5020
	lodsw
	mov rdi, tstring
	call b_int_to_string
	mov rsi, tstring
	call b_print_string
	mov rsi, mbmsg
	call b_print_string


	call b_print_newline

ret				; Return to OS

startmessage: db 'System Information:', 13, 0
cpustringmsg: db 'CPU String: ', 0
numcoresmsg: db 'Number of cores: ', 0
speedmsg: db 'Detected speed: ', 0
l1ccachemsg: db 'L1 code cache: ', 0
l1dcachemsg: db 'L1 data cache: ', 0
l2ucachemsg: db 'L2 unified cache: ', 0
l3ucachemsg: db 'L3 unified cache: ', 0
cpufeatures: db 'CPU features: ', 0
kbmsg: db ' KiB', 0
mbmsg: db ' MiB', 0
mhzmsg: db ' MHz', 0
sse: db 'SSE ', 0
sse2: db 'SSE2 ', 0
sse3: db 'SSE3 ', 0
ssse3: db 'SSSE3 ', 0
sse41: db 'SSE4.1 ', 0
sse42: db 'SSE4.2 ', 0
aes: db 'AES ', 0
avx: db 'AVX ', 0
memmessage: db 'RAM: ', 0

tstring: times 50 db 0