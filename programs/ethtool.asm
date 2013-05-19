; -----------------------------------------------------------------------------
; EthTool - Ethernet debugging tool (v1.0, May 14 2013)
; Ian Seyler @ Return Infinity
;
; 's' to broadcast a packet
; 'q' to quit
;
; A network callback is installed to deal with packets the moment they are
; received. This callback is run by the network interrupt.
;
; BareMetal compile:
; nasm ethtool.asm -o ethtool.app
; -----------------------------------------------------------------------------


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:

	mov rsi, startstring
	call [b_output]
	; Configure the network callback
	mov rax, ethtool_receive
	mov rdx, networkcallback_set
	call [b_system_config]

ethtool_command:
	call [b_input_key]
	or al, 00100000b			; Convert character to lowercase if it is not already

	cmp al, 's'
	je ethtool_send
	cmp al, 'q'
	je ethtool_finish
	jmp ethtool_command			; Didn't get any key we were expecting so try again.

ethtool_finish:
	mov rsi, endstring
	call [b_output]
	; Clear the network callback
	mov rax, 0
	mov rdx, networkcallback_set
	call [b_system_config]
	ret					; Back to OS

ethtool_send:
	mov rsi, sendstring
	call [b_output]
	mov rsi, packet
	mov rcx, 1522
	call [b_ethernet_tx]
	mov rsi, sentstring
	call [b_output]
	jmp ethtool_command
	
ethtool_receive:
	mov rsi, receivestring
	call [b_output]
	mov rdi, EthernetBuffer
	call [b_ethernet_rx]
	mov rsi, EthernetBuffer
	mov rdx, 4
	call [b_system_misc]
	ret


; -----------------------------------------------------------------

startstring: db 'EthTool: S to send a packet, Q to quit.', 13, 'Received packets will display automatically.', 0
endstring: db 13, 0
sendstring: db 13, 'Sending packet, ', 0
sentstring: db 'Sent', 0
receivestring: db 13, 'Received packet', 13, 0
packet:
destination: db 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
source: db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
ethertype: db 0xAB, 0xBA
EthernetBuffer: db 0