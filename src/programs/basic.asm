; ==================================================================
; basic.asm - BASIC Interpreter for BareMetal OS
; Ported by Ian Seyler
;
; Based on the "OS-independent" version of MIBASIC by Neville Watkin
; which is based on MIKEOS BASIC by Mike Saunders
; ==================================================================

[BITS 64]
[ORG 0x0000000000200000]

%INCLUDE "bmdev.asm"

; ------------------------------------------------------------------
; Token types
VARIABLE equ 1
STRING_VAR equ 2
NUMBER equ 3
STRING equ 4
QUOTE equ 5
CHAR equ 6
UNKNOWN equ 7
LABEL equ 8

; ------------------------------------------------------------------
; The BASIC intepreter execution starts here...

os_run_basic:
	mov dword [orig_stack], esp	; Save stack pointer -- we might jump to the
					; error printing code and quit in the middle
					; some nested loops, and we want to preserve
					; the stack
	mov eax, basic_prog		;embedded test program for a quick DOS test
	mov ebx, 8192			;default size for test program (not critical)
	mov dword [load_point], eax	; EAX was passed as starting location of code
	mov dword [prog], eax		; prog = pointer to current execution point in code
	add ebx, eax			; We were passed the .BAS byte size in BX
	dec ebx
	dec ebx
	mov dword [prog_end], ebx	; Make note of program end point
	call clear_ram			; Clear variables etc. from previous run
					; of a BASIC program
mainloop:
	call get_token			; Get a token from the start of the line
	cmp eax, STRING			; Is the type a string of characters?
	je .keyword			; If so, let's see if it's a keyword to process
	cmp eax, VARIABLE		; If it's a variable at the start of the line,
	je near assign			; this is an assign (eg "X = Y + 5")
	cmp eax, STRING_VAR		; Same for a string variable (eg $1)
	je near assign
	cmp eax, LABEL			; Don't need to do anything here - skip
	je mainloop
	mov esi, err_syntax		; Otherwise show an error and quit
	jmp error
.keyword:
	mov esi, token			; Start trying to match commands
	mov edi, alert_cmd
	call b_string_compare
	jc near do_alert
	mov edi, call_cmd
	call b_string_compare
	jc near do_call
	mov edi, cls_cmd
	call b_string_compare
	jc near do_cls
	mov edi, cursor_cmd
	call b_string_compare
	jc near do_cursor
	mov edi, curschar_cmd
	call b_string_compare
	jc near do_curschar
	mov edi, end_cmd
	call b_string_compare
	jc near do_end
	mov edi, for_cmd
	call b_string_compare
	jc near do_for
	mov edi, getkey_cmd
	call b_string_compare
	jc near do_getkey
	mov edi, gosub_cmd
	call b_string_compare
	jc near do_gosub
	mov edi, goto_cmd
	call b_string_compare
	jc near do_goto
	mov edi, input_cmd
	call b_string_compare
	jc near do_input
	mov edi, if_cmd
	call b_string_compare
	jc near do_if
;  mov edi, load_cmd
;  call b_string_compare
;  jc near do_load
	mov edi, move_cmd
	call b_string_compare
	jc near do_move
	mov edi, next_cmd
	call b_string_compare
	jc near do_next
	mov edi, pause_cmd
	call b_string_compare
	jc near do_pause
	mov edi, peek_cmd
	call b_string_compare
	jc near do_peek
	mov edi, poke_cmd
	call b_string_compare
	jc near do_poke
	mov edi, port_cmd
	call b_string_compare
	jc near do_port
	mov edi, print_cmd
	call b_string_compare
	jc near do_print
	mov edi, rand_cmd
	call b_string_compare
	jc near do_rand
	mov edi, rem_cmd
	call b_string_compare
	jc near do_rem
	mov edi, return_cmd
	call b_string_compare
	jc near do_return
;  mov edi, save_cmd
;  call b_string_compare
;  jc near do_save
	mov edi, serial_cmd
	call b_string_compare
	jc near do_serial
	mov edi, sound_cmd
	call b_string_compare
	jc near do_sound
	mov edi, waitkey_cmd
	call b_string_compare
	jc near do_waitkey
	mov esi, err_cmd_unknown              ; Command not found?
	jmp error

; ------------------------------------------------------------------
; CLEAR RAM
clear_ram:
  mov al, 0
  mov edi, variables
  mov ecx, 52
  rep stosb
  mov edi, for_variables
  mov ecx, 52
  rep stosb
  mov edi, for_code_points
  mov ecx, 52
  rep stosb
  mov byte [gosub_depth], 0
  mov edi, gosub_points
  mov ecx, 20
  rep stosb
  mov edi, string_vars
  mov ecx, 1024
  rep stosb
  ret
; ------------------------------------------------------------------
; ASSIGNMENT
assign:
  cmp eax, VARIABLE                     ; Are we starting with a number var?
  je .do_num_var
  mov edi, string_vars                  ; Otherwise it's a string var
  mov eax, 128
  mul ebx                               ; (EBX = string number, passed back from get_token)
  add edi, eax
  push rdi
  call get_token
  mov byte al, [token]
  cmp al, '='
  jne near .error
  call get_token
  cmp eax, QUOTE
  je .second_is_quote
  cmp eax, STRING_VAR
  jne near .error
  mov esi, string_vars                  ; Otherwise it's a string var
  mov eax, 128
  mul ebx                               ; (EBX = string number, passed back from get_token)
  add esi, eax
  pop rdi
  call b_string_copy
  jmp mainloop
