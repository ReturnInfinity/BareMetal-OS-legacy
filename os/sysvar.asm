; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2016 Return Infinity -- see LICENSE.TXT
;
; System Variables
; =============================================================================

align 16
db 'DEBUG: SYSVAR   '
align 16

; Constants
hextable: 		db '0123456789ABCDEF'

; Strings
system_status_header:	db 'BareMetal v0.6.1', 0
readymsg:		db 'BareMetal is ready', 0
cpumsg:			db '[cpu: ', 0
memmsg:			db ']  [mem: ', 0
networkmsg:		db ']  [net: ', 0
diskmsg:		db ']  [hdd: ', 0
mibmsg:			db ' MiB', 0
mhzmsg:			db ' MHz', 0
coresmsg:		db ' x ', 0
namsg:			db 'N/A', 0
closebracketmsg:	db ']', 0
space:			db ' ', 0
newline:		db 13, 0
tab:			db 9, 0
memory_message:		db 'Not enough system memory for CPU stacks! System halted.', 0
startupapp:		db 'startup.app', 0

; Memory addresses
sys_idt:		equ 0x0000000000000000	; 4096 bytes	0x000000 -> 0x000FFF	Interrupt descriptor table
sys_gdt:		equ 0x0000000000001000	; 4096 bytes	0x001000 -> 0x001FFF	Global descriptor table
sys_pml4:		equ 0x0000000000002000	; 4096 bytes	0x002000 -> 0x002FFF	PML4 table
sys_pdp:		equ 0x0000000000003000	; 4096 bytes	0x003000 -> 0x003FFF	PDP table
sys_Pure64:		equ 0x0000000000004000	; 16384 bytes	0x004000 -> 0x007FFF	Pure64 system data
sys_pd:			equ 0x0000000000010000	; 262144 bytes	0x010000 -> 0x04FFFF	Page directory
ahci_cmdlist:		equ 0x0000000000070000	; 4096 bytes	0x070000 -> 0x070FFF
ahci_receivedfis:	equ 0x0000000000071000	; 4096 bytes	0x071000 -> 0x071FFF
ahci_cmdtable:		equ 0x0000000000072000	; 57344 bytes	0x072000 -> 0x07FFFF
cli_temp_string:	equ 0x0000000000080000	; 1024 bytes	0x080000 -> 0x0803FF
os_temp_string:		equ 0x0000000000080400	; 1024 bytes	0x080400 -> 0x0807FF
os_args:		equ 0x0000000000080C00
bmfs_directory:		equ 0x0000000000090000	; 4096 bytes	0x090000 -> 0x090FFF
os_filehandlers:	equ 0x0000000000091000	; 64 bytes (1x64)
os_filehandlers_seek:	equ 0x0000000000092000	; 512 bytes (8x64)
sys_ROM:		equ 0x00000000000A0000	; 393216 bytes	0x0A0000 -> 0x0FFFFF
os_KernelStart:		equ 0x0000000000100000	; 65536 bytes	0x100000 -> 0x10FFFF	Location of Kernel
os_SystemVariables:	equ 0x0000000000110000	; 65536 bytes	0x110000 -> 0x11FFFF	Location of System Variables
os_MemoryMap:		equ 0x0000000000120000	; 131072 bytes	0x120000 -> 0x13FFFF	Location of Memory Map - Room to map 256 GiB with 2 MiB pages
os_EthernetBuffer:	equ 0x0000000000140000	; 262144 bytes	0x140000 -> 0x17FFFF	Location of Ethernet RX Ring Buffer - Room for 170 packets
os_screen:		equ 0x0000000000180000	; 4096 bytes	80x25x2 = 4000
os_temp:		equ 0x0000000000190000
os_ethernet_rx_buffer:	equ 0x00000000001C0000
os_eth_rx_buffer:	equ 0x00000000001C8000
os_ethernet_tx_buffer:	equ 0x00000000001D0000
os_eth_tx_buffer:	equ 0x00000000001D8000
cpustatus:		equ 0x00000000001FEF00	; Location of CPU status data (256 bytes) Bit 0 = Available, Bit 1 = Free/Busy
cpuqueue:		equ 0x00000000001FF000	; Location of CPU Queue. Each queue item is 16 bytes. (4KiB before the 2MiB mark, Room for 256 entries)
programlocation:	equ 0x0000000000200000	; Location in memory where programs are loaded (the start of 2MiB)

