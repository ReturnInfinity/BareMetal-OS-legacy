; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Include file for Bare Metal program development (API version 2.0)
; =============================================================================


b_print_string			equ 0x0000000000100010	; Displays text. IN: RSI = message location (zero-terminated string)
b_print_char			equ 0x0000000000100020	; Displays a char. IN: AL = char to display
b_input_string			equ 0x0000000000100030	; Take string from keyboard entry. IN: RDI = location where string will be stored. RCX = max chars to accept
b_input_key			equ 0x0000000000100040	; Waits for keypress and returns key. OUT: AL = key pressed
b_file_create			equ 0x0000000000100050	; Create a file on disk. IN: RSI = location of filename. RCX = number of 2MiB blocks to reserve
b_delay				equ 0x0000000000100060	; Pause for a set time. IN: RAX = Time in hundredths of a second
b_move_cursor			equ 0x0000000000100070	; Move the cursor on screen. IN: AL = column, AH = row
b_smp_reset			equ 0x0000000000100080	; Resets a CPU/Core. IN: AL = CPU #
b_smp_get_id			equ 0x0000000000100090	; Returns the APIC ID of the CPU that ran this function. OUT: RAX = CPU's APIC ID number
b_smp_enqueue			equ 0x00000000001000A0	; Add a workload to the processing queue. IN: RAX = Code to execute, RBX = Variable/Data to work on
b_smp_dequeue			equ 0x00000000001000B0	; Dequeue a workload from the processing queue. OUT: RAX = Code to execute, RBX = Variable/Data to work on
b_serial_send			equ 0x00000000001000C0	; Send a byte over the primary serial port. IN: AL = Byte to send over serial port
b_serial_recv			equ 0x00000000001000D0	; Receive a byte from the primary serial port. OUT: AL = Byte recevied, Carry flag is set if a byte was received (otherwise AL is trashed)
b_smp_queuelen			equ 0x00000000001000E0	; Returns the number of items in the processing queue. OUT: RAX = number of items in processing queue
b_smp_wait			equ 0x00000000001000F0	; Wait until all other CPU Cores are finished processing
b_file_read			equ 0x0000000000100100	; Read a file from disk into memory. IN: RSI = Address of filename string, RDI = Memory location where file will be loaded to. OUT: Carry is set if the file was not found or an error occured
b_file_write			equ 0x0000000000100110	; Write memory to a file on disk. IN: RSI = Memory location of data to be written, RDI = Address of filename string, RCX = Number of bytes to write. OUT: Carry is set if an error occured
b_file_delete			equ 0x0000000000100120	; Delete a file from disk. IN: RSI = Memory location of file name to delete. OUT: Carry is set if the file was not found or an error occured
b_file_get_list			equ 0x0000000000100130	; Generate a list of files on disk. IN: RDI = Location to store list. OUT: RDI = pointer to end of list
b_smp_run			equ 0x0000000000100140	; Call the function address in RAX. IN: RAX = Memory location of code to run
b_smp_lock			equ 0x0000000000100150	; Lock a variable. IN: RAX = Memory address of variable
b_smp_unlock			equ 0x0000000000100160	; Unlock a variable. IN: RAX = Memory address of variable
b_ethernet_tx			equ 0x0000000000100170	; Transmit a packet via Ethernet. IN: RSI = Memory location where data is stored, RDI = Pointer to 48 bit destination address, BX = Type of packet (If set to 0 then the EtherType will be set to the length of data), CX = Length of data
b_ethernet_rx			equ 0x0000000000100180	; Polls the Ethernet card for received data. IN: RDI = Memory location where packet will be stored. OUT: RCX = Length of packet
b_mem_allocate			equ 0x0000000000100190	; Allocates the requested number of 2 MiB pages. IN: RCX = Number of pages to allocate. OUT: RAX = Starting address, RCX = Number of pages allocated (Set to the value asked for or 0 on failure)
b_mem_release			equ 0x00000000001001A0	; Frees the requested number of 2 MiB pages. IN: RAX = Starting address, RCX = Number of pages to free. OUT: RCX = Number of pages freed
b_mem_get_free			equ 0x00000000001001B0	; Returns the number of 2 MiB pages that are available. OUT: RCX = Number of free 2 MiB pages
b_smp_numcores			equ 0x00000000001001C0	; Returns the number of cores in this computer. OUT: RAX = number of cores in this computer
b_file_get_size			equ 0x00000000001001D0	; Return the size of a file on disk. IN: RSI = Address of filename string. OUT: RCX = Size in bytes, Carry is set if the file was not found or an error occured
b_ethernet_avail		equ 0x00000000001001E0	; Check if Ethernet is available. IN: Nothing. OUT: RAX = Set to 1 if Ethernet is enabled on host
b_ethernet_tx_raw		equ 0x00000000001001F0	; Transmit a raw Ethernet packet. IN: RSI = Memory location of packet, CX = Length of packet.
b_show_statusbar		equ 0x0000000000100200	; Show the system status bar
b_hide_statusbar		equ 0x0000000000100210	; Hide the system status bar
b_screen_update			equ 0x0000000000100220	; Manually refresh the screen from the frame buffer
b_print_chars			equ 0x0000000000100230	; Displays text. IN: RSI = message location (A string, not zero-terminated), RCX = number of chars to print
b_print_chars_with_color	equ 0x0000000000100240	; Displays text with color. IN: RSI = message location (A string, not zero-terminated), BL = color, RCX = number of chars to print


; =============================================================================
; EOF