.second_is_quote:
  mov esi, token
  pop rdi
  call b_string_copy
  jmp mainloop
.do_num_var:
  mov eax, 0
  mov byte al, [token]
  mov byte [.tmp], al
  call get_token
  mov byte al, [token]
  cmp al, '='
  jne near .error
  call get_token
  cmp eax, NUMBER
  je .second_is_num
  cmp eax, VARIABLE
  je .second_is_variable
  cmp eax, STRING
  je near .second_is_string
  cmp eax, UNKNOWN
  jne near .error
  mov byte al, [token]                  ; Address of string var?
  cmp al, '&'
  jne near .error
  call get_token                        ; Let's see if there's a string var
  cmp eax, STRING_VAR
  jne near .error
  mov edi, string_vars
  mov eax, 128
  mul ebx
  add edi, eax
  mov ebx, edi
  mov byte al, [.tmp]
  call set_var
  jmp mainloop
.second_is_variable:
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov ebx, eax
  mov byte al, [.tmp]
  call set_var
  jmp .check_for_more
.second_is_num:
  mov esi, token
  call b_string_to_int
  mov ebx, eax                          ; Number to insert in variable table
  mov eax, 0
  mov byte al, [.tmp]
  call set_var
                                        ; The assignment could be simply "X = 5" etc. Or it could be
                                        ; "X = Y + 5" -- ie more complicated. So here we check to see if
                                        ; there's a delimiter...
.check_for_more:
  mov dword eax, [prog]                 ; Save code location in case there's no delimiter
  mov dword [.tmp_loc], eax
  call get_token                        ; Any more to deal with in this assignment?
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
  mov dword eax, [.tmp_loc]             ; Not a delimiter, so step back before the token
  mov dword [prog], eax                 ; that we just grabbed
  jmp mainloop                          ; And go back to the code interpreter!
.theres_more:
  mov byte [.delim], al
  call get_token
  cmp eax, VARIABLE
  je .handle_variable
  mov esi, token
  call b_string_to_int
  mov ebx, eax
  mov eax, 0
  mov byte al, [.tmp]
  call get_var                          ; This also points ESI at right place in variable table
  cmp byte [.delim], '+'
  jne .not_plus
  add eax, ebx
  jmp .finish
.not_plus:
  cmp byte [.delim], '-'
  jne .not_minus
  sub eax, ebx
  jmp .finish
.not_minus:
  cmp byte [.delim], '*'
  jne .not_times
  mul ebx
  jmp .finish
.not_times:
  cmp byte [.delim], '/'
  jne .not_divide
  mov edx, 0
  div ebx
  jmp .finish
.not_divide:
  mov edx, 0
  div ebx
  mov eax, edx                          ; Get remainder
.finish:
  mov ebx, eax
  mov byte al, [.tmp]
  call set_var
  jmp .check_for_more
.handle_variable:
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov ebx, eax
  mov eax, 0
  mov byte al, [.tmp]
  call get_var
  cmp byte [.delim], '+'
  jne .vnot_plus
  add eax, ebx
  jmp .vfinish
.vnot_plus:
  cmp byte [.delim], '-'
  jne .vnot_minus
  sub eax, ebx
  jmp .vfinish
.vnot_minus:
  cmp byte [.delim], '*'
  jne .vnot_times
  mul ebx
  jmp .vfinish
.vnot_times:
  cmp byte [.delim], '/'
  jne .vnot_divide
  mov edx, 0
  div ebx
  jmp .finish
.vnot_divide:
  mov edx, 0
  div ebx
  mov eax, edx                          ; Get remainder
.vfinish:
  mov ebx, eax
  mov byte al, [.tmp]
  call set_var
  jmp .check_for_more
.second_is_string:
  mov edi, token
  mov esi, progstart_keyword
  call b_string_compare
  je .is_progstart
  mov esi, ramstart_keyword
  call b_string_compare
  je .is_ramstart
  jmp .error
.is_progstart:
  mov eax, 0
  mov byte al, [.tmp]
  mov dword ebx, [load_point]
  call set_var
  jmp mainloop
.is_ramstart:
  mov eax, 0
  mov byte al, [.tmp]
  mov dword ebx, [prog_end]
  inc ebx
  inc ebx
  inc ebx
  call set_var
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
.tmp db 0
.tmp_loc dd 0
.delim db 0
; ==================================================================
; SPECIFIC COMMAND CODE STARTS HERE
; ------------------------------------------------------------------
; ALERT
do_alert:
  call get_token
  cmp eax, QUOTE
  je .is_quote
  mov esi, err_syntax
  jmp error
.is_quote:
  mov eax, token                        ; First string for alert box
  mov ebx, 0                            ; Others are blank
  mov ecx, 0
  mov edx, 0                            ; One-choice box
;  call b_dialog_box
  jmp mainloop
; ------------------------------------------------------------------
; CALL
do_call:
  call get_token
  cmp eax, NUMBER
  je .is_number
  xor eax, eax
  mov byte al, [token]
  call get_var
  jmp .execute_call
.is_number:
  mov esi, token
  call b_string_to_int
.execute_call:
  mov ebx, 0
  mov ecx, 0
  mov edx, 0
  mov edi, 0
  mov esi, 0
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
  mov esi, token
  mov edi, .on_str
  call b_string_compare
  jc .turn_on
  mov esi, token
  mov edi, .off_str
  call b_string_compare
  jc .turn_off
  mov esi, err_syntax
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
  cmp eax, VARIABLE
  je .is_ok
  mov esi, err_syntax
  jmp error
