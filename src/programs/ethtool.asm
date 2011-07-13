; -----------------------------------------------------------------
; EthTool v0.1 - Ethernet debugging tool
; Ian Seyler @ Return Infinity
; -----------------------------------------------------------------


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

ethtool:

	mov rsi, startstring
	call b_print_string

ethtool_command:
	call b_input_key_wait
	or al, 00100000b			; Convert character to lowercase if it is not already

	cmp al, 's'
	je ethtool_send
	cmp al, 'r'
	je ethtool_receive
	cmp al, 'q'
	je ethtool_finish
	jmp ethtool_command			; Didn't get any key we were expecting so try again.

ethtool_finish:
	call b_print_newline
	ret					; Back to OS

ethtool_send:
	mov rsi, sendstring
	call b_print_string
	mov rdi, broadcastaddress
	mov rsi, startstring
	mov rbx, 0xABBA
	mov rcx, 63
	call b_ethernet_tx
	mov rsi, sentstring
	call b_print_string
	jmp ethtool_command
	
ethtool_receive:
	mov rsi, receivestring
	call b_print_string
	mov rdi, EthernetBuffer
	call b_ethernet_rx
	cmp rcx, 0
	je ethtool_receive_nopacket
	mov rsi, receiveddata
	call b_print_string
	mov rsi, EthernetBuffer
	call b_debug_dump_mem
	jmp ethtool_command

ethtool_receive_nopacket:
	mov rsi, receivednothingstring
	call b_print_string
	jmp ethtool_command

; -----------------------------------------------------------------

startstring: db 'EthTool: S to send a packet, R to recieve a packet, Q to quit.', 0
sendstring: db 13, 'Sending packet, ', 0
sentstring: db 'Sent', 0
receivestring: db 13, 'Receiving packet, ', 0
receivednothingstring: db 'Nothing there', 0
receiveddata: db 'Data received', 13, 0
broadcastaddress: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0
EthernetBuffer: db 0