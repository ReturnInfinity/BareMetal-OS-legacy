; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; FAT16 Functions
; =============================================================================

align 16
db 'DEBUG: FAT16    '
align 16

; -----------------------------------------------------------------------------
; os_fat16_setup -- Initialize FAT16 data structures
os_fat16_setup:
; Read first sector (MBR) into memory
	xor rax, rax
	mov rdi, secbuffer0
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi

	cmp byte [0x0000000000005030], 0x01	; Did we boot from a MBR drive
	jne os_fat16_setup_no_mbr		; If not then we already have the correct sector

; Grab the partition offset value for the first partition
	mov eax, [rdi+0x01C6]
	mov [fat16_PartitionOffset], eax

; Read the first sector of the first partition
	mov rdi, secbuffer0
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi

os_fat16_setup_no_mbr:
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
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_read_cluster -- Read a cluster from the FAT16 partition
; IN:	AX  = Cluster # to read
;	RDI = Memory location to store at least 32KB
; OUT:	AX  = Next cluster in chain (0xFFFF if this was the last)
;	RDI = Points one byte after the last byte read
os_fat16_read_cluster:
	push rsi
	push rdx
	push rcx
	push rbx

	and rax, 0x000000000000FFFF		; Clear the top 48 bits
	mov rbx, rax				; Save the cluster number to be used later

	cmp ax, 2				; If less than 2 then bail out...
	jl near os_fat16_read_cluster_bailout	; as clusters start at 2

; Calculate the LBA address --- startingsector = (cluster-2) * clustersize + data_start
	xor rcx, rcx
	mov cl, byte [fat16_SectorsPerCluster]
	push rcx				; Save the number of sectors per cluster
	sub ax, 2
	imul cx					; EAX now holds starting sector
	add eax, dword [fat16_DataStart]	; EAX now holds the sector where our cluster starts
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition

	pop rcx					; Restore the number of sectors per cluster
	call readsectors			; Read one cluster of sectors

; Calculate the next cluster
; Psuedo-code
; tint1 = Cluster / 256  <- Dump the remainder
; sector_to_read = tint1 + ReservedSectors
; tint2 = (Cluster - (tint1 * 256)) * 2
	push rdi
	mov rdi, secbuffer1			; Read to this temporary buffer
	mov rsi, rdi				; Copy buffer address to RSI
	push rbx				; Save the original cluster value
	shr rbx, 8				; Divide the cluster value by 256. Keep no remainder
	movzx ax, [fat16_ReservedSectors]	; First sector of the first FAT
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	add rax, rbx				; Add the sector offset
	mov rcx, 1
	call readsectors
	pop rax					; Get our original cluster value back
	shl rbx, 8				; Quick multiply by 256 (RBX was the sector offset in the FAT)
	sub rax, rbx				; RAX is now pointed to the offset within the sector
	shl rax, 1				; Quickly multiply by 2 (since entries are 16-bit)
	add rsi, rax
	lodsw					; AX now holds the next cluster
	pop rdi

	jmp os_fat16_read_cluster_end

os_fat16_read_cluster_bailout:
	xor ax, ax

os_fat16_read_cluster_end:
	pop rbx
	pop rcx
	pop rdx
	pop rsi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_write_cluster -- Write a cluster to the FAT16 partition
; IN:	AX  = Cluster # to write to
;	RSI = Memory location of data to write
; OUT:	AX  = Next cluster in the chain (set to 0xFFFF if this was the last cluster of the chain)
;	RSI = Points one byte after the last byte written
os_fat16_write_cluster:
	push rdi
	push rdx
	push rcx
	push rbx

	and rax, 0x000000000000FFFF		; Clear the top 48 bits
	mov rbx, rax				; Save the cluster number to be used later

	cmp ax, 2				; If less than 2 then bail out...
	jl near os_fat16_write_cluster_bailout	; as clusters start at 2