.is_ok:
  mov eax, 0
  mov byte al, [token]
  push rax                              ; Store variable we're going to use
  mov ah, 08h
  mov ebx, 0
;  int 10h                               ; Get char at current cursor location
  mov ebx, 0                            ; We only want the lower byte (the char, not attribute)
  mov bl, al
  pop rax                               ; Get the variable back
  call set_var                          ; And store the value
  jmp mainloop
; ------------------------------------------------------------------
; END
do_end:
  mov dword esp, [orig_stack]
  ret
; ------------------------------------------------------------------
; FOR
do_for:
  call get_token                        ; Get the variable we're using in this loop
  cmp eax, VARIABLE
  jne near .error
  mov eax, 0
  mov byte al, [token]
  mov byte [.tmp_var], al               ; Store it in a temporary location for now
  call get_token
  mov eax, 0                            ; Check it's followed up with '='
  mov byte al, [token]
  cmp al, '='
  jne .error
  call get_token                        ; Next we want a number
  cmp eax, NUMBER
  jne .error
  mov esi, token                        ; Convert it
  call b_string_to_int
                                        ; At this stage, we've read something like "FOR X = 1"
                                        ; so let's store that 1 in the variable table
  mov ebx, eax
  mov eax, 0
  mov byte al, [.tmp_var]
  call set_var
  call get_token                        ; Next we're looking for "TO"
  cmp eax, STRING
  jne .error
  mov eax, token
  call b_string_uppercase
  mov esi, token
  mov edi, .to_string
  call b_string_compare
  jnc .error
                                        ; So now we're at "FOR X = 1 TO"
  call get_token
  cmp eax, NUMBER
  jne .error
  mov esi, token                        ; Get target number
  call b_string_to_int
  mov ebx, eax
  mov eax, 0
  mov byte al, [.tmp_var]
  sub al, 65                            ; Store target number in table
  mov edi, for_variables
  add edi, eax
  add edi, eax
  mov eax, ebx
  stosw
                                        ; So we've got the variable, assigned it the starting number, and put into
                                        ; our table the limit it should reach. But we also need to store the point in
                                        ; code after the FOR line we should return to if NEXT X doesn't complete the loop...
  mov eax, 0
  mov byte al, [.tmp_var]
  sub al, 65                            ; Store code position to return to in table
  mov edi, for_code_points
  add edi, eax
  add edi, eax
  mov dword eax, [prog]
  stosw
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
.tmp_var db 0
.to_string db 'TO', 0
; ------------------------------------------------------------------
; GETKEY
do_getkey:
  call get_token
  cmp eax, VARIABLE
  je .is_variable
  mov esi, err_syntax
  jmp error
.is_variable:
  mov eax, 0
  mov byte al, [token]
  push rax
  call b_input_key_check
  mov ebx, 0
  mov bl, al
  pop rax
  call set_var
  jmp mainloop
; ------------------------------------------------------------------
; GOSUB
do_gosub:
  call get_token                        ; Get the number (label)
  cmp eax, STRING
  je .is_ok
  mov esi, err_goto_notlabel
  jmp error
.is_ok:
  mov esi, token                        ; Back up this label
  mov edi, .tmp_token
  call b_string_copy
  mov eax, .tmp_token
  call b_string_length
  mov edi, .tmp_token                   ; Add ':' char to end for searching
  add edi, eax
  mov al, ':'
  stosb
  mov al, 0
  stosb
  inc byte [gosub_depth]
  mov eax, 0
  mov byte al, [gosub_depth]            ; Get current GOSUB nest level
  cmp al, 9
  jle .within_limit
  mov esi, err_nest_limit
  jmp error
.within_limit:
  mov edi, gosub_points                 ; Move into our table of pointers
  add edi, eax                          ; Table is words (not bytes)
  add edi, eax
  mov dword eax, [prog]
  stosw                                 ; Store current location before jump
  mov dword eax, [load_point]
  mov dword [prog], eax                 ; Return to start of program to find label
.loop:
  call get_token
  cmp eax, LABEL
  jne .line_loop
  mov esi, token
  mov edi, .tmp_token
  call b_string_compare
  jc mainloop
.line_loop:                             ; Go to end of line
  mov dword esi, [prog]
  mov byte al, [esi]
  inc dword [prog]
  cmp al, 10
  jne .line_loop
  mov dword eax, [prog]
  mov dword ebx, [prog_end]
  cmp eax, ebx
  jg .past_end
  jmp .loop
.past_end:
  mov esi, err_label_notfound
  jmp error
.tmp_token: times 30 db 0
; ------------------------------------------------------------------
; GOTO
do_goto:
  call get_token                        ; Get the next token
  cmp eax, STRING
  je .is_ok
  mov esi, err_goto_notlabel
  jmp error
.is_ok:
  mov esi, token                        ; Back up this label
  mov edi, .tmp_token
  call b_string_copy
  mov eax, .tmp_token
  call b_string_length
  mov edi, .tmp_token                   ; Add ':' char to end for searching
  add edi, eax
  mov al, ':'
  stosb
  mov al, 0
  stosb
  mov dword eax, [load_point]
  mov dword [prog], eax                 ; Return to start of program to find label
.loop:
  call get_token
  cmp eax, LABEL
  jne .line_loop
  mov esi, token
  mov edi, .tmp_token
  call b_string_compare
  jc mainloop
