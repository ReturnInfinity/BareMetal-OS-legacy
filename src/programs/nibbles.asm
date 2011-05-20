; The classic game of Nibbles
; Written by Ian Seyler
;
; BareMetal compile:
; nasm argtest.asm -o argtest.app

; Game field is surrounded by a border. Play area is 38 x 23

[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

start:					; Start of program label
	call b_hide_statusbar
	call b_hide_cursor
	call b_screen_clear

	mov rdi, os_screen		; Screen framebuffer

	mov eax, 0x15DB15DB
	mov rcx, 41
	rep stosd			; Draw the top wall

	mov rcx, 23
nextside:				; Draw the side walls
	add rdi, 152
	stosd
	stosd
	sub rcx, 1
	cmp rcx, 0
	jne nextside

	mov rcx, 39
	rep stosd			; Draw the bottom wall

	call b_screen_update		; Copy the screen buffer to video memory
	


gameloop:
	cmp byte [direction], 1
	je move_up
	cmp byte [direction], 2
	je move_right
	cmp byte [direction], 3
	je move_down
	cmp byte [direction], 4
	je move_left
	jmp fin				; Fatal error

move_up:
	sub byte [head_x], 1
	jmp drawworm
move_right:
	add byte [head_y], 1
	jmp drawworm
move_down:
	add byte [head_x], 1
	jmp drawworm
move_left:
	sub byte [head_y], 1
	jmp drawworm

drawworm:
	mov rax, 1
	call b_delay
	mov ah, byte [head_y]
	shl ah, 1
	mov al, byte [head_x]
	call b_move_cursor
	mov al, 219
	call b_print_char
	call b_print_char
	call b_input_key_check
	cmp al, 'w'
	je go_up
	cmp al, 'a'
	je go_left
	cmp al, 's'
	je go_down
	cmp al, 'd'
	je go_right
	cmp al, 'q'
	je fin
	jmp gameloop

go_up:
	mov byte [direction], 1
	jmp gameloop

go_left:
	mov byte [direction], 4
	jmp gameloop

go_down:
	mov byte [direction], 3
	jmp gameloop

go_right:
	mov byte [direction], 2
	jmp gameloop

fin:
	call b_screen_clear
	mov ax, 0x0018			; Set the hardware cursor to the bottom left-hand corner
	call b_move_cursor
	call b_show_cursor
	call b_show_statusbar
	ret				; Return to OS

head_x: 	db 5
head_y: 	db 5
direction:	db 2			; 1 up, 2 right, 3 down, 4 left 

os_screen:	equ 0x0000000000180000	; This is the address for the text screen frame buffer. It gets copied to video memory via b_update_screen