; Calculate the LBA address --- startingsector = (cluster-2) * clustersize + data_start
	xor rcx, rcx
	mov cl, byte [fat16_SectorsPerCluster]
	push rcx				; Save the number of sectors per cluster
	sub ax, 2
	imul cx					; EAX now holds starting sector
	add eax, dword [fat16_DataStart]	; EAX now holds the sector where our cluster starts
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition

	pop rcx					; Restore the number of sectors per cluster
	call writesectors

; Calculate the next cluster
	push rsi
	mov rdi, secbuffer1			; Read to this temporary buffer
	mov rsi, rdi				; Copy buffer address to RSI
	push rbx				; Save the original cluster value
	shr rbx, 8				; Divide the cluster value by 256. Keep no remainder
	movzx ax, [fat16_ReservedSectors]	; First sector of the first FAT
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	add rax, rbx				; Add the sector offset
	mov rcx, 1
	call readsectors
	pop rax					; Get our original cluster value back
	shl rbx, 8				; Quick multiply by 256 (RBX was the sector offset in the FAT)
	sub rax, rbx				; RAX is now pointed to the offset within the sector
	shl rax, 1				; Quickly multiply by 2 (since entries are 16-bit)
	add rsi, rax
	lodsw					; AX now holds the next cluster
	pop rsi

	jmp os_fat16_write_cluster_done

os_fat16_write_cluster_bailout:
	xor ax, ax

os_fat16_write_cluster_done:
	pop rbx
	pop rcx
	pop rdx
	pop rdi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_find_file -- Search for a file name and return the starting cluster
; IN:	RSI = Pointer to file name, must be in 'FILENAMEEXT' format
; OUT:	AX  = Staring cluster
;	ECX = File size
;	Carry set if not found. If carry is set then ignore value in AX
os_fat16_find_file:
	push rsi
	push rdi
	push rdx
	push rbx

	clc				; Clear carry
	xor rax, rax
	mov eax, [fat16_RootStart]	; eax points to the first sector of the root
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rdx, rax			; Save the sector value

os_fat16_find_file_read_sector:
	mov rdi, hdbuffer1
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi
	mov rbx, 16			; Each record is 32 bytes. 512 (bytes per sector) / 32 = 16

os_fat16_find_file_next_entry:
	cmp byte [rdi], 0x00		; end of records
	je os_fat16_find_file_notfound

	mov rcx, 11
	push rsi
	repe cmpsb
	pop rsi
	mov ax, [rdi+15]		; AX now holds the starting cluster # of the file we just looked at
	mov ecx, [rdi+17]		; ECX now holds the size of the file in bytes
	jz os_fat16_find_file_done	; The file was found. Note that rdi now is at dirent+11

	add rdi, byte 0x20
	and rdi, byte -0x20
	dec rbx
	cmp rbx, 0
	jne os_fat16_find_file_next_entry

; At this point we have read though one sector of file names. We have not found the file we are looking for and have not reached the end of the table. Load the next sector.

	add rdx, 1
	mov rax, rdx
	jmp os_fat16_find_file_read_sector

os_fat16_find_file_notfound:
	stc				; Set carry
	xor rax, rax

os_fat16_find_file_done:
	cmp ax, 0x0000			; BUG HERE
	jne wut				; Carry is not being set properly in this function
	stc
wut:
	pop rbx
	pop rdx
	pop rdi
	pop rsi
ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_get_list -- Generate a list of files on disk
; IN:	RDI = location to store list
; OUT:	RDI = pointer to end of list
os_fat16_file_get_list:
	push rsi
	push rdi
	push rcx
	push rbx
	push rax

	push rsi
	mov rsi, dir_title_string
	call os_string_length
	call os_string_copy			; Copy the header
	add rdi, rcx
	pop rsi

	xor rbx, rbx
	mov ebx, [fat16_RootStart]		; ebx points to the first sector of the root
	add ebx, [fat16_PartitionOffset]	; Add the offset to the partition

	jmp os_fat16_file_get_list_read_sector

os_fat16_file_get_list_next_sector:
	add rbx, 1

