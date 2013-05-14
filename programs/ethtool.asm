; -----------------------------------------------------------------
; EthTool v0.1 - Ethernet debugging tool
; Ian Seyler @ Return Infinity
; -----------------------------------------------------------------


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

ethtool:

	mov rsi, startstring
	call b_output

ethtool_command:
	call b_input_key
	or al, 00100000b			; Convert character to lowercase if it is not already

	cmp al, 's'
	je ethtool_send
	cmp al, 'r'
	je ethtool_receive
	cmp al, 'q'
	je ethtool_finish
	jmp ethtool_command			; Didn't get any key we were expecting so try again.

ethtool_finish:
	mov rsi, endstring
	call b_output
	ret					; Back to OS

ethtool_send:
	mov rsi, sendstring
	call b_output
	mov rsi, packet
	mov rcx, 1522
	call b_ethernet_tx
	mov rsi, sentstring
	call b_output
	jmp ethtool_command
	
ethtool_receive:
	mov rsi, receivestring
	call b_output
	mov rdi, EthernetBuffer
	call b_ethernet_rx
	cmp rcx, 0
	je ethtool_receive_nopacket
	mov rsi, receiveddata
	call b_output
	mov rsi, EthernetBuffer
	mov rdx, 4
	call b_system_misc
	jmp ethtool_command

ethtool_receive_nopacket:
	mov rsi, receivednothingstring
	call b_output
	jmp ethtool_command

; -----------------------------------------------------------------

startstring: db 'EthTool: S to send a packet, R to recieve a packet, Q to quit.', 0
endstring: db 13, 0
sendstring: db 13, 'Sending packet, ', 0
sentstring: db 'Sent', 0
receivestring: db 13, 'Receiving packet, ', 0
receivednothingstring: db 'Nothing there', 0
receiveddata: db 'Data received', 13, 0
packet:
destination: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
source: db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
ethertype: db 0xAB, 0xBA
EthernetBuffer: db 0