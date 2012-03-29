; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2011 Return Infinity -- see LICENSE.TXT
;
; Include file for Bare Metal program development (API version 2.0)
; =============================================================================


b_print_string			equ 0x0000000000100010	; Displays text. IN: RSI = message location (zero-terminated string)
b_print_char			equ 0x0000000000100020	; Displays a char. IN: AL = char to display
b_print_char_hex		equ 0x0000000000100030	; Displays a char in hex mode. IN: AL = char to display
b_print_newline			equ 0x0000000000100040	; Print a new line
b_input_key_check		equ 0x0000000000100050	; Scans keyboard for input, but doesn't wait. OUT: AL = ASCII code or 0 if no key pressed
b_input_key_wait		equ 0x0000000000100060	; Waits for keypress and returns key. OUT: AL = key pressed
b_input_string			equ 0x0000000000100070	; Take string from keyboard entry. IN: RDI = location where string will be stored. RCX = max chars to accept
b_delay				equ 0x0000000000100080	; Pause for a set time. IN: RAX = Time in hundredths of a second
b_speaker_tone			equ 0x0000000000100090	; Generate PC speaker tone (call b_speaker_off after). IN: RAX = note frequency
b_speaker_off			equ 0x00000000001000A0	; Shut off the PC speaker
b_speaker_beep			equ 0x00000000001000B0	; Play a standard beep noise
b_move_cursor			equ 0x00000000001000C0	; Move the cursor on screen. IN: AL = column, AH = row
b_string_length			equ 0x00000000001000D0	; Return the length of a string. IN: RSI = string address. OUT: RCX = string length
b_find_char_in_string		equ 0x00000000001000E0	; Find first location of character in a string. IN: RSI = string location, AL = character to find. OUT: RAX = location in string, or 0 if char not present
b_string_copy			equ 0x00000000001000F0	; Copy the contents of one string into another. IN: RSI = source, RDI = destination
b_string_truncate		equ 0x0000000000100100	; Chop string down to specified number of characters. IN: RSI = string location, RAX = number of characters
b_string_join			equ 0x0000000000100110	; Join two strings into a third string. IN: RAX = string one, RBX = string two, RDI = destination string
b_string_chomp			equ 0x0000000000100120	; Strip leading and trailing spaces from a string. IN: RSI = string location
b_string_strip			equ 0x0000000000100130	; Removes specified character from a string. IN: RSI = string location, AL = character to remove
b_string_compare		equ 0x0000000000100140	; See if two strings match. IN: RSI = string one, RDI = string two. OUT: Carry flag set if same
b_string_uppercase		equ 0x0000000000100150	; Convert a string to all uppercase characters. IN: RSI = string address
b_string_lowercase		equ 0x0000000000100160	; Convert a string to all lowercase characters. IN: RSI = string address
b_int_to_string			equ 0x0000000000100170	; Convert an integer to a string. IN: RAX = interger. OUT: RDI = destination string
b_string_to_int			equ 0x0000000000100180	; Convert a string to an interger. IN: RSI = source string. OUT: RAX = interger
b_debug_dump_reg		equ 0x0000000000100190	; Dump the registers to the screen
b_debug_dump_mem		equ 0x00000000001001A0	; Dump contents of memory to the screen. IN: RSI = Start of memory address to dump, RCX = number of bytes to dump
b_debug_dump_rax		equ 0x00000000001001B0	; Dump the content of RAX (64-bit) to the screen
b_debug_dump_eax		equ 0x00000000001001C0	; Dump the content of EAX (32-bit) to the screen
b_debug_dump_ax			equ 0x00000000001001D0	; Dump the content of AX (16-bit) to the screen
b_debug_dump_al			equ 0x00000000001001E0	; Dump the content of AL (8-bit) to the screen
b_smp_reset			equ 0x00000000001001F0	; Resets a CPU/Core. IN: AL = CPU #
b_smp_get_id			equ 0x0000000000100200	; Returns the APIC ID of the CPU that ran this function. OUT: RAX = CPU's APIC ID number
b_smp_enqueue			equ 0x0000000000100210	; Add a workload to the processing queue. IN: RAX = Code to execute, RBX = Variable/Data to work on
b_smp_dequeue			equ 0x0000000000100220	; Dequeue a workload from the processing queue. OUT: RAX = Code to execute, RBX = Variable/Data to work on
b_serial_send			equ 0x0000000000100230	; Send a byte over the primary serial port. IN: AL = Byte to send over serial port
b_serial_recv			equ 0x0000000000100240	; Receive a byte from the primary serial port. OUT: AL = Byte recevied, Carry flag is set if a byte was received (otherwise AL is trashed)
b_string_parse			equ 0x0000000000100250	; Parse a string into individual words. IN: RSI = Address of string. OUT: RCX = word count
b_get_argc			equ 0x0000000000100260	; Return the number arguments passed to the program. OUT: AL = Number of arguments
b_get_argv			equ 0x0000000000100270	; Get the value of an argument that was passed to the program. IN: AL = Argument number. OUT: RSI = Start of numbered argument string
b_smp_queuelen			equ 0x0000000000100280	; Returns the number of items in the processing queue. OUT: RAX = number of items in processing queue
b_smp_wait			equ 0x0000000000100290	; Wait until all other CPU Cores are finished processing
b_get_timecounter		equ 0x00000000001002A0	; Get the current RTC clock couter value. OUT: RAX = Time in eights of a second since clock started
b_string_append			equ 0x00000000001002B0	; Append a string to an existing string. IN: RSI = String to be appended, RDI = Destination string
b_int_to_hex_string		equ 0x00000000001002C0	; Convert an integer to a hex string. IN: RAX = Integer value. RDI = location to store string
b_hex_string_to_int		equ 0x00000000001002D0	; Convert up to 8 hexascii to bin. IN: RSI = Location of hex asciiz string. OUT: RAX = binary value of hex string
b_string_change_char		equ 0x00000000001002E0	; Change all instances of a character in a string. IN: RSI = string location, AL = character to replace, BL = replacement character
b_is_digit			equ 0x00000000001002F0	; Check if character is a digit. IN: AL = ASCII char. OUT: EQ flag set if numeric
b_is_alpha			equ 0x0000000000100300	; Check if character is a letter. IN: AL = ASCII char. OUT: EQ flag set if alpha
b_file_read			equ 0x0000000000100310	; Read a file from disk into memory. IN: RSI = Address of filename string, RDI = Memory location where file will be loaded to. OUT: Carry is set if the file was not found or an error occured
b_file_write			equ 0x0000000000100320	; Write memory to a file on disk. IN: RSI = Memory location of data to be written, RDI = Address of filename string, RCX = Number of bytes to write. OUT: Carry is set if an error occured
b_file_delete			equ 0x0000000000100330	; Delete a file from disk. IN: RSI = Memory location of file name to delete. OUT: Carry is set if the file was not found or an error occured
b_file_get_list			equ 0x0000000000100340	; Generate a list of files on disk. IN: RDI = Location to store list. OUT: RDI = pointer to end of list
b_smp_run			equ 0x0000000000100350	; Call the function address in RAX. IN: RAX = Memory location of code to run
b_smp_lock			equ 0x0000000000100360	; Lock a variable. IN: RAX = Memory address of variable
b_smp_unlock			equ 0x0000000000100370	; Unlock a variable. IN: RAX = Memory address of variable
b_print_string_with_color	equ 0x0000000000100380	; Displays text in colour. IN: RSI = message location (zero-terminated string), BL = colour
b_print_char_with_color		equ 0x0000000000100390	; Displays a char in colour. IN: AL = char to display, BL = colour
b_ethernet_tx			equ 0x00000000001003A0	; Transmit a packet via Ethernet. IN: RSI = Memory location where data is stored, RDI = Pointer to 48 bit destination address, BX = Type of packet (If set to 0 then the EtherType will be set to the length of data), CX = Length of data
b_ethernet_rx			equ 0x00000000001003B0	; Polls the Ethernet card for received data. IN: RDI = Memory location where packet will be stored. OUT: RCX = Length of packet
b_mem_allocate			equ 0x00000000001003C0	; Allocates the requested number of 2 MiB pages. IN: RCX = Number of pages to allocate. OUT: RAX = Starting address, RCX = Number of pages allocated (Set to the value asked for or 0 on failure)
b_mem_release			equ 0x00000000001003D0	; Frees the requested number of 2 MiB pages. IN: RAX = Starting address, RCX = Number of pages to free. OUT: RCX = Number of pages freed
b_mem_get_free			equ 0x00000000001003E0	; Returns the number of 2 MiB pages that are available. OUT: RCX = Number of free 2 MiB pages
b_smp_numcores			equ 0x00000000001003F0	; Returns the number of cores in this computer. OUT: RAX = number of cores in this computer
b_file_get_size			equ 0x0000000000100400	; Return the size of a file on disk. IN: RSI = Address of filename string. OUT: RCX = Size in bytes, Carry is set if the file was not found or an error occured
b_ethernet_avail		equ 0x0000000000100410	; Check if Ethernet is available. IN: Nothing. OUT: RAX = Set to 1 if Ethernet is enabled on host
b_print_char_hex_with_color	equ 0x0000000000100420	; Displays a char in hex mode with color. IN: AL = char to display, BL = colour
b_screen_clear			equ 0x0000000000100440	; Clear the screen
b_show_cursor			equ 0x0000000000100450	; Turns on cursor in text mode
b_hide_cursor			equ 0x0000000000100460	; Turns off cursor in text mode
b_show_statusbar		equ 0x0000000000100470	; Show the system status bar
b_hide_statusbar		equ 0x0000000000100480	; Hide the system status bar
b_screen_update			equ 0x0000000000100490	; Manually refresh the screen from the frame buffer
b_print_chars			equ 0x00000000001004A0	; Displays text. IN: RSI = message location (A string, not zero-terminated), RCX = number of chars to print
b_print_chars_with_color	equ 0x00000000001004B0	; Displays text with color. IN: RSI = message location (A string, not zero-terminated), BL = color, RCX = number of chars to print
os_arp_request			equ 0x00000000001004C0	;
os_get_ethernet_driver		equ 0x00000000001004D0	;
b_get_ip_config			equ 0x00000000001004E0	;
b_set_ip_config			equ 0x00000000001004F0	;
b_parse_ip_addr			equ 0x0000000000100500	;
b_ip_addr_to_str		equ 0x0000000000100510	;
b_get_mac_addr			equ 0x0000000000100520	;
b_mac_addr_to_str		equ 0x0000000000100530	;
b_byte_to_hex_string		equ 0x0000000000100540	;
b_get_arp_table			equ 0x0000000000100550	;
b_icmp_send_request		equ 0x0000000000100560	;


; =============================================================================
; EOF