os_fat16_file_get_list_read_sector:
	push rdi
	mov rdi, hdbuffer1
	mov rsi, rdi
	mov rcx, 1
	mov rax, rbx
	call readsectors
	pop rdi

	; RDI = location of string
	; RSI = buffer that contains the cluster

	; start reading
os_fat16_file_get_list_read:
	cmp rsi, hdbuffer1+512
	je os_fat16_file_get_list_next_sector
	cmp byte [rsi], 0x00		; end of records
	je os_fat16_file_get_list_done
	cmp byte [rsi], 0xE5		; unused record
	je os_fat16_file_get_list_skip

	mov al, [rsi + 8]		; Grab the attribute byte
	bt ax, 5			; check if bit 3 is set (volume label)
	jc os_fat16_file_get_list_skip	; if so skip the entry
	mov al, [rsi + 11]		; Grab the attribute byte
	cmp al, 0x0F			; Check if it is a LFN entry
	je os_fat16_file_get_list_skip	; if so skip the entry

	; copy the string
	xor rcx, rcx
	xor rax, rax
os_fat16_file_get_list_copy:
	mov al, [rsi+rcx]
	stosb				; Store to RDI
	inc rcx
	cmp rcx, 8
	jne os_fat16_file_get_list_copy

	mov al, ' '			; Store a space as the separtator
	stosb

	mov al, [rsi+8]
	stosb
	mov al, [rsi+9]
	stosb
	mov al, [rsi+10]
	stosb

	mov al, ' '			; Store a space as the separtator
	stosb

	mov eax, [rsi+0x1C]
	call os_int_to_string
	dec rdi
	mov al, 13
	stosb

os_fat16_file_get_list_skip:
	add rsi, 32
	jmp os_fat16_file_get_list_read

os_fat16_file_get_list_done:
	mov al, 0x00
	stosb

	pop rax
	pop rbx
	pop rcx
	pop rdi
	pop rsi
ret

dir_title_string: db "Name     Ext Size", 13, "====================", 13, 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_read -- Read a file from disk into memory
; IN:	RSI = Address of filename string
;	RDI = Memory location where file will be loaded to
; OUT:	Carry clear on success, set if file was not found or error occured
os_fat16_file_read:
	push rsi
	push rdi
	push rcx			; Used by os_fat16_find_file
	push rax

; Convert the file name to FAT format
	push rdi			; Save the memory address
	mov rdi, os_fat16_file_read_string
	call os_fat16_filename_convert	; Convert the filename to the proper FAT format
	xchg rsi, rdi
	pop rdi				; Grab the memory address
	jc os_fat16_file_read_done	; If Carry is set then the filename could not be converted

; Check to see if the file exists
	call os_fat16_find_file		; Fuction will return the starting cluster value in AX or carry set if not found
	jc os_fat16_file_read_done	; If Carry is clear then the file exists. AX is set to the starting cluster

os_fat16_file_read_read:
	call os_fat16_read_cluster	; Store cluster in memory. AX is set to the next cluster
	cmp ax, 0xFFFF			; 0xFFFF is the FAT end of file marker
	jne os_fat16_file_read_read	; Are there more clusters? If so then read again.. if not fall through
	clc				; Clear Carry

os_fat16_file_read_done:
	pop rax
	pop rcx
	pop rdi
	pop rsi
ret

	os_fat16_file_read_string	times 13 db 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_write -- Write a file to the hard disk
; IN:	RSI = Address of data in memory
;	RDI = File name to write
;	RCX = number of bytes to write
; OUT:	Carry clear on success, set on failure
os_fat16_file_write:
	push rsi
	push rdi
	push rcx
	push rax

	mov [memory_address], rsi	; Save the memory address

; Convert the file name to FAT format
	mov rsi, rdi			; Move the file name address into RSI
	mov rdi, os_fat16_file_write_string
	call os_fat16_filename_convert	; Convert the filename to the proper FAT format
	jc os_fat16_file_write_done	; Fail (Invalid file name)