.line_loop:                             ; Go to end of line
  mov dword esi, [prog]
  mov byte al, [esi]
  inc dword [prog]
  cmp al, 10
  jne .line_loop
  mov dword eax, [prog]
  mov dword ebx, [prog_end]
  cmp eax, ebx
  jg .past_end
  jmp .loop
.past_end:
  mov esi, err_label_notfound
  jmp error
.tmp_token: times 30 db 0
; ------------------------------------------------------------------
; IF
do_if:
  call get_token
  cmp eax, VARIABLE                     ; If can only be followed by a variable
  je .num_var
  cmp eax, STRING_VAR
  je near .string_var
  mov esi, err_syntax
  jmp error
.num_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov edx, eax                          ; Store value of first part of comparison
  call get_token                        ; Get the delimiter
  mov byte al, [token]
  cmp al, '='
  je .equals
  cmp al, '>'
  je .greater
  cmp al, '<'
  je .less
  mov esi, err_syntax                   ; If not one of the above, error out
  jmp error
.equals:
  call get_token                        ; Is this 'X = Y' (equals another variable?)
  cmp eax, CHAR
  je .equals_char
  mov byte al, [token]
  call is_letter
  jc .equals_var
  mov esi, token                        ; Otherwise it's, eg 'X = 1' (a number)
  call b_string_to_int
  cmp eax, edx                          ; On to the THEN bit if 'X = num' matches
  je near .on_to_then
  jmp .finish_line                      ; Otherwise skip the rest of the line
.equals_char:
  mov eax, 0
  mov byte al, [token]
  cmp eax, edx
  je near .on_to_then
  jmp .finish_line
.equals_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  cmp eax, edx                          ; Do the variables match?
  je near .on_to_then                   ; On to the THEN bit if so
  jmp .finish_line                      ; Otherwise skip the rest of the line
.greater:
  call get_token                        ; Greater than a variable or number?
  mov byte al, [token]
  call is_letter
  jc .greater_var
  mov esi, token                        ; Must be a number here...
  call b_string_to_int
  cmp eax, edx
  jl near .on_to_then
  jmp .finish_line
.greater_var:                           ; Variable in this case
  mov eax, 0
  mov byte al, [token]
  call get_var
  cmp eax, edx                          ; Make the comparison!
  jl .on_to_then
  jmp .finish_line
.less:
  call get_token
  mov byte al, [token]
  call is_letter
  jc .less_var
  mov esi, token
  call b_string_to_int
  cmp eax, edx
  jg .on_to_then
  jmp .finish_line
.less_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  cmp eax, edx
  jg .on_to_then
  jmp .finish_line
.string_var:
  mov byte [.tmp_string_var], bl
  call get_token
  mov byte al, [token]
  cmp al, '='
  jne .error
  call get_token
  cmp eax, STRING_VAR
  je .second_is_string_var
  cmp eax, QUOTE
  jne .error
  mov esi, string_vars
  mov eax, 128
  mul ebx
  add esi, eax
  mov edi, token
  call b_string_compare
  je .on_to_then
  jmp .finish_line
.second_is_string_var:
  mov esi, string_vars
  mov eax, 128
  mul ebx
  add esi, eax
  mov edi, string_vars
  mov ebx, 0
  mov byte bl, [.tmp_string_var]
  mov eax, 128
  mul ebx
  add edi, eax
  call b_string_compare
  jc .on_to_then
  jmp .finish_line
.on_to_then:
  call get_token
  mov esi, token
  mov edi, then_keyword
  call b_string_compare
  jc .then_present
  mov esi, err_syntax
  jmp error
.then_present:                          ; Continue rest of line like any other command!
  jmp mainloop
.finish_line:                           ; IF wasn't fulfilled, so skip rest of line
  mov dword esi, [prog]
  mov byte al, [esi]
  inc dword [prog]
  cmp al, 10
  jne .finish_line
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
.tmp_string_var db 0
; ------------------------------------------------------------------
; INPUT
do_input:
  mov al, 0                             ; Clear string from previous usage
  mov edi, .tmpstring
  mov ecx, 128
  rep stosb
  call get_token
  cmp eax, VARIABLE                     ; We can only INPUT to variables!
  je .number_var
  cmp eax, STRING_VAR
  je .string_var
  mov esi, err_syntax
  jmp error
.number_var:
  mov rdi, .tmpstring                   ; Get input from the user
  call b_input_string
  mov rsi, .tmpstring
  call b_string_length
  cmp rcx, 0
  jne .char_entered
  mov byte [.tmpstring], '0'            ; If enter hit, fill variable with zero
  mov byte [.tmpstring + 1], 0
.char_entered:
  mov esi, .tmpstring                   ; Convert to integer format
  call b_string_to_int
  mov ebx, eax
  mov eax, 0
  mov byte al, [token]                  ; Get the variable where we're storing it...
  call set_var                          ; ...and store it!
  call b_print_newline
  jmp mainloop
.string_var:
  push rbx
  mov rdi, .tmpstring
  mov rcx, 120				; Limit to max of 120 chars
  call b_input_string
  mov esi, .tmpstring
  mov edi, string_vars
  pop rbx
  mov eax, 128
  mul ebx
  add edi, eax
  call b_string_copy
  call b_print_newline
  jmp mainloop
