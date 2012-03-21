; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; System Variables
; =============================================================================

align 16
db 'DEBUG: SYSVAR   '
align 16

; Constants
hextable: 		db '0123456789ABCDEF'

; Strings
system_status_header:	db 'BareMetal v0.5.3', 0
readymsg:		db 'BareMetal is ready.', 0
networkmsg:		db 'Network Address: ', 0
prompt:			db '> ', 0
space:			db ' ', 0
newline:		db 13, 0
appextension:		db '.APP', 0
memory_message:		db 'Not enough system memory for CPU stacks! System halted.', 0
startupapp:		db 'startup.app', 0
device_name_rtl8169	db 'rtl8169', 0
device_name_i8254x	db 'i8254x', 0
NIC_name_ptr		dq 0x00000000000000000	; Pointer to network interface device name
ARP_timeout		dd 0x10000000		; After this time, ARP entry must be refreshed
os_icmp_callback	dq 0x00000000000000000	; Point to ICMP reciever call back fundtion

; Memory addresses
os_ip_rx_buffer		equ 0x000000000004EC00	; 2048 bytes
os_ip_tx_buffer		equ 0x000000000006F400	; 2048 butes
arp_table		equ 0x000000000006FC00  ; 1024 bytes	0x06FC00 -> 0x06FFFF
hdbuffer0:		equ 0x0000000000070000	; 32768 bytes	0x070000 -> 0x077FFF
hdbuffer1:		equ 0x0000000000078000	; 32768 bytes	0x078000 -> 0x07FFFF
cli_temp_string:	equ 0x0000000000080000	; 1024 bytes	0x080000 -> 0x0803FF
os_temp_string:		equ 0x0000000000080400	; 1024 bytes	0x080400 -> 0x0807FF
secbuffer0:		equ 0x0000000000080800	; 512 bytes	0x080800 -> 0x0809FF
secbuffer1:		equ 0x0000000000080A00	; 512 bytes	0x080A00 -> 0x080BFF
os_args:		equ 0x0000000000080C00
os_KernelStart:		equ 0x0000000000100000	; 65536 bytes	0x100000 -> 0x10FFFF - Location of Kernel
os_SystemVariables:	equ 0x0000000000110000	; 65536 bytes	0x110000 -> 0x11FFFF - Location of System Variables
os_MemoryMap:		equ 0x0000000000120000	; 131072 bytes	0x120000 -> 0x13FFFF - Location of Memory Map - Room to map 256 GiB with 2 MiB pages
os_EthernetBuffer:	equ 0x0000000000140000	; 262144 bytes	0x140000 -> 0x17FFFF - Location of Ethernet RX Ring Buffer - Room for 170 packets
os_screen:		equ 0x0000000000180000	; 4096 bytes	80x25x2 = 4000
os_ethernet_rx_buffer:	equ 0x00000000001C0000
os_eth_rx_buffer:	equ 0x00000000001C8000
os_ethernet_tx_buffer:	equ 0x00000000001D0000
os_eth_tx_buffer:	equ 0x00000000001D8000
os_eth_temp_buffer:	equ 0x00000000001E0000
cpustatus:		equ 0x00000000001FEF00	; Location of CPU status data (256 bytes) Bit 0 = Avaiable, Bit 1 = Free/Busy
cpuqueue:		equ 0x00000000001FF000	; Location of CPU Queue. Each queue item is 16 bytes. (4KiB before the 2MiB mark, Room for 256 entries)
programlocation:	equ 0x0000000000200000	; Location in memory where programs are loaded (the start of 2MiB)

; DQ - Starting at offset 0, increments by 0x8
os_LocalAPICAddress:	equ os_SystemVariables + 0x00
os_IOAPICAddress:	equ os_SystemVariables + 0x08
os_ClockCounter:	equ os_SystemVariables + 0x10
os_RandomSeed:		equ os_SystemVariables + 0x18	; Seed for RNG
screen_cursor_offset:	equ os_SystemVariables + 0x20
hd1_maxlba:		equ os_SystemVariables + 0x28	; 64-bit value since at most it will hold a 48-bit value
os_StackBase:		equ os_SystemVariables + 0x30
os_net_transmit:	equ os_SystemVariables + 0x38
os_net_poll:		equ os_SystemVariables + 0x40
os_net_ack_int:		equ os_SystemVariables + 0x48
os_NetIOBaseMem:	equ os_SystemVariables + 0x50
os_NetMAC:		equ os_SystemVariables + 0x58
os_HPETAddress:		equ os_SystemVariables + 0x60
os_TimerCounter:	equ os_SystemVariables + 0x68

; DD - Starting at offset 128, increments by 4
cpu_speed:		equ os_SystemVariables + 128	; in MHz
hd1_size:		equ os_SystemVariables + 132	; Size in MiB
ip:			equ os_SystemVariables + 136	; IPv4 Address
sn:			equ os_SystemVariables + 140	; IPv4 Subnet
gw:			equ os_SystemVariables + 144	; IPv4 Gateway

; DW - Starting at offset 256, increments by 2
os_MemAmount:		equ os_SystemVariables + 256	; in MiB
os_NumCores:		equ os_SystemVariables + 258
cpuqueuestart:		equ os_SystemVariables + 260
cpuqueuefinish:		equ os_SystemVariables + 262
os_QueueLen:		equ os_SystemVariables + 264
os_QueueLock:		equ os_SystemVariables + 266	; Bit 0 clear for unlocked, set for locked.
os_NetIOAddress:	equ os_SystemVariables + 268
os_EthernetBusyLock:	equ os_SystemVariables + 270

