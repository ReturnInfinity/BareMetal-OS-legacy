; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; INIT HDD
; =============================================================================

align 16
db 'DEBUG: INIT_HDD '
align 16


hdd_setup:
; Read first sector (MBR) into memory
	xor rax, rax
	mov rdi, secbuffer0
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi

	cmp byte [0x0000000000005030], 0x01	; Did we boot from a MBR drive
	jne hdd_setup_no_mbr			; If not then we already have the correct sector

; Grab the partition offset value for the first partition
	mov eax, [rdi+0x01C6]
	mov [fat16_PartitionOffset], eax

; Read the first sector of the first partition
	mov rdi, secbuffer0
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi

hdd_setup_no_mbr:
; Get the values we need to start using fat16
	mov ax, [rdi+0x0b]
	mov [fat16_BytesPerSector], ax		; This will probably be 512
	mov al, [rdi+0x0d]
	mov [fat16_SectorsPerCluster], al	; This will be 128 or less (Max cluster size is 64KiB)
	mov ax, [rdi+0x0e]
	mov [fat16_ReservedSectors], ax
	mov [fat16_FatStart], eax
	mov al, [rdi+0x10]
	mov [fat16_Fats], al			; This will probably be 2
	mov ax, [rdi+0x11]
	mov [fat16_RootDirEnts], ax
	mov ax, [rdi+0x16]
	mov [fat16_SectorsPerFat], ax

; Find out how many sectors are on the disk
	xor eax, eax
	mov ax, [rdi+0x13]
	cmp ax, 0x0000
	jne lessthan65536sectors
	mov eax, [rdi+0x20]
lessthan65536sectors:
	mov [fat16_TotalSectors], eax

; Calculate the size of the drive in MiB
	xor rax, rax
	mov eax, [fat16_TotalSectors]
	mov [hd1_maxlba], rax
	shr rax, 11 ; rax = rax * 512 / 1048576
	mov [hd1_size], eax ; in mebibytes

; Calculate FAT16 info
	xor rax, rax
	xor rbx, rbx
	mov ax, [fat16_SectorsPerFat]
	shl ax, 1	; quick multiply by two
	add ax, [fat16_ReservedSectors]
	mov [fat16_RootStart], eax
	mov bx, [fat16_RootDirEnts]
	shr ebx, 4	; bx = (bx * 32) / 512
	add ebx, eax	; BX now holds the datastart sector number
	mov [fat16_DataStart], ebx

ret


; =============================================================================
; EOF