.tmpstring: times 128 db 0
; ------------------------------------------------------------------
;; LOAD
;do_load:
;  call get_token
;  cmp eax, QUOTE
;  je .is_quote
;  cmp eax, STRING_VAR
;  jne .error
;  mov esi, string_vars
;  mov eax, 128
;  mul ebx
;  add esi, eax
;  jmp .get_position
;.is_quote:
;  mov esi, token
;.get_position:
;  mov eax, esi
;  call b_file_exists
;  jc .file_not_exists
;  mov edx, eax                          ; Store for now
;  call get_token
;  cmp eax, VARIABLE
;  je .second_is_var
;  cmp eax, NUMBER
;  jne .error
;  mov esi, token
;  call b_string_to_int
;.load_part:
;  mov ecx, eax
;  mov eax, edx
;  call b_load_file
;  mov eax, 0
;  mov byte al, 'S'
;  call set_var
;  mov eax, 0
;  mov byte al, 'R'
;  mov ebx, 0
;  call set_var
;  jmp mainloop
;.second_is_var:
;  mov eax, 0
;  mov byte al, [token]
;  call get_var
;  jmp .load_part
;.file_not_exists:
;  mov eax, 0
;  mov byte al, 'R'
;  mov ebx, 1
;  call set_var
;  call get_token                        ; Skip past the loading point -- unnecessary now
;  jmp mainloop
;.error:
;  mov esi, err_syntax
;  jmp error
; ------------------------------------------------------------------
; MOVE
do_move:
  call get_token
  cmp eax, VARIABLE
  je .first_is_var
  mov esi, token
  call b_string_to_int
  mov dl, al
  jmp .onto_second
.first_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov dl, al
.onto_second:
  call get_token
  cmp eax, VARIABLE
  je .second_is_var
  mov esi, token
  call b_string_to_int
  mov dh, al
  jmp .finish
.second_is_var:
  mov eax, 0
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
  cmp eax, VARIABLE                     ; NEXT must be followed by a variable
  jne .error
  mov eax, 0
  mov byte al, [token]
  call get_var
  inc eax                               ; NEXT increments the variable, of course!
  mov ebx, eax
  mov eax, 0
  mov byte al, [token]
  sub al, 65
  mov esi, for_variables
  add esi, eax
  add esi, eax
  lodsw                                 ; Get the target number from the table
  inc eax                               ; (Make the loop inclusive of target number)
  cmp eax, ebx                          ; Do the variable and target match?
  je .loop_finished
  mov eax, 0                            ; If not, store the updated variable
  mov byte al, [token]
  call set_var
  mov eax, 0                            ; Find the code point and go back
  mov byte al, [token]
  sub al, 65
  mov esi, for_code_points
  add esi, eax
  add esi, eax
  lodsw
  mov dword [prog], eax
  jmp mainloop
.loop_finished:
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
; ------------------------------------------------------------------
; PAUSE
do_pause:
  call get_token
  cmp eax, VARIABLE
  je .is_var
  mov esi, token
  call b_string_to_int
  jmp .finish
.is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
.finish:
  call b_delay
  jmp mainloop
; ------------------------------------------------------------------
; PEEK
do_peek:
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov eax, 0
  mov byte al, [token]
  mov byte [.tmp_var], al
  call get_token
  cmp eax, VARIABLE
  je .dereference
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
.store:
  mov esi, eax
  mov ebx, 0
  mov byte bl, [esi]
  mov eax, 0
  mov byte al, [.tmp_var]
  call set_var
  jmp mainloop
.dereference:
  mov byte al, [token]
  call get_var
  jmp .store
.error:
  mov esi, err_syntax
  jmp error
.tmp_var db 0
; ------------------------------------------------------------------
; POKE
do_poke:
  call get_token
  cmp eax, VARIABLE
  je .first_is_var
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
  cmp eax, 255
  jg .error
  mov byte [.first_value], al
  jmp .onto_second
.first_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov byte [.first_value], al
.onto_second:
  call get_token
  cmp eax, VARIABLE
  je .second_is_var
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
.got_value:
  mov edi, eax
  mov eax, 0
  mov byte al, [.first_value]
  mov byte [edi], al
  jmp mainloop
.second_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
  jmp .got_value
.error:
  mov esi, err_syntax
  jmp error
.first_value db 0
; ------------------------------------------------------------------
; PORT
do_port:
  call get_token
  mov esi, token
  mov edi, .out_cmd
  call b_string_compare
  jc .do_out_cmd
  mov edi, .in_cmd
  call b_string_compare
  jc .do_in_cmd
  jmp .error
.do_out_cmd:
  call get_token
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int                 ; Now EAX = port number
  mov edx, eax
  call get_token
  cmp eax, NUMBER
  je .out_is_num
  cmp eax, VARIABLE
  je .out_is_var
  jmp .error
.out_is_num:
  mov esi, token
  call b_string_to_int
;  call b_port_byte_out
  jmp mainloop
.out_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
;  call b_port_byte_out
  jmp mainloop
.do_in_cmd:
  call get_token
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
  mov edx, eax
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov byte cl, [token]
;  call b_port_byte_in
  mov ebx, 0
  mov bl, al
  mov al, cl
  call set_var
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
.out_cmd db "OUT", 0
.in_cmd db "IN", 0
; ------------------------------------------------------------------
; PRINT
do_print:
  call get_token                        ; Get part after PRINT
  cmp eax, QUOTE                        ; What type is it?
  je .print_quote
  cmp eax, VARIABLE                     ; Numerical variable (eg X)
  je .print_var
  cmp eax, STRING_VAR                   ; String variable (eg $1)
  je .print_string_var
  cmp eax, STRING                       ; Special keyword (eg CHR or HEX)
  je .print_keyword
  mov esi, err_print_type               ; We only print quoted strings and vars!
  jmp error
