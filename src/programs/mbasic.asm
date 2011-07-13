; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2011 MikeOS Developers -- see doc/LICENSE.TXT
;
; BASIC CODE INTERPRETER
; ==================================================================


[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

; ------------------------------------------------------------------
; Token types

%DEFINE VARIABLE 1
%DEFINE STRING_VAR 2
%DEFINE NUMBER 3
%DEFINE STRING 4
%DEFINE QUOTE 5
%DEFINE CHAR 6
%DEFINE UNKNOWN 7
%DEFINE LABEL 8


; ------------------------------------------------------------------
; The BASIC interpreter execution starts here...

b_run_basic:
	mov [orig_stack], rsp		; Save stack pointer -- we might jump to the
						; error printing code and quit in the middle
						; some nested loops, and we want to preserve
						; the stack
	mov rax, basic_prog			;embedded test program for a quick DOS test
	mov rbx, 8192				;default size for test program (not critical)
	mov [load_point], rax		; rax was passed as starting location of code

	mov [prog], rax			; prog = pointer to current execution point in code

	add rbx, rax				; We were passed the .BAS byte size in rbx
	sub rbx, 2
	mov [prog_end], rbx			; Make note of program end point


	call clear_ram				; Clear variables etc. from previous run
						; of a BASIC program



mainloop:
	call get_token				; Get a token from the start of the line

	cmp rax, STRING				; Is the type a string of characters?
	je .keyword				; If so, let's see if it's a keyword to process

	cmp rax, VARIABLE			; If it's a variable at the start of the line,
	je near assign				; this is an assign (eg "X = Y + 5")

	cmp rax, STRING_VAR			; Same for a string variable (eg $1)
	je near assign

	cmp rax, LABEL				; Don't need to do anything here - skip
	je mainloop

	mov rsi, err_syntax			; Otherwise show an error and quit
	jmp error


.keyword:
	mov rsi, token				; Start trying to match commands

	mov rdi, alert_cmd
	call b_string_compare
	jc near do_alert

	mov rdi, call_cmd
	call b_string_compare
	jc near do_call

	mov rdi, cls_cmd
	call b_string_compare
	jc near do_cls

	mov rdi, cursor_cmd
	call b_string_compare
	jc near do_cursor

	mov rdi, curschar_cmd
	call b_string_compare
	jc near do_curschar

	mov rdi, end_cmd
	call b_string_compare
	jc near do_end

	mov rdi, for_cmd
	call b_string_compare
	jc near do_for

	mov rdi, getkey_cmd
	call b_string_compare
	jc near do_getkey

	mov rdi, gosub_cmd
	call b_string_compare
	jc near do_gosub

	mov rdi, goto_cmd
	call b_string_compare
	jc near do_goto

	mov rdi, input_cmd
	call b_string_compare
	jc near do_input

	mov rdi, if_cmd
	call b_string_compare
	jc near do_if

	mov rdi, load_cmd
	call b_string_compare
	jc near do_load

	mov rdi, move_cmd
	call b_string_compare
	jc near do_move

	mov rdi, next_cmd
	call b_string_compare
	jc near do_next

	mov rdi, pause_cmd
	call b_string_compare
	jc near do_pause

	mov rdi, peek_cmd
	call b_string_compare
	jc near do_peek

	mov rdi, poke_cmd
	call b_string_compare
	jc near do_poke

	mov rdi, port_cmd
	call b_string_compare
	jc near do_port

	mov rdi, print_cmd
	call b_string_compare
	jc near do_print

	mov rdi, rand_cmd
	call b_string_compare
	jc near do_rand

	mov rdi, rem_cmd
	call b_string_compare
	jc near do_rem

	mov rdi, return_cmd
	call b_string_compare
	jc near do_return

	mov rdi, save_cmd
	call b_string_compare
	jc near do_save

	mov rdi, serial_cmd
	call b_string_compare
	jc near do_serial

	mov rdi, sound_cmd
	call b_string_compare
	jc near do_sound

	mov rdi, waitkey_cmd
	call b_string_compare
	jc near do_waitkey

	mov rsi, err_cmd_unknown			; Command not found?
	jmp error


; ------------------------------------------------------------------
; CLEAR RAM

clear_ram:
	xor eax, eax

	mov rdi, variables
	mov rcx, 52
	rep stosb

	mov rdi, for_variables
	mov rcx, 52
	rep stosb

	mov rdi, for_code_points
	mov rcx, 52
	rep stosb

	mov byte [gosub_depth], 0

	mov rdi, gosub_points
	mov rcx, 20
	rep stosb

	mov rdi, string_vars
	mov rcx, 1024
	rep stosb

	ret


; ------------------------------------------------------------------
; ASSIGNMENT

assign:
	cmp rax, VARIABLE			; Are we starting with a number var?
	je .do_num_var

	mov rdi, string_vars			; Otherwise it's a string var
	mov rax, 128
	mul rbx					; (rbx = string number, passed back from get_token)
	add rdi, rax

	push rdi

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp rax, QUOTE
	je .second_is_quote

	cmp rax, STRING_VAR
	jne near .error

	mov rsi, string_vars			; Otherwise it's a string var
	mov rax, 128
	mul rbx					; (rbx = string number, passed back from get_token)
	add rsi, rax

	pop rdi
	call b_string_copy

	jmp mainloop


.second_is_quote:
	mov rsi, token
	pop rdi
	call b_string_copy

	jmp mainloop


.do_num_var:
	xor rax, rax
	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp rax, NUMBER
	je .second_is_num

	cmp rax, VARIABLE
	je .second_is_variable

	cmp rax, STRING
	je near .second_is_string

	cmp rax, UNKNOWN
	jne near .error

	mov byte al, [token]			; Address of string var?
	cmp al, '&'
	jne near .error

	call get_token				; Let's see if there's a string var
	cmp rax, STRING_VAR
	jne near .error

	mov rdi, string_vars
	mov rax, 128
	mul rbx
	add rdi, rax

	mov rbx, rdi

	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.second_is_variable:
	xor rax, rax
	mov byte al, [token]

	call get_var
	mov rbx, rax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_num:
	mov rsi, token
	call b_string_to_int

	mov rbx, rax				; Number to insert in variable table

	xor rax, rax
	mov byte al, [.tmp]

	call set_var


	; The assignment could be simply "X = 5" etc. Or it could be
	; "X = Y + 5" -- ie more complicated. So here we check to see if
	; there's a delimiter...

.check_for_more:
	mov rax, [prog]			; Save code location in case there's no delimiter
	mov [.tmp_loc], rax

	call get_token				; Any more to deal with in this assignment?
	mov byte al, [token]
	cmp al, '+'
	je .theres_more
	cmp al, '-'
	je .theres_more
	cmp al, '*'
	je .theres_more
	cmp al, '/'
	je .theres_more
	cmp al, '%'
	je .theres_more

	mov rax, [.tmp_loc]			; Not a delimiter, so step back before the token
	mov [prog], rax			; that we just grabbed

	jmp mainloop				; And go back to the code interpreter!


.theres_more:
	mov byte [.delim], al

	call get_token
	cmp rax, VARIABLE
	je .handle_variable

	mov rsi, token
	call b_string_to_int
	mov rbx, rax

	xor rax, rax
	mov byte al, [.tmp]

	call get_var				; This also points rsi at right place in variable table

	cmp byte [.delim], '+'
	jne .not_plus

	add rax, rbx
	jmp .finish

.not_plus:
	cmp byte [.delim], '-'
	jne .not_minus

	sub rax, rbx
	jmp .finish

.not_minus:
	cmp byte [.delim], '*'
	jne .not_times

	mul rbx
	jmp .finish

.not_times:
	cmp byte [.delim], '/'
	jne .not_divide

	xor rdx, rdx
	div rbx
	jmp .finish

.not_divide:
	xor rdx, rdx
	div rbx
	mov rax, rdx				; Get remainder

.finish:
	mov rbx, rax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.handle_variable:
	xor rax, rax
	mov byte al, [token]

	call get_var

	mov rbx, rax

	xor rax, rax
	mov byte al, [.tmp]

	call get_var

	cmp byte [.delim], '+'
	jne .vnot_plus

	add rax, rbx
	jmp .vfinish

.vnot_plus:
	cmp byte [.delim], '-'
	jne .vnot_minus

	sub rax, rbx
	jmp .vfinish

.vnot_minus:
	cmp byte [.delim], '*'
	jne .vnot_times

	mul rbx
	jmp .vfinish

.vnot_times:
	cmp byte [.delim], '/'
	jne .vnot_divide

	mov dx, 0
	div rbx
	jmp .finish

.vnot_divide:
	mov dx, 0
	div rbx
	mov rax, rdx				; Get remainder

.vfinish:
	mov rbx, rax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_string:
	mov rdi, token
	mov rsi, progstart_keyword
	call b_string_compare
	je .is_progstart

	mov rsi, ramstart_keyword
	call b_string_compare
	je .is_ramstart

	jmp .error

.is_progstart:
	xor rax, rax
	mov byte al, [.tmp]

	mov rbx, [load_point]
	call set_var

	jmp mainloop



.is_ramstart:
	xor rax, rax
	mov byte al, [.tmp]

	mov rbx, [prog_end]
	inc rbx
	inc rbx
	inc rbx
	call set_var

	jmp mainloop


.error:
	mov rsi, err_syntax
	jmp error


	.tmp		db 0
	.tmp_loc	dq 0
	.delim		db 0


; ==================================================================
; SPECIFIC COMMAND CODE STARTS HERE

; ------------------------------------------------------------------
; ALERT

do_alert:
	call get_token

	cmp rax, QUOTE
	je .is_quote

	mov rsi, err_syntax
	jmp error

.is_quote:
	mov rax, token				; First string for alert box
	xor rbx, rbx				; Others are blank
	xor rcx, rcx
	mov dx, 0				; One-choice box
	jmp mainloop


; ------------------------------------------------------------------
; CALL

do_call:
	call get_token
	cmp rax, NUMBER
	je .is_number

	xor rax, rax
	mov byte al, [token]
	call get_var
	jmp .execute_call

.is_number:
	mov rsi, token
	call b_string_to_int

.execute_call:
	xor rbx, rbx
	xor rcx, rcx
	mov dx, 0
	mov rdi, 0
	mov rsi, 0

	call rax

	jmp mainloop



; ------------------------------------------------------------------
; CLS

do_cls:
	call b_screen_clear
	jmp mainloop


; ------------------------------------------------------------------
; CURSOR

do_cursor:
	call get_token

	mov rsi, token
	mov rdi, .on_str
	call b_string_compare
	jc .turn_on

	mov rsi, token
	mov rdi, .off_str
	call b_string_compare
	jc .turn_off

	mov rsi, err_syntax
	jmp error

.turn_on:
	call b_show_cursor
	jmp mainloop

.turn_off:
	call b_hide_cursor
	jmp mainloop


	.on_str db "ON", 0
	.off_str db "OFF", 0


; ------------------------------------------------------------------
; CURSCHAR

do_curschar:
	call get_token

	cmp rax, VARIABLE
	je .is_ok

	mov rsi, err_syntax
	jmp error

.is_ok:
	xor rax, rax
	mov byte al, [token]

	push rax				; Store variable we're going to use

;	mov ah, 08h
;	xor rbx, rbx
;	int 10h				; Get char at current cursor location

	xor rbx, rbx			; We only want the lower byte (the char, not attribute)
	mov bl, al

	pop rax				; Get the variable back

	call set_var			; And store the value

	jmp mainloop


; ------------------------------------------------------------------
; END

do_end:
	mov rsp, [orig_stack]
	ret


; ------------------------------------------------------------------
; FOR

do_for:
	call get_token				; Get the variable we're using in this loop

	cmp rax, VARIABLE
	jne near .error

	xor rax, rax
	mov byte al, [token]
	mov byte [.tmp_var], al			; Store it in a temporary location for now

	call get_token

	xor rax, rax				; Check it's followed up with '='
	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token				; Next we want a number

	cmp rax, NUMBER
	jne .error

	mov rsi, token				; Convert it
	call b_string_to_int


	; At this stage, we've read something like "FOR X = 1"
	; so let's store that 1 in the variable table

	mov rbx, rax
	xor rax, rax
	mov byte al, [.tmp_var]
	call set_var


	call get_token				; Next we're looking for "TO"

	cmp rax, STRING
	jne .error

	mov rax, token
	call b_string_uppercase

	mov rsi, token
	mov rdi, .to_string
	call b_string_compare
	jnc .error

	; So now we're at "FOR X = 1 TO"

	call get_token

	cmp rax, NUMBER
	jne .error

	mov rsi, token					; Get target number
	call b_string_to_int

	mov rbx, rax

	xor rax, rax
	mov byte al, [.tmp_var]

	sub al, 65					; Store target number in table
	mov rdi, for_variables
	add rdi, rax
	add rdi, rax
	mov rax, rbx
	stosw


	; So we've got the variable, assigned it the starting number, and put into
	; our table the limit it should reach. But we also need to store the point in
	; code after the FOR line we should return to if NEXT X doesn't complete the loop...
;	xor rax, rax
	xor rax, rax
;	xor eax, eax
	mov byte al, [.tmp_var]

	sub al, 65					; Store code position to return to in table
	mov rdi, for_code_points
;	add rdi, rax
;	add rdi, rax
	shl rax, 3
	add rdi, rax
	mov rax, [prog]
	stosq

	jmp mainloop


.error:
	mov rsi, err_syntax
	jmp error


	.tmp_var	db 0
	.to_string	db 'TO', 0


; ------------------------------------------------------------------
; GETKEY

do_getkey:
	call get_token
	cmp rax, VARIABLE
	je .is_variable

	mov rsi, err_syntax
	jmp error

.is_variable:
	xor rax, rax
	mov byte al, [token]

	push rax

	call b_input_key_check

	xor rbx, rbx
	mov bl, al

	pop rax

	call set_var

	jmp mainloop


; ------------------------------------------------------------------
; GOSUB

do_gosub:
	call get_token				; Get the number (label)

	cmp rax, STRING
	je .is_ok

	mov rsi, err_goto_notlabel
	jmp error

.is_ok:
	mov rsi, token				; Back up this label
	mov rdi, .tmp_token
	call b_string_copy

	mov rax, .tmp_token
	call b_string_length

	mov rdi, .tmp_token			; Add ':' char to end for searching
	add rdi, rax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	inc byte [gosub_depth]

	xor rax, rax
	mov byte al, [gosub_depth]		; Get current GOSUB nest level

	cmp al, 9
	jle .within_limit

	mov rsi, err_nest_limit
	jmp error

.within_limit:
	mov rdi, gosub_points			; Move into our table of pointers
	add rdi, rax				; Table is words (not bytes)
	add rdi, rax
	mov rax, [prog]
	stosw					; Store current location before jump


	mov rax, [load_point]
	mov [prog], rax			; Return to start of program to find label

.loop:
	call get_token

	cmp rax, LABEL
	jne .line_loop

	mov rsi, token
	mov rdi, .tmp_token
	call b_string_compare
	jc mainloop

.line_loop:					; Go to end of line
	mov rsi, [prog]
	mov byte al, [rsi]
	inc qword [prog]
	cmp al, 10
	jne .line_loop

	mov rax, [prog]
	mov rbx, [prog_end]
	cmp rax, rbx
	jg .past_end

	jmp .loop

.past_end:
	mov rsi, err_label_notfound
	jmp error

	.tmp_token	times 30 db 0


; ------------------------------------------------------------------
; GOTO

do_goto:
	call get_token				; Get the next token

	cmp rax, STRING
	je .is_ok

	mov rsi, err_goto_notlabel
	jmp error

.is_ok:
	mov rsi, token				; Back up this label
	mov rdi, .tmp_token
	call b_string_copy

	mov rax, .tmp_token
	call b_string_length

	mov rdi, .tmp_token			; Add ':' char to end for searching
	add rdi, rax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov rax, [load_point]
	mov [prog], rax			; Return to start of program to find label

.loop:
	call get_token

	cmp rax, LABEL
	jne .line_loop

	mov rsi, token
	mov rdi, .tmp_token
	call b_string_compare
	jc mainloop

.line_loop:					; Go to end of line
	mov rsi, [prog]
	mov byte al, [rsi]
	inc qword [prog]

	cmp al, 10
	jne .line_loop

	mov rax, [prog]
	mov rbx, [prog_end]
	cmp rax, rbx
	jg .past_end

	jmp .loop

.past_end:
	mov rsi, err_label_notfound
	jmp error

	.tmp_token times	30 db 0


; ------------------------------------------------------------------
; IF

do_if:
	call get_token

	cmp rax, VARIABLE			; If can only be followed by a variable
	je .num_var

	cmp rax, STRING_VAR
	je near .string_var

	mov rsi, err_syntax
	jmp error

.num_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

	mov rdx, rax				; Store value of first part of comparison

	call get_token				; Get the delimiter
	mov byte al, [token]
	cmp al, '='
	je .equals
	cmp al, '>'
	je .greater
	cmp al, '<'
	je .less

	mov rsi, err_syntax			; If not one of the above, error out
	jmp error

.equals:
	call get_token				; Is this 'X = Y' (equals another variable?)

	cmp rax, CHAR
	je .equals_char

	mov byte al, [token]
	call is_letter
	jc .equals_var

	mov rsi, token				; Otherwise it's, eg 'X = 1' (a number)
	call b_string_to_int

	cmp rax, rdx				; On to the THEN bit if 'X = num' matches
	je near .on_to_then

	jmp .finish_line			; Otherwise skip the rest of the line

.equals_char:
	xor rax, rax
	mov byte al, [token]

	cmp rax, rdx
	je near .on_to_then

	jmp .finish_line

.equals_var:
	xor rax, rax
	mov byte al, [token]

	call get_var

	cmp rax, rdx				; Do the variables match?
	je near .on_to_then				; On to the THEN bit if so

	jmp .finish_line			; Otherwise skip the rest of the line

.greater:
	call get_token				; Greater than a variable or number?
	mov byte al, [token]
	call is_letter
	jc .greater_var

	mov rsi, token				; Must be a number here...
	call b_string_to_int

	cmp rax, rdx
	jl near .on_to_then

	jmp .finish_line

.greater_var:					; Variable in this case
	xor rax, rax
	mov byte al, [token]

	call get_var

	cmp rax, rdx				; Make the comparison!
	jl .on_to_then

	jmp .finish_line

.less:
	call get_token
	mov byte al, [token]
	call is_letter
	jc .less_var

	mov rsi, token
	call b_string_to_int

	cmp rax, rdx
	jg .on_to_then

	jmp .finish_line

.less_var:
	xor rax, rax
	mov byte al, [token]

	call get_var

	cmp rax, rdx
	jg .on_to_then

	jmp .finish_line

.string_var:
	mov byte [.tmp_string_var], bl

	call get_token

	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token
	cmp rax, STRING_VAR
	je .second_is_string_var

	cmp rax, QUOTE
	jne .error

	mov rsi, string_vars
	mov rax, 128
	mul rbx
	add rsi, rax
	mov rdi, token
	call b_string_compare
	je .on_to_then

	jmp .finish_line

.second_is_string_var:
	mov rsi, string_vars
	mov rax, 128
	mul rbx
	add rsi, rax

	mov rdi, string_vars
	xor rbx, rbx
	mov byte bl, [.tmp_string_var]
	mov rax, 128
	mul rbx
	add rdi, rax

	call b_string_compare
	jc .on_to_then

	jmp .finish_line

.on_to_then:
	call get_token

	mov rsi, token
	mov rdi, then_keyword
	call b_string_compare

	jc .then_present

	mov rsi, err_syntax
	jmp error

.then_present:				; Continue rest of line like any other command!
	jmp mainloop

.finish_line:				; IF wasn't fulfilled, so skip rest of line
	mov rsi, [prog]
	mov byte al, [rsi]
	inc qword [prog]
	cmp al, 10
	jne .finish_line

	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error

	.tmp_string_var		db 0


; ------------------------------------------------------------------
; INPUT

do_input:
	mov al, 0				; Clear string from previous usage
	mov rdi, .tmpstring
	mov rcx, 128
	rep stosb

	call get_token

	cmp rax, VARIABLE			; We can only INPUT to variables!
	je .number_var

	cmp rax, STRING_VAR
	je .string_var

	mov rsi, err_syntax
	jmp error

.number_var:
	mov rdi, .tmpstring			; Get input from the user
	mov rcx, 50
	call b_input_string

	mov rsi, .tmpstring
	call b_string_length
	cmp rcx, 0
	jne .char_entered

	mov byte [.tmpstring], '0'		; If enter hit, fill variable with zero
	mov byte [.tmpstring + 1], 0

.char_entered:
	mov rsi, .tmpstring			; Convert to integer format
	call b_string_to_int
	mov rbx, rax

	xor rax, rax
	mov byte al, [token]			; Get the variable where we're storing it...
	call set_var				; ...and store it!

	call b_print_newline

	jmp mainloop

.string_var:
	push rbx

	mov rdi, .tmpstring
	mov rcx, 50
	call b_input_string

	mov rsi, .tmpstring
	mov rdi, string_vars

	pop rbx

	mov rax, 128
	mul rbx

	add rdi, rax
	call b_string_copy

	call b_print_newline

	jmp mainloop

	.tmpstring	times 128 db 0


; ------------------------------------------------------------------
; LOAD

do_load:
	call get_token
	cmp rax, QUOTE
	je .is_quote

	cmp rax, STRING_VAR
	jne .error

	mov rsi, string_vars
	mov rax, 128
	mul rbx
	add rsi, rax
	jmp .get_position

.is_quote:
	mov rsi, token

.get_position:
	mov rax, rsi
;	call b_file_exists
	jc .file_not_exists

	mov rdx, rax			; Store for now

	call get_token

	cmp rax, VARIABLE
	je .second_is_var

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

.load_part:
	mov rcx, rax

	mov rax, rdx

;	call b_load_file

	xor rax, rax
	mov byte al, 'S'
	call set_var

	xor rax, rax
	mov byte al, 'R'
	xor rbx, rbx
	call set_var

	jmp mainloop

.second_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	jmp .load_part

.file_not_exists:
	xor rax, rax
	mov byte al, 'R'
	mov rbx, 1
	call set_var

	call get_token				; Skip past the loading point -- unnecessary now

	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error


; ------------------------------------------------------------------
; MOVE

do_move:
	call get_token

	cmp rax, VARIABLE
	je .first_is_var

	mov rsi, token
	call b_string_to_int
	mov dl, al
	jmp .onto_second

.first_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	mov dl, al

.onto_second:
	call get_token

	cmp rax, VARIABLE
	je .second_is_var

	mov rsi, token
	call b_string_to_int
	mov dh, al
	jmp .finish

.second_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	mov dh, al

.finish:
	call b_move_cursor

	jmp mainloop


; ------------------------------------------------------------------
; NEXT

do_next:
	call get_token

	cmp rax, VARIABLE			; NEXT must be followed by a variable
	jne .error

	xor rax, rax
	mov byte al, [token]
	call get_var

	inc rax					; NEXT increments the variable, of course!

	mov rbx, rax

	xor rax, rax
	mov byte al, [token]

	sub al, 65
	mov rsi, for_variables
	add rsi, rax
	add rsi, rax
	lodsw					; Get the target number from the table

	inc rax					; (Make the loop inclusive of target number)
	cmp rax, rbx				; Do the variable and target match?
	je .loop_finished

	xor rax, rax				; If not, store the updated variable
	mov byte al, [token]
	call set_var

	xor rax, rax				; Find the code point and go back
	mov byte al, [token]
	sub al, 65
	mov rsi, for_code_points
;	add rsi, rax
;	add rsi, rax
	shl rax, 3
	add rsi, rax
	lodsq

	mov [prog], rax
	jmp mainloop

.loop_finished:
	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error


; ------------------------------------------------------------------
; PAUSE

do_pause:
	call get_token

	cmp rax, VARIABLE
	je .is_var

	mov rsi, token
	call b_string_to_int
	jmp .finish

.is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

.finish:
;	call b_pause
	jmp mainloop


; ------------------------------------------------------------------
; PEEK

do_peek:
	call get_token

	cmp rax, VARIABLE
	jne .error

	xor rax, rax
	mov byte al, [token]
	mov byte [.tmp_var], al

	call get_token

	cmp rax, VARIABLE
	je .dereference

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

.store:
	mov rsi, rax
	xor rbx, rbx
	mov byte bl, [rsi]
	xor rax, rax
	mov byte al, [.tmp_var]
	call set_var

	jmp mainloop

.dereference:
	mov byte al, [token]
	call get_var
	jmp .store

.error:
	mov rsi, err_syntax
	jmp error


	.tmp_var	db 0


; ------------------------------------------------------------------
; POKE

do_poke:
	call get_token

	cmp rax, VARIABLE
	je .first_is_var

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

	cmp rax, 255
	jg .error

	mov byte [.first_value], al
	jmp .onto_second


.first_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

	mov byte [.first_value], al

.onto_second:
	call get_token

	cmp rax, VARIABLE
	je .second_is_var

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

.got_value:
	mov rdi, rax
	xor rax, rax
	mov byte al, [.first_value]
	mov byte [rdi], al

	jmp mainloop

.second_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	jmp .got_value

.error:
	mov rsi, err_syntax
	jmp error

	.first_value	db 0


; ------------------------------------------------------------------
; PORT

do_port:
	call get_token
	mov rsi, token

	mov rdi, .out_cmd
	call b_string_compare
	jc .do_out_cmd

	mov rdi, .in_cmd
	call b_string_compare
	jc .do_in_cmd

	jmp .error

.do_out_cmd:
	call get_token
	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int		; Now rax = port number
	mov rdx, rax

	call get_token
	cmp rax, NUMBER
	je .out_is_num

	cmp rax, VARIABLE
	je .out_is_var

	jmp .error

.out_is_num:
	mov rsi, token
	call b_string_to_int
;	call b_port_byte_out
	jmp mainloop

.out_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

;	call b_port_byte_out
	jmp mainloop

.do_in_cmd:
	call get_token
	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int
	mov rdx, rax

	call get_token
	cmp rax, VARIABLE
	jne .error

	mov byte cl, [token]

;	call b_port_byte_in
	xor rbx, rbx
	mov bl, al

	mov al, cl
	call set_var

	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error


	.out_cmd	db "OUT", 0
	.in_cmd		db "IN", 0


; ------------------------------------------------------------------
; PRINT

do_print:
	call get_token				; Get part after PRINT

	cmp rax, QUOTE				; What type is it?
	je .print_quote

	cmp rax, VARIABLE			; Numerical variable (eg X)
	je .print_var

	cmp rax, STRING_VAR			; String variable (eg $1)
	je .print_string_var

	cmp rax, STRING				; Special keyword (eg CHR or HEX)
	je .print_keyword

	mov rsi, err_print_type			; We only print quoted strings and vars!
	jmp error

.print_var:
	xor rax, rax
	mov byte al, [token]
	call get_var				; Get its value
	mov rdi, tstring
	mov rsi, rdi
	call b_int_to_string			; Convert to string
	call b_print_string

	jmp .newline_or_not

.print_quote:					; If it's quoted text, print it
	mov rsi, token
	call b_print_string

	jmp .newline_or_not

.print_string_var:
	mov rsi, string_vars
	mov rax, 128
	mul rbx
	add rsi, rax
	call b_print_string

	jmp .newline_or_not

.print_keyword:
	mov rsi, token
	mov rdi, chr_keyword
	call b_string_compare
	jc .is_chr

	mov rdi, hex_keyword
	call b_string_compare
	jc .is_hex

	mov rsi, err_syntax
	jmp error

.is_chr:
	call get_token

	cmp rax, VARIABLE
	jne .error

	xor rax, rax
	mov byte al, [token]
	call get_var

;	mov ah, 0Eh
;	int 10h

	jmp .newline_or_not

.is_hex:
	call get_token

	cmp rax, VARIABLE
	jne .error

	xor rax, rax
	mov byte al, [token]
	call get_var

	call b_debug_dump_al ;print_2hex

	jmp .newline_or_not

.error:
	mov rsi, err_syntax
	jmp error

.newline_or_not:
	; We want to see if the command ends with ';' -- which means that
	; we shouldn't print a newline after it finishes. So we store the
	; current program location to pop ahead and see if there's the ';'
	; character -- otherwise we put the program location back and resume
	; the main loop
	mov rax, [prog]
	mov [.tmp_loc], rax

	call get_token
	cmp rax, UNKNOWN
	jne .ignore

	xor rax, rax
	mov al, [token]
	cmp al, ';'
	jne .ignore

	jmp mainloop				; And go back to interpreting the code!

.ignore:
	call b_print_newline

	mov rax, [.tmp_loc]
	mov [prog], rax

	jmp mainloop

	.tmp_loc	dq 0


; ------------------------------------------------------------------
; RAND

do_rand:
	call get_token
	cmp rax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int
	mov [.num1], rax

	call get_token
	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int
	mov [.num2], rax

	mov rax, [.num1]
	mov rbx, [.num2]
;	call b_get_random

	mov rbx, rcx
	xor rax, rax
	mov byte al, [.tmp]
	call set_var

	jmp mainloop

	.tmp	db 0
	.num1	dq 0
	.num2	dq 0

.error:
	mov rsi, err_syntax
	jmp error


; ------------------------------------------------------------------
; REM

do_rem:
	mov rsi, [prog]
	mov byte al, [rsi]
	inc qword [prog]
	cmp al, 10			; Find end of line after REM
	jne do_rem

	jmp mainloop


; ------------------------------------------------------------------
; RETURN

do_return:
	xor rax, rax
	mov byte al, [gosub_depth]
	cmp al, 0
	jne .is_ok

	mov rsi, err_return
	jmp error

.is_ok:
	mov rsi, gosub_points
	add rsi, rax				; Table is words (not bytes)
	add rsi, rax
	lodsw
	mov [prog], rax
	dec byte [gosub_depth]

	jmp mainloop	


; ------------------------------------------------------------------
; SAVE

do_save:
	call get_token
	cmp rax, QUOTE
	je .is_quote

	cmp rax, STRING_VAR
	jne near .error

	mov rsi, string_vars
	mov rax, 128
	mul rbx
	add rsi, rax
	jmp .get_position

.is_quote:
	mov rsi, token

.get_position:
	mov rdi, .tmp_filename
	call b_string_copy

	call get_token

	cmp rax, VARIABLE
	je .second_is_var

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

.set_data_loc:
	mov [.data_loc], rax

	call get_token

	cmp rax, VARIABLE
	je .third_is_var

	cmp rax, NUMBER
	jne .error

	mov rsi, token
	call b_string_to_int

.set_data_size:
	mov  [.data_size], rax

	mov rax, .tmp_filename
	mov  rbx, [.data_loc]
	mov  rcx, [.data_size]

;	call b_write_file
	jc .save_failure

	xor rax, rax
	mov byte al, 'R'
	xor rbx, rbx
	call set_var

	jmp mainloop

.second_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	jmp .set_data_loc

.third_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var
	jmp .set_data_size

.save_failure:
	xor rax, rax
	mov byte al, 'R'
	mov rbx, 1
	call set_var

	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error


	.filename_loc	dw 0
	.data_loc	dw 0
	.data_size	dw 0

	.tmp_filename	times 15 db 0


; ------------------------------------------------------------------
; SERIAL

do_serial:
	call get_token
	mov rsi, token

	mov rdi, .on_cmd
	call b_string_compare
	jc .do_on_cmd

	mov rdi, .send_cmd
	call b_string_compare
	jc .do_send_cmd

	mov rdi, .rec_cmd
	call b_string_compare
	jc .do_rec_cmd

	jmp .error

.do_on_cmd:
	call get_token
	cmp rax, NUMBER
	je .do_on_cmd_ok
	jmp .error

.do_on_cmd_ok:
	mov rsi, token
	call b_string_to_int
	cmp rax, 1200
	je .on_cmd_slow_mode
	cmp rax, 9600
	je .on_cmd_fast_mode

	jmp .error

.on_cmd_fast_mode:
	xor rax, rax
;	call b_serial_port_enable
	jmp mainloop

.on_cmd_slow_mode:
	mov rax, 1
;	call b_serial_port_enable
	jmp mainloop

.do_send_cmd:
	call get_token
	cmp rax, NUMBER
	je .send_number

	cmp rax, VARIABLE
	je .send_variable

	jmp .error

.send_number:
	mov rsi, token
	call b_string_to_int
;	call b_send_via_serial
	jmp mainloop

.send_variable:
	xor rax, rax
	mov byte al, [token]
	call get_var
;	call b_send_via_serial
	jmp mainloop

.do_rec_cmd:
	call get_token
	cmp rax, VARIABLE
	jne .error

	mov byte al, [token]

	xor rcx, rcx
	mov cl, al
;	call b_get_via_serial

	xor rbx, rbx
	mov bl, al
	mov al, cl
	call set_var

	jmp mainloop

.error:
	mov rsi, err_syntax
	jmp error

	.on_cmd		db "ON", 0
	.send_cmd	db "SEND", 0
	.rec_cmd	db "REC", 0


; ------------------------------------------------------------------
; SOUND

do_sound:
	call get_token

	cmp rax, VARIABLE
	je .first_is_var

	mov rsi, token
	call b_string_to_int
	jmp .done_first

.first_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

.done_first:
	call b_speaker_tone

	call get_token

	cmp rax, VARIABLE
	je .second_is_var

	mov rsi, token
	call b_string_to_int
	jmp .finish

.second_is_var:
	xor rax, rax
	mov byte al, [token]
	call get_var

.finish:
;	call b_pause
	call b_speaker_off

	jmp mainloop


; ------------------------------------------------------------------
; WAITKEY

do_waitkey:
	call get_token
	cmp rax, VARIABLE
	je .is_variable

	mov rsi, err_syntax
	jmp error

.is_variable:
	xor rax, rax
	mov byte al, [token]

	push rax

	call b_input_key_wait

	cmp rax, 48E0h
	je .up_pressed

	cmp rax, 50E0h
	je .down_pressed

	cmp rax, 4BE0h
	je .left_pressed

	cmp rax, 4DE0h
	je .right_pressed

.store:
	xor rbx, rbx
	mov bl, al

	pop rax

	call set_var

	jmp mainloop

.up_pressed:
	mov rax, 1
	jmp .store

.down_pressed:
	mov rax, 2
	jmp .store

.left_pressed:
	mov rax, 3
	jmp .store

.right_pressed:
	mov rax, 4
	jmp .store


; ==================================================================
; INTERNAL ROUTINES FOR INTERPRETER

; ------------------------------------------------------------------
; Get value of variable character specified in AL (eg 'A')

get_var:
	sub al, 65
	mov rsi, variables
	add rsi, rax
	add rsi, rax
	lodsw
	ret


; ------------------------------------------------------------------
; Set value of variable character specified in AL (eg 'A')
; with number specified in rbx

set_var:
	mov ah, 0
	sub al, 65				; Remove ASCII codes before 'A'

	mov rdi, variables			; Find position in table (of words)
	add rdi, rax
	add rdi, rax
	mov rax, rbx
	stosw
	ret


; ------------------------------------------------------------------
; Get token from current position in prog

get_token:
	mov rsi, [prog]
	lodsb

	cmp al, 13
	je .newline

	cmp al, 10
	je .newline

	cmp al, ' '
	je .newline

	call is_number
	jc get_number_token

	cmp al, '"'
	je get_quote_token

	cmp al, 39			; Quote mark (')
	je get_char_token

	cmp al, '$'
	je near get_string_var_token

	jmp get_string_token

.newline:
	inc qword [prog]
	jmp get_token

get_number_token:
	mov rsi, [prog]
	mov rdi, token

.loop:
	lodsb
	cmp al, 13
	je .done
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	call is_number
	jc .fine

	mov rsi, err_char_in_num
	jmp error

.fine:
	stosb
	inc qword [prog]
	jmp .loop

.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov rax, NUMBER			; Pass back the token type
	ret

get_char_token:
	inc qword [prog]			; Move past first quote (')

	mov rsi, [prog]
	lodsb

	mov byte [token], al

	lodsb
	cmp al, 39			; Needs to finish with another quote
	je .is_ok

	mov rsi, err_quote_term
	jmp error

.is_ok:
	inc qword [prog]
	inc qword [prog]

	mov rax, CHAR
	ret

get_quote_token:
	inc qword [prog]			; Move past first quote (") char
	mov qword rsi, [prog]
	mov rdi, token
.loop:
	lodsb
	cmp al, '"'
	je .done
	cmp al, 10
	je .error
	stosb
	inc qword [prog]
	jmp .loop

.done:
	mov al, 0			; Zero-terminate the token
	stosb
	inc qword [prog]			; Move past final quote

	mov rax, QUOTE			; Pass back token type
	ret

.error:
	mov rsi, err_quote_term
	jmp error

get_string_var_token:
	lodsb
	xor rbx, rbx			; If it's a string var, pass number of string in rbx
	mov bl, al
	sub bl, 49

	inc qword [prog]
	inc qword [prog]

	mov rax, STRING_VAR
	ret

get_string_token:
	mov qword rsi, [prog]
	mov rdi, token
.loop:
	lodsb
	cmp al, 13
	je .done
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	stosb
	inc qword [prog]
	jmp .loop
.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov rax, token
	call b_string_uppercase

	mov rsi, token
	call b_string_length		; How long was the token?
	cmp rcx, 1			; If 1 char, it's a variable or delimiter
	je .is_not_string

	mov rsi, token			; If the token ends with ':', it's a label
	add rsi, rax
	dec rsi
	lodsb
	cmp al, ':'
	je .is_label

	mov rax, STRING			; Otherwise it's a general string of characters
	ret

.is_label:
	mov rax, LABEL
	ret

.is_not_string:
	mov byte al, [token]
	call is_letter
	jc .is_var

	mov rax, UNKNOWN
	ret

.is_var:
	mov rax, VARIABLE		; Otherwise probably a variable
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII number

is_number:
	cmp al, 48
	jl .not_number
	cmp al, 57
	jg .not_number
	stc
	ret
.not_number:
	clc
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII letter

is_letter:
	cmp al, 65
	jl .not_letter
	cmp al, 90
	jg .not_letter
	stc
	ret

.not_letter:
	clc
	ret


; ------------------------------------------------------------------
; Print error message and quit out

error:
	call b_print_newline
	call b_print_string		; Print error message
	call b_print_newline

	mov rsp, [orig_stack]	; Restore the stack to as it was when BASIC started

	ret				; And finish


	; Error messages text...

	err_char_in_num		db "Error: unexpected character in number", 0
	err_quote_term		db "Error: quoted string or character not terminated correctly", 0
	err_print_type		db "Error: PRINT command not followed by quoted text or variable", 0
	err_cmd_unknown		db "Error: unknown command", 0
	err_goto_notlabel	db "Error: GOTO or GOSUB not followed by label", 0
	err_label_notfound	db "Error: GOTO or GOSUB label not found", 0
	err_return		db "Error: RETURN without GOSUB", 0
	err_nest_limit		db "Error: FOR or GOSUB nest limit exceeded", 0
	err_next		db "Error: NEXT without FOR", 0
	err_syntax		db "Error: syntax error", 0



; ==================================================================
; DATA SECTION

	orig_stack		dq 0		; Original stack location when BASIC started

	prog			dq 0		; Pointer to current location in BASIC code
	prog_end		dq 0		; Pointer to final byte of BASIC code

	load_point		dq 0

	token_type		db 0		; Type of last token read (eg NUMBER, VARIABLE)
	token			times 255 db 0	; Storage space for the token
	tstring			times 255 db 0

align 16
	variables		times 26 dq 0	; Storage space for variables A to Z
align 16
	for_variables		times 26 dq 0	; Storage for FOR loops
align 16
	for_code_points		times 26 dq 0	; Storage for code positions where FOR loops start

	alert_cmd		db "ALERT", 0
	call_cmd		db "CALL", 0
	cls_cmd			db "CLS", 0
	cursor_cmd		db "CURSOR", 0
	curschar_cmd		db "CURSCHAR", 0
	end_cmd			db "END", 0
	for_cmd 		db "FOR", 0
	gosub_cmd		db "GOSUB", 0
	goto_cmd		db "GOTO", 0
	getkey_cmd		db "GETKEY", 0
	if_cmd 			db "IF", 0
	input_cmd 		db "INPUT", 0
	load_cmd		db "LOAD", 0
	move_cmd 		db "MOVE", 0
	next_cmd 		db "NEXT", 0
	pause_cmd 		db "PAUSE", 0
	peek_cmd		db "PEEK", 0
	poke_cmd		db "POKE", 0
	port_cmd		db "PORT", 0
	print_cmd 		db "PRINT", 0
	rem_cmd			db "REM", 0
	rand_cmd		db "RAND", 0
	return_cmd		db "RETURN", 0
	save_cmd		db "SAVE", 0
	serial_cmd		db "SERIAL", 0
	sound_cmd 		db "SOUND", 0
	waitkey_cmd		db "WAITKEY", 0

	then_keyword		db "THEN", 0
	chr_keyword		db "CHR", 0
	hex_keyword		db "HEX", 0

	progstart_keyword	db "PROGSTART", 0
	ramstart_keyword	db "RAMSTART", 0

	gosub_depth		db 0
	gosub_points		times 10 dq 0	; Points in code to RETURN to

	string_vars		times 1024 db 0	; 8 * 128 byte strings


; ------------------------------------------------------------------
basic_prog:
 DB 'CLS',13,10
 DB 'PRINT "Please type your name: ";',13,10
 DB 'INPUT $N',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT "Hello ";',13,10
 DB 'PRINT $N;',13,10
 DB 'PRINT ", welcome to MikeOS Basic (in 64-bit mode)!"',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT "It supports FOR...NEXT loops and simple integer maths..."',13,10
 DB 'PRINT ""',13,10
 DB 'FOR I = 1 TO 15',13,10
 DB 'J = I * I',13,10
 DB 'K = J * I',13,10
 DB 'L = K * I',13,10
 DB 'PRINT I ;',13,10
 DB 'PRINT "        ";',13,10
 DB 'PRINT J ;',13,10
 DB 'PRINT "        ";',13,10
 DB 'PRINT K ;',13,10
 DB 'PRINT "        ";',13,10
 DB 'PRINT L',13,10
 DB 'NEXT I',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT " ...and IF...THEN and GOSUB and lots of other stuff. Bye!"',13,10
 DB 'END',13,10
