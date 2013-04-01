# BareMetal OS API #

Version 0.6.0


## Output ##

    b_output
Output text to the screen (The string must be null-terminated)

	b_output_chars
Output a number of characters to the screen


## Input ##

	os_input
Accept a number of keys from the keyboard. The resulting string will automatically be null-terminated

	os_input_key
Scans keyboard for input


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
