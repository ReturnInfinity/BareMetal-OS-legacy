# BareMetal OS API #

Version 0.6.0


## Output ##

**b_output**

Output text to the screen (The string must be null-terminated)

Assembly Registers:

	 IN:	RSI = message location (zero-terminated string)
	OUT:	All registers preserved

Assembly Example:

	mov rsi, Message
	call b_output
	...
	Message: db 'This is a test', 0

C/C++ Example:

	char Message[] = "This is a test";
	b_output(Message);
	...
	b_output("This is a another test");


**b_output_chars**

Output a number of characters to the screen

Assembly Registers:

	 IN:	RSI = message location
			RCX = number of characters to output
	OUT:	All registers preserved

Assembly Example:

	mov rsi, Message
	mov rcx, 4
	call os_output_chars					; Only output the word 'This'
	...
	Message: db 'This is a test', 0

C/C++ Example:

	b_output_chars("This is a test", 4);	// Output 'This'


## Input ##

**os_input**

Accept a number of keys from the keyboard. The resulting string will automatically be null-terminated

Assembly Registers:

	 IN:	RDI = location where string will be stored
			RCX = number of characters to accept
	OUT:	RCX = length of string that were input (NULL not counted)
			All other registers preserved

Assembly Example:

	mov rdi, Input
	mov rcx, 20
	call b_input
	...
	Input: db 0 times 21

C/C++ Example:

	char Input[21];
	b_input(Input, 20);


**os_input_key**

Scans keyboard for input

Assembly Registers:

	 IN:	Nothing
	OUT:	AL = 0 if no key pressed, otherwise ASCII code, other regs preserved
			All other registers preserved

Assembly Example:

	call b_input_key
	mov byte [KeyChar], al
	...
	KeyChar: db 0

C/C++ Example:

	char KeyChar;
	KeyChar = b_input_key


## SMP ##

	b_smp_enqueue
Add a workload to the processing queue

	b_smp_dequeue
Dequeue a workload from the processing queue

	b_smp_run
Call the code address stored in RAX

	b_smp_wait
Wait until all other CPU Cores are finished processing


## Memory ##

	os_mem_allocate
Allocate pages of memory

	os_mem_release
Release pages of memory


## Network ##

	b_ethernet_tx
Send data via Ethernet


	b_ethernet_rx
Receive data via Ethernet


## File ##

	b_file_read
Read a file from disk into memory

	b_file_write
Write a file from memory to disk

	b_file_create
Create a file on disk

	b_file_delete
Delete a file from disk

	b_file_query
Query the existence of a file

	b_file_list
Generate a list of files on disk


## Misc ##

	b_system_config
A grab-bag of useful functions