; DQ - Starting at offset 0, increments by 8
os_LocalAPICAddress:	equ os_SystemVariables + 0
os_IOAPICAddress:	equ os_SystemVariables + 8
os_ClockCounter:	equ os_SystemVariables + 16
os_VideoBase:		equ os_SystemVariables + 24
screen_cursor_offset:	equ os_SystemVariables + 32
os_StackBase:		equ os_SystemVariables + 40
os_net_transmit:	equ os_SystemVariables + 48
os_net_poll:		equ os_SystemVariables + 56
os_net_ack_int:		equ os_SystemVariables + 64
os_NetIOBaseMem:	equ os_SystemVariables + 72
os_NetMAC:		equ os_SystemVariables + 80
os_HPETAddress:		equ os_SystemVariables + 88
ahci_base:		equ os_SystemVariables + 96
os_NetworkCallback:	equ os_SystemVariables + 104
bmfs_TotalBlocks:	equ os_SystemVariables + 112
os_KeyboardCallback:	equ os_SystemVariables + 120
os_ClockCallback:	equ os_SystemVariables + 128
os_net_TXBytes:		equ os_SystemVariables + 136
os_net_TXPackets:	equ os_SystemVariables + 144
os_net_RXBytes:		equ os_SystemVariables + 152
os_net_RXPackets:	equ os_SystemVariables + 160
os_hdd_BytesRead:	equ os_SystemVariables + 168
os_hdd_BytesWrite:	equ os_SystemVariables + 176

; DD - Starting at offset 256, increments by 4
cpu_speed:		equ os_SystemVariables + 256	; in MHz
os_HPETRate:		equ os_SystemVariables + 260
os_MemAmount:		equ os_SystemVariables + 264	; in MiB
ahci_port:		equ os_SystemVariables + 268
hd1_size:		equ os_SystemVariables + 272	; in MiB
os_Screen_Pixels:	equ os_SystemVariables + 276
os_Screen_Bytes:	equ os_SystemVariables + 280
os_Screen_Row_2:	equ os_SystemVariables + 284
os_Font_Color:		equ os_SystemVariables + 288

; DW - Starting at offset 512, increments by 2
os_NumCores:		equ os_SystemVariables + 512
cpuqueuestart:		equ os_SystemVariables + 514
cpuqueuefinish:		equ os_SystemVariables + 516
os_QueueLen:		equ os_SystemVariables + 518
os_QueueLock:		equ os_SystemVariables + 520	; Bit 0 clear for unlocked, set for locked.
os_NetIOAddress:	equ os_SystemVariables + 522
os_EthernetBusyLock:	equ os_SystemVariables + 524
os_VideoX:		equ os_SystemVariables + 526
os_VideoY:		equ os_SystemVariables + 528
os_Screen_Rows:		equ os_SystemVariables + 530
os_Screen_Cols:		equ os_SystemVariables + 532
os_Screen_Cursor_Row:	equ os_SystemVariables + 534
os_Screen_Cursor_Col:	equ os_SystemVariables + 536

; DB - Starting at offset 768, increments by 1
cursorx:		equ os_SystemVariables + 768	; cursor row location
cursory:		equ os_SystemVariables + 769	; cursor column location
scancode:		equ os_SystemVariables + 770
key:			equ os_SystemVariables + 771
key_shift:		equ os_SystemVariables + 772
screen_cursor_x:	equ os_SystemVariables + 773
screen_cursor_y:	equ os_SystemVariables + 774
os_PCIEnabled:		equ os_SystemVariables + 775	; 1 if PCI is detected
os_NetEnabled:		equ os_SystemVariables + 776	; 1 if a supported network card was enabled
os_NetIRQ:		equ os_SystemVariables + 778	; Set to Interrupt line that NIC is connected to
os_NetActivity_TX:	equ os_SystemVariables + 779
os_NetActivity_RX:	equ os_SystemVariables + 780
os_EthernetBuffer_C1:	equ os_SystemVariables + 781	; Counter 1 for the Ethernet RX Ring Buffer
os_EthernetBuffer_C2:	equ os_SystemVariables + 782	; Counter 2 for the Ethernet RX Ring Buffer
os_DiskEnabled:		equ os_SystemVariables + 783
os_DiskActivity:	equ os_SystemVariables + 784
app_argc:		equ os_SystemVariables + 785
os_VideoDepth:		equ os_SystemVariables + 786
os_VideoEnabled:	equ os_SystemVariables + 787

cpuqueuemax:		dw 256
screen_rows: 		db 25 ; x
screen_cols: 		db 80 ; y

; Function variables
os_debug_dump_reg_stage:	db 0x00

; File System
; Define the structure of a directory entry
struc	BMFS_DirEnt
	.filename	resb 32
	.start		resq 1	; starting block index
	.reserved	resq 1	; number of blocks reserved
	.size		resq 1	; number of bytes
	.unused		resq 1
endstruc

keylayoutlower:
db 0x00, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0x0e, 0, 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0x1c, 0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', 0x27, '`', 0, '\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, 0, 0, ' ', 0
keylayoutupper:
db 0x00, 0, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 0x0e, 0, 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 0x1c, 0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', 0x22, '~', 0, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0, 0, 0, ' ', 0
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


align 16
this_is_the_end:	db 'This is the end.'

;------------------------------------------------------------------------------

SYS64_CODE_SEL	equ 8		; defined by Pure64

; =============================================================================
; EOF