.print_var:
  mov eax, 0
  mov byte al, [token]
  call get_var                          ; Get its value
  call b_int_to_string                 ; Convert to string
  mov esi, eax
  call b_print_string
  jmp .newline_or_not
.print_quote:                           ; If it's quoted text, print it
  mov esi, token
  call b_print_string
  jmp .newline_or_not
.print_string_var:
  mov esi, string_vars
  mov eax, 128
  mul ebx
  add esi, eax
  call b_print_string
  jmp .newline_or_not
.print_keyword:
  mov esi, token
  mov edi, chr_keyword
  call b_string_compare
  jc .is_chr
  mov edi, hex_keyword
  call b_string_compare
  jc .is_hex
  mov esi, err_syntax
  jmp error
.is_chr:
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov eax, 0
  mov byte al, [token]
  call get_var
  mov ah, 0Eh
  int 10h
  jmp .newline_or_not
.is_hex:
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov eax, 0
  mov byte al, [token]
  call get_var
  call b_debug_dump_ax
  jmp .newline_or_not
.error:
  mov esi, err_syntax
  jmp error
.newline_or_not:
                                        ; We want to see if the command ends with ';' -- which means that
                                        ; we shouldn't print a newline after it finishes. So we store the
                                        ; current program location to pop ahead and see if there's the ';'
                                        ; character -- otherwise we put the program location back and resume
                                        ; the main loop
xchg bx, bx
  mov dword eax, [prog]
  mov dword [.tmp_loc], eax
  call get_token
  cmp eax, UNKNOWN
  jne .ignore
  mov eax, 0
  mov al, [token]
  cmp al, ';'
  jne .ignore
  jmp mainloop                          ; And go back to interpreting the code!
.ignore:
  call b_print_newline
  mov dword eax, [.tmp_loc]
  mov dword [prog], eax
  jmp mainloop
.tmp_loc dd 0
; ------------------------------------------------------------------
; RAND
do_rand:
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov byte al, [token]
  mov byte [.tmp], al
  call get_token
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
  mov dword [.num1], eax
  call get_token
  cmp eax, NUMBER
  jne .error
  mov esi, token
  call b_string_to_int
  mov dword [.num2], eax
  mov dword eax, [.num1]
  mov dword ebx, [.num2]
 ; call b_get_random
  mov ebx, ecx
  mov eax, 0
  mov byte al, [.tmp]
  call set_var
  jmp mainloop
.tmp db 0
.num1 dd 0
.num2 dd 0
.error:
  mov esi, err_syntax
  jmp error
; ------------------------------------------------------------------
; REM
do_rem:
  mov dword esi, [prog]
  mov byte al, [esi]
  inc dword [prog]
  cmp al, 10                            ; Find end of line after REM
  jne do_rem
  jmp mainloop
; ------------------------------------------------------------------
; RETURN
do_return:
  mov eax, 0
  mov byte al, [gosub_depth]
  cmp al, 0
  jne .is_ok
  mov esi, err_return
  jmp error
.is_ok:
  mov esi, gosub_points
  add esi, eax                          ; Table is words (not bytes)
  add esi, eax
  lodsw
  mov dword [prog], eax
  dec byte [gosub_depth]
  jmp mainloop
; ------------------------------------------------------------------
;; SAVE
;do_save:
;  call get_token
;  cmp eax, QUOTE
;  je .is_quote
;  cmp eax, STRING_VAR
;  jne near .error
;  mov esi, string_vars
;  mov eax, 128
;  mul ebx
;  add esi, eax
;  jmp .get_position
;.is_quote:
;  mov esi, token
;.get_position:
;  mov edi, .tmp_filename
;  call b_string_copy
;  call get_token
;  cmp eax, VARIABLE
;  je .second_is_var
;  cmp eax, NUMBER
;  jne .error
;  mov esi, token
;  call b_string_to_int
;.set_data_loc:
;  mov dword [.data_loc], eax
;  call get_token
;  cmp eax, VARIABLE
;  je .third_is_var
;  cmp eax, NUMBER
;  jne .error
;  mov esi, token
;  call b_string_to_int
;.set_data_size:
;  mov dword [.data_size], eax
;  mov dword eax, .tmp_filename
;  mov dword ebx, [.data_loc]
;  mov dword ecx, [.data_size]
;  call b_write_file
;  jc .save_failure
;  mov eax, 0
;  mov byte al, 'R'
;  mov ebx, 0
;  call set_var
;  jmp mainloop
;.second_is_var:
;  mov eax, 0
;  mov byte al, [token]
;  call get_var
;  jmp .set_data_loc
;.third_is_var:
;  mov eax, 0
;  mov byte al, [token]
;  call get_var
;  jmp .set_data_size
;.save_failure:
;  mov eax, 0
;  mov byte al, 'R'
;  mov ebx, 1
;  call set_var
;  jmp mainloop
;.error:
;  mov esi, err_syntax
;  jmp error
;.filename_loc dd 0
;.data_loc dd 0
;.data_size dd 0
;.tmp_filename: times 15 db 0
; ------------------------------------------------------------------
; SERIAL
do_serial:
  call get_token
  mov esi, token
  mov edi, .on_cmd
  call b_string_compare
  jc .do_on_cmd
  mov edi, .send_cmd
  call b_string_compare
  jc .do_send_cmd
  mov edi, .rec_cmd
  call b_string_compare
  jc .do_rec_cmd
  jmp .error