; Check to see if a file already exists with the same name
	mov rsi, os_fat16_file_write_string
	push rcx
	call os_fat16_find_file		; Returns the starting cluster in AX or carry set if it doesn't exist
	pop rcx
	jc os_fat16_file_write_create	; Jump if the file doesn't exist (No need to delete it)
	jmp os_fat16_file_write_done	;	call os_fat16_file_delete

; At this point the file doesn't exist so create it.
os_fat16_file_write_create:
xchg bx, bx
	call os_fat16_file_create
	jc os_fat16_file_write_done	; Fail (Couldn't create the file)
	call os_fat16_find_file		; Call this to get the starting cluster
	jc os_fat16_file_write_done	; Fail (File was supposed to be created but wasn't)

; We are ready to start writing. First cluster is in AX
	mov rsi, [memory_address]
os_fat16_file_write_write:
	call os_fat16_write_cluster
	cmp ax, 0xFFFF
	jne os_fat16_file_write_write
	clc

os_fat16_file_write_done:
	pop rax
	pop rcx
	pop rdi
	pop rsi
ret

	os_fat16_file_write_string	times 13 db 0
	memory_address			dq 0x0000000000000000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_create -- Create a file on the hard disk
; IN:	RSI = Pointer to file name, must be in FAT 'FILENAMEEXT' format
;	RCX = File size
; OUT:	Carry clear on success, set on failure
; Note:	This function pre-allocates all clusters required for the size of the file
os_fat16_file_create:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	clc				; Clear the carry flag. It will be set if there is an error

	mov [filesize], ecx		; Save file size for later
	mov [filename], rsi

; Check to see if a file already exists with the same name
;	call os_fat16_find_file
;	jc os_fat16_file_create_fail	; Fail (File already exists)

; How many clusters will we need?
	mov rax, rcx
	xor rdx, rdx
	xor rbx, rbx
	mov bl, byte [fat16_SectorsPerCluster]
	shl rbx, 9			; Multiply by 512 to get bytes per cluster
	div rbx
	cmp rdx, 0
	jg add_a_bit			; If there's a remainder, we need another cluster
	jmp carry_on
add_a_bit:
	add rax, 1
carry_on:
	mov rcx, rax			; RCX holds number of clusters that are needed

; Allocate all of the clusters required for the amount of bytes we are writting.
	xor rax, rax
	mov ax, [fat16_ReservedSectors]		; First sector of the first FAT
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rdi, hdbuffer0
	mov rsi, rdi
	push rcx
	mov rcx, 64
	call readsectors
	pop rcx
	xor rdx, rdx				; cluster we are currently at
	xor rbx, rbx				; cluster marker
findfirstfreeclust:
	mov rdi, rsi
	lodsw
	inc dx					; counter
	cmp ax, 0x0000
	jne findfirstfreeclust			; Continue until we find a free cluster
	dec dx
	mov [startcluster], dx			; Save the starting cluster ID
	inc dx
	mov bx, dx
	cmp rcx, 0
	je clusterdone
	cmp rcx, 1
	je clusterdone

findnextfreecluster:
	lodsw
	inc dx
	cmp ax, 0x0000
	jne findnextfreecluster
	mov ax, bx
	mov bx, dx
	stosw
	mov rdi, rsi
	sub rdi, 2
	dec rcx
	cmp rcx, 1
	jne findnextfreecluster

clusterdone:
	mov ax, 0xFFFF
	stosw
;	push dx					; save the free cluster number
;	inc rbx
;	cmp rbx, rcx				; Have we found enough free clusters?
;	jne nextclust				; If not keep going, if yes fall through
; At this point we have free cluster ID's on the stack

;	mov ax, 0xFFFF



; At this point we have a sector of FAT in hdbuffer0. A cluster has been marked in use but the sector is not written back to disk yet!
; Save the sector # as we will write this to disk later

; Load the first sector of the file info table
	xor rax, rax
	mov eax, [fat16_RootStart]	; eax points to the first sector of the root
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rdi, hdbuffer1
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi
	mov rcx, 16			; records / sector
	mov rsi, rdi
nextrecord:
	sub rcx, 1
	cmp byte [rsi], 0x00		; Empty record
	je foundfree
	cmp byte [rsi], 0xE5		; Unused record
	je foundfree
	add rsi, 32			; Each record is 32 bytes
	cmp rcx, 0
	je os_fat16_file_create_fail
	jmp nextrecord

foundfree:
	; At this point RSI points to the start of the record
	mov rdi, rsi
	mov rsi, [filename]
	mov rcx, 11
nextchar:
	lodsb
	stosb
	sub rcx, 1
	cmp rcx, 0
	jne nextchar
	xor rax, rax
	stosb	; LFN Attrib
	stosb	; NT Reserved
	stosw	; Create time
	stosb	; Create time
	stosw	; Create date
	stosw	; Access date
	stosw	; Access time
	stosw	; Modified time
	stosw	; Modified date
	mov ax, [startcluster]
	stosw
	mov eax, [filesize]
	stosd	; File size

; At this point the updated file record is in memory at hdbuffer1

	xor rax, rax

	movzx ax, [fat16_ReservedSectors]	; First sector of the first FAT
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rsi, hdbuffer0
	mov rcx, 64
	call writesectors

	mov eax, [fat16_RootStart]	; eax points to the first sector of the root
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rsi, hdbuffer1
	mov rcx, 1
	call writesectors

	jmp os_fat16_file_create_done

os_fat16_file_create_fail:
	stc
	call os_speaker_beep

os_fat16_file_create_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
ret

;	newfile_string	times 13 db 0
	startcluster	dw 0x0000
	filesize	dd 0x00000000
	filename	dq 0x0000000000000000
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_delete -- Delete a file from the hard disk
; IN:	RSI = File name to delete
; OUT:	Carry clear on success, set on failure
os_fat16_file_delete:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx

	clc				; Clear carry
	xor rax, rax
	mov eax, [fat16_RootStart]	; eax points to the first sector of the root
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rdx, rax			; Save the sector value

; Convert the file name to FAT format
	mov rdi, os_fat16_file_delete_string
	call os_fat16_filename_convert	; Convert the filename to the proper FAT format
	jc os_fat16_file_delete_error	; Fail (Invalid file name)
	mov rsi, rdi

; Read through the root cluster (if file not found bail out)
os_fat16_file_delete_read_sector:
	mov rdi, hdbuffer0
	push rdi
	mov rcx, 1
	call readsectors
	pop rdi
	mov rbx, 16			; Each record is 32 bytes. 512 (bytes per sector) / 32 = 16

os_fat16_file_delete_next_entry:
	cmp byte [rdi], 0x00		; end of records
	je os_fat16_file_delete_error

	mov rcx, 11
	push rsi
	repe cmpsb
	pop rsi
	mov ax, [rdi+15]		; AX now holds the starting cluster # of the file we just looked at
	jz os_fat16_file_delete_found	; The file was found. Note that rdi now is at dirent+11

	add rdi, byte 0x20		; Great little trick here. Add 32 ...
	and rdi, byte -0x20		; ... and then round backwards to a 32-byte barrier. Sets RDI to the start of the next record
	dec rbx
	cmp rbx, 0
	jne os_fat16_file_delete_next_entry

; At this point we have read though one sector of file names. We have not found the file we are looking for and have not reached the end of the table. Load the next sector.
	add rdx, 1			; We are about to read the next sector so increment the counter
	mov rax, rdx
	jmp os_fat16_file_delete_read_sector

; Mark the file as deleted (set first byte of file name to 0xE5) and write the sector back to the drive
os_fat16_file_delete_found:
	xor rbx, rbx
	mov bx, ax			; Save the starting cluster value
	and rdi, byte -0x20		; Round backward to get to the start of the record
	mov al, 0xE5			; Set the first character of the filename to this
	stosb
	mov rsi, hdbuffer0
	mov rax, rdx			; Retrieve the sector number
	mov rcx, 1
	call writesectors

; Follow cluster chain and set any cluster in the chain to 0x0000 (mark as free)
	xor rax, rax
	mov ax, [fat16_ReservedSectors]		; First sector of the first FAT
	add eax, [fat16_PartitionOffset]	; Add the offset to the partition
	mov rdx, rax				; Save the sector value
	mov rdi, hdbuffer1
	mov rsi, rdi
	mov rcx, 1
	call readsectors
	xor rax, rax
os_fat16_file_delete_next_cluster:
	shl rbx, 1
	mov ax, word [rsi+rbx]
	mov [rsi+rbx], word 0x0000
	mov bx, ax
	cmp ax, 0xFFFF
	jne os_fat16_file_delete_next_cluster
	mov rax, rdx				; Get the sector back. RSI already points to what we need
	mov rcx, 1
	call writesectors
	jmp os_fat16_file_delete_done

os_fat16_file_delete_error:
	xor rax, rax
	stc				; Set carry

os_fat16_file_delete_done:
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
ret

	os_fat16_file_delete_string	times 13 db 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_file_get_size -- Read a file from disk into memory
; IN:	RSI = Address of filename string
; OUT:	RCX = Size of file in bytes
;	Carry clear on success, set if file was not found or error occured
os_fat16_file_get_size:
	push rsi
	push rdi
	push rax
	xor ecx, ecx

; Convert the file name to FAT format
	mov rdi, os_fat16_file_get_size_string
	call os_fat16_filename_convert	; Convert the filename to the proper FAT format
	mov rsi, rdi
	jc os_fat16_file_get_size_done	; If Carry is set then the filename could not be converted

; Check to see if the file exists
	call os_fat16_find_file		; Fuction will return the starting cluster value in AX and size in ECX or carry set if not found

os_fat16_file_get_size_done:
	pop rax
	pop rdi
	pop rsi
ret

	os_fat16_file_get_size_string	times 13 db 0
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_fat16_filename_convert -- Change 'test.er' into 'TEST    ER ' as per FAT16
; IN:	RSI = filename string
;	RDI = location to store converted string (carry set if invalid)
; OUT:	All registers preserved
; NOTE:	Must have room for 12 bytes. 11 for the name and 1 for the NULL
;	Need fix for short extensions!
os_fat16_filename_convert:
	push rsi
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	mov rbx, rdi				; Save the string destination address
	call os_string_length
	cmp rcx, 12				; Bigger than name + dot + extension?
	jg os_fat16_filename_convert_failure	; Fail if so
	cmp rcx, 0
	je os_fat16_filename_convert_failure	; Similarly, fail if zero-char string

	mov rdx, rcx			; Store string length for now
	xor rcx, rcx
os_fat16_filename_convert_copy_loop:
	lodsb
	cmp al, '.'
	je os_fat16_filename_convert_extension_found
	stosb
	inc rcx
	cmp rcx, rdx
	jg os_fat16_filename_convert_failure	; No extension found = wrong
	jmp os_fat16_filename_convert_copy_loop

os_fat16_filename_convert_failure:
	stc					; Set carry for failure
	jmp os_fat16_filename_convert_done

os_fat16_filename_convert_extension_found:
	cmp rcx, 0
	je os_fat16_filename_convert_failure	; Fail if extension dot is first char
	cmp rcx, 8
	je os_fat16_filename_convert_do_extension	; Skip spaces if first bit is 8 chars

	mov al, ' '
os_fat16_filename_convert_add_spaces:
	stosb
	inc rcx
	cmp rcx, 8
	jl os_fat16_filename_convert_add_spaces

os_fat16_filename_convert_do_extension:				; FIX THIS for cases where ext is less than 3 chars
	lodsb
	stosb
	lodsb
	stosb
	lodsb
	stosb
	mov byte [rdi], 0		; Zero-terminate filename
	clc				; Clear carry for success
	mov rsi, rbx			; Get the start address of the desitination string
	call os_string_uppercase	; Set it all to uppercase

os_fat16_filename_convert_done:
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	pop rsi
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
