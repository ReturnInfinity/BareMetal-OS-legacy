; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2013 Return Infinity -- see LICENSE.TXT
;
; Include file for Bare Metal program development (API version 2.0)
; =============================================================================


b_output		equ 0x0000000000100010	; Displays text. IN: RSI = message location (zero-terminated string)
b_output_chars		equ 0x0000000000100018	; Displays a number of characters. IN: RSI = message location, RCX = number of characters

b_input			equ 0x0000000000100020	; Take string from keyboard entry. IN: RDI = location where string will be stored. RCX = max chars to accept
b_input_key		equ 0x0000000000100028	; Scans keyboard for input. OUT: AL = 0 if no key pressed, otherwise ASCII code

b_smp_enqueue		equ 0x0000000000100030	; Add a workload to the processing queue. IN: RAX = Code to execute, RSI = Variable/Data to work on
b_smp_dequeue		equ 0x0000000000100038	; Dequeue a workload from the processing queue. OUT: RAX = Code to execute, RDI = Variable/Data to work on
b_smp_run		equ 0x0000000000100040	; Call the function address in RAX. IN: RAX = Memory location of code to run
b_smp_wait		equ 0x0000000000100048	; Wait until all other CPU Cores are finished processing.

b_mem_allocate		equ 0x0000000000100050	; Allocates the requested number of 2 MiB pages. IN: RCX = Number of pages to allocate. OUT: RAX = Starting address, RCX = Number of pages allocated (Set to the value asked for or 0 on failure)
b_mem_release		equ 0x0000000000100058	; Frees the requested number of 2 MiB pages. IN: RAX = Starting address, RCX = Number of pages to free. OUT: RCX = Number of pages freed

b_ethernet_tx		equ 0x0000000000100060	; Transmit a packet via Ethernet. IN: RSI = Memory location where data is stored, RDI = Pointer to 48 bit destination address, BX = Type of packet (If set to 0 then the EtherType will be set to the length of data), CX = Length of data
b_ethernet_rx		equ 0x0000000000100068	; Polls the Ethernet card for received data. IN: RDI = Memory location where packet will be stored. OUT: RCX = Length of packet

b_file_open		equ 0x0000000000100070	; Open a file for read/write access. IN: RSI = File name. OUT: RAX = File handle ID
b_file_close		equ 0x0000000000100078	; Close a file. IN: RAX = File handle ID
b_file_read		equ 0x0000000000100080	; Read a file from disk into memory. IN: RAX = File handle ID, RDI = Memory location where file will be loaded to, RCX = Number of bytes to read. OUT: Carry is set if the file was not found or an error occured
b_file_write		equ 0x0000000000100088	; Write memory to a file on disk. IN: RAX = File handle ID, RSI = Memory location of data to be written, RCX = Number of bytes to write. OUT: Carry is set if an error occured
b_file_seek		equ 0x0000000000100090	; Generate a list of files on disk. IN: RDI = Location to store list. OUT: RDI = pointer to end of list
b_file_query		equ 0x0000000000100098	; Query the existence of a file. IN: RSI = location of filename. OUT: RCX = Size in bytes, Carry set if file not found
b_file_create		equ 0x00000000001000A0	; Create a file on disk. IN: RSI = location of filename, RCX = number of 2MiB blocks to reserve
b_file_delete		equ 0x00000000001000A8	; Delete a file from disk. IN: RSI = Memory location of file name to delete. OUT: Carry is set if the file was not found or an error occured

b_system_config		equ 0x00000000001000B0	; View/modify system configuration. IN: RDX = Function #, RAX = Variable. OUT: RAX = Result
b_system_misc		equ 0x00000000001000B8	; Call a misc system function. IN: RDX = Function #, RAX = Variable 1, RCX = Variable 2. Out: RAX = Result 1, RCX = Result 2


; Index for b_system_config calls
timecounter		equ 0
networkcallback_get	equ 1
networkcallback_set	equ 2
statusbar_hide		equ 10
statusbar_show		equ 11


; Index for b_system_misc calls
smp_get_id		equ 1
smp_lock		equ 2
smp_unlock		equ 3
debug_dump_mem		equ 4
debug_dump_rax		equ 5
get_argc		equ 6
get_argv		equ 7


; =============================================================================
; EOF