.do_on_cmd:
  call get_token
  cmp eax, NUMBER
  je .do_on_cmd_ok
  jmp .error
.do_on_cmd_ok:
  mov esi, token
  call b_string_to_int
  cmp eax, 1200
  je .on_cmd_slow_mode
  cmp eax, 9600
  je .on_cmd_fast_mode
  jmp .error
.on_cmd_fast_mode:
  mov eax, 0
 ; call b_serial_port_enable
  jmp mainloop
.on_cmd_slow_mode:
  mov eax, 1
;  call b_serial_port_enable
  jmp mainloop
.do_send_cmd:
  call get_token
  cmp eax, NUMBER
  je .send_number
  cmp eax, VARIABLE
  je .send_variable
  jmp .error
.send_number:
  mov esi, token
  call b_string_to_int
  call b_serial_send
  jmp mainloop
.send_variable:
  mov eax, 0
  mov byte al, [token]
  call get_var
  call b_serial_send
  jmp mainloop
.do_rec_cmd:
  call get_token
  cmp eax, VARIABLE
  jne .error
  mov byte al, [token]
  mov ecx, 0
  mov cl, al
  call b_serial_recv
  mov ebx, 0
  mov bl, al
  mov al, cl
  call set_var
  jmp mainloop
.error:
  mov esi, err_syntax
  jmp error
.on_cmd db "ON", 0
.send_cmd db "SEND", 0
.rec_cmd db "REC", 0
; ------------------------------------------------------------------
; SOUND
do_sound:
  call get_token
  cmp eax, VARIABLE
  je .first_is_var
  mov esi, token
  call b_string_to_int
  jmp .done_first
.first_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
.done_first:
  call b_speaker_tone
  call get_token
  cmp eax, VARIABLE
  je .second_is_var
  mov esi, token
  call b_string_to_int
  jmp .finish
.second_is_var:
  mov eax, 0
  mov byte al, [token]
  call get_var
.finish:
  call b_delay
  call b_speaker_off
  jmp mainloop
; ------------------------------------------------------------------
; WAITKEY
do_waitkey:
  call get_token
  cmp eax, VARIABLE
  je .is_variable
  mov esi, err_syntax
  jmp error
.is_variable:
  mov eax, 0
  mov byte al, [token]
  push rax
  call b_input_key_wait
  cmp eax, 48E0h
  je .up_pressed
  cmp eax, 50E0h
  je .down_pressed
  cmp eax, 4BE0h
  je .left_pressed
  cmp eax, 4DE0h
  je .right_pressed
.store:
  mov ebx, 0
  mov bl, al
  pop rax
  call set_var
  jmp mainloop
.up_pressed:
  mov eax, 1
  jmp .store
.down_pressed:
  mov eax, 2
  jmp .store
.left_pressed:
  mov eax, 3
  jmp .store
.right_pressed:
  mov eax, 4
  jmp .store
; ==================================================================
; INTERNAL ROUTINES FOR INTERPRETER
; ------------------------------------------------------------------
; Get value of variable character specified in AL (eg 'A')
get_var:
  sub al, 65
  mov esi, variables
  add esi, eax
  add esi, eax
  lodsw
  ret
; ------------------------------------------------------------------
; Set value of variable character specified in AL (eg 'A')
; with number specified in EBX
set_var:
  mov ah, 0
  sub al, 65                            ; Remove ASCII codes before 'A'
  mov edi, variables                    ; Find position in table (of words)
  add edi, eax
  add edi, eax
  mov eax, ebx
  stosw
  ret