; DB - Starting at offset 384, increments by 1
cursorx:		equ os_SystemVariables + 384	; cursor row location
cursory:		equ os_SystemVariables + 385	; cursor column location
scancode:		equ os_SystemVariables + 386
key:			equ os_SystemVariables + 387
key_shift:		equ os_SystemVariables + 388
screen_cursor_x:	equ os_SystemVariables + 389
screen_cursor_y:	equ os_SystemVariables + 390
hd1_enable:		equ os_SystemVariables + 391	; 1 if the drive is there and enabled
hd1_lba48:		equ os_SystemVariables + 392	; 1 if LBA48 is allowed
os_PCIEnabled:		equ os_SystemVariables + 393	; 1 if PCI is detected
os_NetEnabled:		equ os_SystemVariables + 394	; 1 if a supported network card was enabled
os_NetIRQ:		equ os_SystemVariables + 395	; Set to Interrupt line that NIC is connected to
os_NetActivity_TX:	equ os_SystemVariables + 396
os_NetActivity_RX:	equ os_SystemVariables + 397
os_EthernetBuffer_C1:	equ os_SystemVariables + 398	; Counter 1 for the Ethernet RX Ring Buffer
os_EthernetBuffer_C2:	equ os_SystemVariables + 399	; Counter 2 for the Ethernet RX Ring Buffer


cpuqueuemax:		dw 256
screen_rows: 		db 25 ; x
screen_cols: 		db 80 ; y
os_show_sysstatus:	db 1

; Function variables
os_debug_dump_reg_stage:	db 0x00

; File System
fat16_FatStart:			dd 0x00000000
fat16_TotalSectors:		dd 0x00000000
fat16_DataStart:		dd 0x00000000
fat16_RootStart:		dd 0x00000000
fat16_PartitionOffset:		dd 0x00000000
fat16_ReservedSectors:		dw 0x0000
fat16_RootDirEnts:		dw 0x0000
fat16_SectorsPerFat:		dw 0x0000
fat16_BytesPerSector:		dw 0x0000
fat16_SectorsPerCluster:	db 0x00
fat16_Fats:			db 0x00


keylayoutlower:
db 0x00, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x0e, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0x1c, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0, '`', 0, 0, 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0
keylayoutupper:
db 0x00, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0x0e, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0x1c, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 0, '~', 0, 0, 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0
; 0e = backspace
; 1c = enter

palette:		; These colors are in RGB format. Each color byte is actually 6 bits (0x00 - 0x3F)
db 0x00, 0x00, 0x00	;  0 Black
db 0x33, 0x00, 0x00	;  1 Red
db 0x0F, 0x26, 0x01	;  2 Green
db 0x0D, 0x19, 0x29	;  3 Blue
db 0x31, 0x28, 0x00	;  4 Orange
db 0x1D, 0x14, 0x1E	;  5 Purple
db 0x01, 0x26, 0x26	;  6 Teal
db 0x2A, 0x2A, 0x2A	;  7 Light Gray
db 0x15, 0x15, 0x15	;  8 Dark Gray
db 0x3B, 0x0A, 0x0A	;  9 Bright Red
db 0x22, 0x38, 0x0D	; 10 Bright Green
db 0x1C, 0x27, 0x33	; 11 Bright Blue
db 0x3F, 0x3A, 0x13	; 12 Yellow
db 0x2B, 0x1F, 0x2A	; 13 Bright Purple
db 0x0D, 0x38, 0x38	; 14 Bright Teal
db 0x3F, 0x3F, 0x3F	; 15 White


os_debug_dump_reg_string00:	db '  A:', 0
os_debug_dump_reg_string01:	db '  B:', 0
os_debug_dump_reg_string02:	db '  C:', 0
os_debug_dump_reg_string03:	db '  D:', 0
os_debug_dump_reg_string04:	db ' SI:', 0
os_debug_dump_reg_string05:	db ' DI:', 0
os_debug_dump_reg_string06:	db ' BP:', 0
os_debug_dump_reg_string07:	db ' SP:', 0
os_debug_dump_reg_string08:	db '  8:', 0
os_debug_dump_reg_string09:	db '  9:', 0
os_debug_dump_reg_string0A:	db ' 10:', 0
os_debug_dump_reg_string0B:	db ' 11:', 0
os_debug_dump_reg_string0C:	db ' 12:', 0
os_debug_dump_reg_string0D:	db ' 13:', 0
os_debug_dump_reg_string0E:	db ' 14:', 0
os_debug_dump_reg_string0F:	db ' 15:', 0
os_debug_dump_reg_string10:	db ' RF:', 0

os_debug_dump_flag_string0:	db ' C:', 0
os_debug_dump_flag_string1:	db ' Z:', 0
os_debug_dump_flag_string2:	db ' S:', 0
os_debug_dump_flag_string3:	db ' D:', 0
os_debug_dump_flag_string4:	db ' O:', 0


cli_command_string:	times 14 db 0
cli_args:		db 0

align 16
this_is_the_end:	db 'This is the end.'

;------------------------------------------------------------------------------

SYS64_CODE_SEL	equ 8		; defined by Pure64

; =============================================================================
; EOF