; ------------------------------------------------------------------
; Get token from current position in prog
get_token:
  mov dword esi, [prog]
  lodsb
  cmp al, 10
  je .newline
  cmp al, 13          ;allow for CRLF
  je .newline
  cmp al, ' '
  je .newline
  call is_number
  jc get_number_token
  cmp al, '"'
  je get_quote_token
  cmp al, 39                            ; Quote mark (')
  je get_char_token
  cmp al, '$'
  je near get_string_var_token
  jmp get_string_token
.newline:
  inc dword [prog]
  jmp get_token
get_number_token:
  mov dword esi, [prog]
  mov edi, token
.loop:
  lodsb
  cmp al, 10
  je .done
  cmp al, 13          ;allow for CRLF
  je .done
  cmp al, ' '
  je .done
  call is_number
  jc .fine
  mov esi, err_char_in_num
  jmp error
.fine:
  stosb
  inc dword [prog]
  jmp .loop
.done:
  mov al, 0                             ; Zero-terminate the token
  stosb
  mov eax, NUMBER                       ; Pass back the token type
  ret
get_char_token:
  inc dword [prog]                      ; Move past first quote (')
  mov dword esi, [prog]
  lodsb
  mov byte [token], al
  lodsb
  cmp al, 39                            ; Needs to finish with another quote
  je .is_ok
  mov esi, err_quote_term
  jmp error
.is_ok:
  inc dword [prog]
  inc dword [prog]
  mov eax, CHAR
  ret
get_quote_token:
  inc dword [prog]                      ; Move past first quote (") char
  mov dword esi, [prog]
  mov edi, token
.loop:
  lodsb
  cmp al, '"'
  je .done
  cmp al, 10
  je .error
  stosb
  inc dword [prog]
  jmp .loop
.done:
  mov al, 0                             ; Zero-terminate the token
  stosb
  inc dword [prog]                      ; Move past final quote
  mov eax, QUOTE                        ; Pass back token type
  ret
.error:
  mov esi, err_quote_term
  jmp error
get_string_var_token:
  lodsb
  mov ebx, 0                            ; If it's a string var, pass number of string in EBX
  mov bl, al
  sub bl, 49
  inc dword [prog]
  inc dword [prog]
  mov eax, STRING_VAR
  ret

get_string_token:
  mov dword esi, [prog]
  mov edi, token
.loop:
  lodsb
  cmp al, 10
  je .done
  cmp al, 13          ;allow for CRLF
  je .done
  cmp al, ' '
  je .done
  stosb
  inc dword [prog]
  jmp .loop
.done:
  mov al, 0                             ; Zero-terminate the token
  stosb
  mov eax, token
  call b_string_uppercase
  mov eax, token
  call b_string_length                 ; How long was the token?
  cmp eax, 1                            ; If 1 char, it's a variable or delimiter
  je .is_not_string
  mov esi, token                        ; If the token ends with ':', it's a label
  add esi, eax
  dec esi
  lodsb
  cmp al, ':'
  je .is_label
  mov eax, STRING                       ; Otherwise it's a general string of characters
  ret
.is_label:
  mov eax, LABEL
  ret
.is_not_string:
  mov byte al, [token]
  call is_letter
  jc .is_var
  mov eax, UNKNOWN
  ret
.is_var:
  mov eax, VARIABLE                     ; Otherwise probably a variable
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
  call b_print_string                  ; Print error message
  call b_print_newline
  mov dword esp, [orig_stack]           ; Restore the stack to as it was when BASIC started
  ret                                   ; And finish
; ------------------------------------------------------------------



                                        ; Error messages text...
err_char_in_num db "Error: unexpected character in number", 0
err_quote_term db "Error: quoted string or character not terminated correctly", 0
err_print_type db "Error: PRINT command not followed by quoted text or variable", 0
err_cmd_unknown db "Error: unknown command", 0
err_goto_notlabel db "Error: GOTO or GOSUB not followed by label", 0
err_label_notfound db "Error: GOTO or GOSUB label not found", 0
err_return db "Error: RETURN without GOSUB", 0
err_nest_limit db "Error: FOR or GOSUB nest limit exceeded", 0
err_next db "Error: NEXT without FOR", 0
err_syntax db "Error: syntax error", 0
; ==================================================================
; DATA SECTION
orig_stack dd 0                         ; Original stack location when BASIC started
prog dd 0                               ; Pointer to current location in BASIC code
prog_end dd 0                           ; Pointer to final byte of BASIC code
load_point dd 0
token_type db 0                         ; Type of last token read (eg NUMBER, VARIABLE)
token: times 255 db 0                   ; Storage space for the token
variables: times 26 dd 0                ; Storage space for variables A to Z
for_variables: times 26 dd 0            ; Storage for FOR loops
for_code_points: times 26 dd 0          ; Storage for code positions where FOR loops start
alert_cmd db "ALERT", 0
call_cmd db "CALL", 0
cls_cmd db "CLS", 0
cursor_cmd db "CURSOR", 0
curschar_cmd db "CURSCHAR", 0
end_cmd db "END", 0
for_cmd db "FOR", 0
gosub_cmd db "GOSUB", 0
goto_cmd db "GOTO", 0
getkey_cmd db "GETKEY", 0
if_cmd db "IF", 0
input_cmd db "INPUT", 0
load_cmd db "LOAD", 0
move_cmd db "MOVE", 0
next_cmd db "NEXT", 0
pause_cmd db "PAUSE", 0
peek_cmd db "PEEK", 0
poke_cmd db "POKE", 0
port_cmd db "PORT", 0
print_cmd db "PRINT", 0
rem_cmd db "REM", 0
rand_cmd db "RAND", 0
return_cmd db "RETURN", 0
save_cmd db "SAVE", 0
serial_cmd db "SERIAL", 0
sound_cmd db "SOUND", 0
waitkey_cmd db "WAITKEY", 0
then_keyword db "THEN", 0
chr_keyword db "CHR", 0
hex_keyword db "HEX", 0
progstart_keyword db "PROGSTART", 0
ramstart_keyword db "RAMSTART", 0
gosub_depth db 0
gosub_points: times 10 dd 0             ; Points in code to RETURN to
string_vars: times 1024 db 0            ; 8 * 128 byte strings
; ------------------------------------------------------------------
basic_prog:
 DB 'CLS',13,10
 DB 'PRINT "Please type your name: ";',13,10
 DB 'INPUT $N',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT "Hello "',13,10
 DB 'PRINT $N',13,10
 DB 'PRINT ", welcome to MikeOS Basic!"',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT "It supports FOR...NEXT loops and simple integer maths..."',13,10
 DB 'PRINT ""',13,10
 DB 'FOR I = 1 TO 15',13,10
 DB 'J = I * I',13,10
 DB 'K = J * I',13,10
 DB 'L = K * I',13,10
 DB 'PRINT I',13,10
 DB 'PRINT "        "',13,10
 DB 'PRINT J',13,10
 DB 'PRINT "        "',13,10
 DB 'PRINT K',13,10
 DB 'PRINT "        "',13,10
 DB 'PRINT L',13,10
 DB 'NEXT I',13,10
 DB 'PRINT ""',13,10
 DB 'PRINT " ...and IF...THEN and GOSUB and lots of other stuff. Bye!"',13,10
 DB 'END',13,10
