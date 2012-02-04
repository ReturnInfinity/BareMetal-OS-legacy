; =============================================================================
; BareMetal -- a 64-bit OS written in Assembly for x86-64 systems
; Copyright (C) 2008-2012 Return Infinity -- see LICENSE.TXT
;
; String Functions
; =============================================================================

align 16
db 'DEBUG: STRING   '
align 16


; -----------------------------------------------------------------------------
; os_int_to_string -- Convert a binary interger into an string
;  IN:	RAX = binary integer
;	RDI = location to store string
; OUT:	RDI = points to end of string
;	All other registers preserved
; Min return value is 0 and max return value is 18446744073709551615 so your
; string needs to be able to store at least 21 characters (20 for the digits
; and 1 for the string terminator).
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/rax2uint.s
os_int_to_string:
	push rdx
	push rcx
	push rbx
	push rax

	mov rbx, 10					; base of the decimal system
	xor ecx, ecx					; number of digits generated
os_int_to_string_next_divide:
	xor edx, edx					; RAX extended to (RDX,RAX)
	div rbx						; divide by the number-base
	push rdx					; save remainder on the stack
	inc rcx						; and count this remainder
	cmp rax, 0					; was the quotient zero?
	jne os_int_to_string_next_divide		; no, do another division

os_int_to_string_next_digit:
	pop rax						; else pop recent remainder
	add al, '0'					; and convert to a numeral
	stosb						; store to memory-buffer
	loop os_int_to_string_next_digit		; again for other remainders
	xor al, al
	stosb						; Store the null terminator at the end of the string

	pop rax
	pop rbx
	pop rcx
	pop rdx
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_to_int -- Convert a string into a binary interger
;  IN:	RSI = location of string
; OUT:	RAX = integer value
;	All other registers preserved
; Adapted from http://www.cs.usfca.edu/~cruse/cs210s09/uint2rax.s
os_string_to_int:
	push rsi
	push rdx
	push rcx
	push rbx

	xor eax, eax			; initialize accumulator
	mov rbx, 10			; decimal-system's radix
os_string_to_int_next_digit:
	mov cl, [rsi]			; fetch next character
	cmp cl, '0'			; char preceeds '0'?
	jb os_string_to_int_invalid	; yes, not a numeral
	cmp cl, '9'			; char follows '9'?
	ja os_string_to_int_invalid	; yes, not a numeral
	mul rbx				; ten times prior sum
	and rcx, 0x0F			; convert char to int
	add rax, rcx			; add to prior total
	inc rsi				; advance source index
	jmp os_string_to_int_next_digit	; and check another char
	
os_string_to_int_invalid:
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_int_to_hex_string -- Convert an integer to a hex string
;  IN:	RAX = Integer value
;	RDI = location to store string
; OUT:	All registers preserved
os_int_to_hex_string:
	push rdi
	push rdx
	push rcx
	push rbx
	push rax

	mov rcx, 16				; number of nibbles. 64 bit = 16 nibbles = 8 bytes
os_int_to_hex_string_next_nibble:	
	rol rax, 4				; next nibble into AL
	mov bl, al				; copy nibble into BL
	and rbx, 0x0F				; and convert to word
	mov dl, [hextable + rbx]		; lookup ascii numeral
	push rax
	mov al, dl
	stosb
	pop rax
	loop os_int_to_hex_string_next_nibble	; again for next nibble
	xor eax, eax				; clear RAX to 0
	stosb					; Store AL to terminate string

	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_hex_string_to_int -- Convert up to 8 hexascii to bin
;  IN:	RSI = Location of hex asciiz string
; OUT:	RAX = binary value of hex string
;	All other registers preserved
os_hex_string_to_int:
	push rsi
	push rcx
	push rbx

	cld
	xor ebx, ebx
os_hex_string_to_int_loop:
	lodsb
	mov cl, 4
	cmp al, 'a'
	jb os_hex_string_to_int_ok
	sub al, 0x20				; convert to upper case if alpha
os_hex_string_to_int_ok:
	sub al, '0'				; check if legal
	jc os_hex_string_to_int_exit		; jmp if out of range
	cmp al, 9
	jle os_hex_string_to_int_got		; jmp if number is 0-9
	sub al, 7				; convert to number from A-F or 10-15
	cmp al, 15				; check if legal
	ja os_hex_string_to_int_exit		; jmp if illegal hex char
os_hex_string_to_int_got:
	shl rbx, cl
	or bl, al
	jmp os_hex_string_to_int_loop
os_hex_string_to_int_exit:
	mov rax, rbx				; int value stored in RBX, move to RAX

	pop rbx
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_length -- Return length of a string
;  IN:	RSI = string location
; OUT:	RCX = length (not including the NULL terminator)
;	All other registers preserved
os_string_length:
	push rdi
	push rax

	xor ecx, ecx
	xor eax, eax
	mov rdi, rsi
	not rcx
	cld
	repne scasb	; compare byte at RDI to value in AL
	not rcx
	dec rcx

	pop rax
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_find_char -- Find first location of character in a string
;  IN:	RSI = string location
;	AL  = character to find
; OUT:	RAX = location in string, or 0 if char not present
;	All other registers preserved
os_string_find_char:
	push rsi
	push rcx

	mov rcx, 1		; Counter -- start at first char
os_string_find_char_more:
	cmp byte [rsi], al
	je os_string_find_char_done
	cmp byte [rsi], 0
	je os_string_find_char_not_found
	inc rsi
	inc rcx
	jmp os_string_find_char_more

os_string_find_char_done:
	mov rax, rcx

	pop rcx
	pop rsi
	ret

os_string_find_char_not_found:
	pop rcx
	pop rsi
	xor eax, eax	; not found, set RAX to 0
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_change_char -- Change all instances of a character in a string
;  IN:	RSI = string location
;	AL  = character to replace
;	BL  = replacement character
; OUT:	All registers preserved
os_string_change_char:
	push rsi
	push rcx
	push rbx
	push rax

	mov cl, al
os_string_change_char_loop:
	mov byte al, [rsi]
	cmp al, 0
	je os_string_change_char_done
	cmp al, cl
	jne os_string_change_char_no_change
	mov byte [rsi], bl

os_string_change_char_no_change:
	inc rsi
	jmp os_string_change_char_loop

os_string_change_char_done:
	pop rax
	pop rbx
	pop rcx
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_copy -- Copy the contents of one string into another
;  IN:	RSI = source
;	RDI = destination
; OUT:	All registers preserved
; Note:	It is up to the programmer to ensure that there is sufficient space in the destination
os_string_copy:
	push rsi
	push rdi
	push rax

os_string_copy_more:
	lodsb				; Load a character from the source string
	stosb
	cmp al, 0			; If source string is empty, quit out
	jne os_string_copy_more

	pop rax
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_truncate -- Chop string down to specified number of characters
;  IN:	RSI = string location
;	RAX = number of characters
; OUT:	All registers preserved
os_string_truncate:
	push rsi

	add rsi, rax
	mov byte [rsi], 0x00

	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
;  IN:	RAX = string one
;	RBX = string two
;	RDI = destination string
; OUT:	All registers preserved
; Note:	It is up to the programmer to ensure that there is sufficient space in the destination
os_string_join:
	push rsi
	push rdi
	push rcx
	push rbx
	push rax

	mov rsi, rax		; Copy first string to location in RDI
	call os_string_copy
	call os_string_length	; Get length of first string
	add rdi, rcx		; Position at end of first string
	mov rsi, rbx		; Add second string onto it
	call os_string_copy

	pop rax
	pop rbx
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_append -- Append a string to an existing string
;  IN:	RSI = String to be appended
;	RDI = Destination string
; OUT:	All registers preserved
; Note:	It is up to the programmer to ensure that there is sufficient space in the destination
os_string_append:
	push rsi
	push rdi
	push rcx

	xchg rsi, rdi
	call os_string_length
	xchg rsi, rdi
	add rdi, rcx
	call os_string_copy

	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_chomp -- Strip leading and trailing spaces from a string
;  IN:	RSI = string location
; OUT:	All registers preserved
os_string_chomp:
	push rsi
	push rdi
	push rcx
	push rax

	call os_string_length		; Quick check to see if there are any characters in the string
	jrcxz os_string_chomp_done	; No need to work on it if there is no data

	mov rdi, rsi			; RDI will point to the start of the string...
	push rdi			; ...while RSI will point to the "actual" start (without the spaces)
	add rdi, rcx			; os_string_length stored the length in RCX

os_string_chomp_findend:		; we start at the end of the string and move backwards until we don't find a space
	dec rdi
	cmp rsi, rdi			; Check to make sure we are not reading backward past the string start
	jg os_string_chomp_fail		; If so then fail (string only contained spaces)
	cmp byte [rdi], ' '
	je os_string_chomp_findend

	inc rdi				; we found the real end of the string so null terminate it
	mov byte [rdi], 0x00
	pop rdi

os_string_chomp_start_count:		; read through string until we find a non-space character
	cmp byte [rsi], ' '
	jne os_string_chomp_copy
	inc rsi
	jmp os_string_chomp_start_count

os_string_chomp_fail:			; In this situataion the string is all spaces
	pop rdi				; We are about to bail out so make sure the stack is sane
	mov al, 0x00
	stosb
	jmp os_string_chomp_done

; At this point RSI points to the actual start of the string (minus the leading spaces, if any)
; And RDI point to the start of the string

os_string_chomp_copy:		; Copy a byte from RSI to RDI one byte at a time until we find a NULL
	lodsb
	stosb
	cmp al, 0x00
	jne os_string_chomp_copy

os_string_chomp_done:
	pop rax
	pop rcx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_strip -- Removes specified character from a string
;  IN:	RSI = string location
;	AL  = character to remove
; OUT:	All registers preserved
os_string_strip:
	push rsi
	push rdi
	push rbx
	push rax

	mov rdi, rsi
	mov bl, al			; copy the char into BL since LODSB and STOSB use AL
os_string_strip_nextchar:
	lodsb
	stosb
	cmp al, 0x00			; check if we reached the end of the string
	je os_string_strip_done		; if so bail out
	cmp al, bl			; check to see if the character we read is the interesting char
	jne os_string_strip_nextchar	; if not skip to the next character

os_string_strip_skip:			; if so the fall through to here
	dec rdi				; decrement RDI so we overwrite on the next pass
	jmp os_string_strip_nextchar

os_string_strip_done:
	pop rax
	pop rbx
	pop rdi
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_compare -- See if two strings match
;  IN:	RSI = string one
;	RDI = string two
; OUT:	Carry flag set if same
os_string_compare:
	push rsi
	push rdi
	push rbx
	push rax

os_string_compare_more:
	mov al, [rsi]			; Store string contents
	mov bl, [rdi]
	cmp al, 0			; End of first string?
	je os_string_compare_terminated
	cmp al, bl
	jne os_string_compare_not_same
	inc rsi
	inc rdi
	jmp os_string_compare_more

os_string_compare_not_same:
	pop rax
	pop rbx
	pop rdi
	pop rsi
	clc
	ret

os_string_compare_terminated:
	cmp bl, 0			; End of second string?
	jne os_string_compare_not_same

	pop rax
	pop rbx
	pop rdi
	pop rsi
	stc
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to uppercase
;  IN:	RSI = string location
; OUT:	All registers preserved
os_string_uppercase:
	push rsi

os_string_uppercase_more:
	cmp byte [rsi], 0x00		; Zero-termination of string?
	je os_string_uppercase_done	; If so, quit
	cmp byte [rsi], 97		; In the uppercase A to Z range?
	jl os_string_uppercase_noatoz
	cmp byte [rsi], 122
	jg os_string_uppercase_noatoz
	sub byte [rsi], 0x20		; If so, convert input char to uppercase
	inc rsi
	jmp os_string_uppercase_more

os_string_uppercase_noatoz:
	inc rsi
	jmp os_string_uppercase_more

os_string_uppercase_done:
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_lowercase -- Convert zero-terminated string to lowercase
;  IN:	RSI = string location
; OUT:	All registers preserved
os_string_lowercase:
	push rsi

os_string_lowercase_more:
	cmp byte [rsi], 0x00		; Zero-termination of string?
	je os_string_lowercase_done	; If so, quit
	cmp byte [rsi], 65		; In the lowercase A to Z range?
	jl os_string_lowercase_noatoz
	cmp byte [rsi], 90
	jg os_string_lowercase_noatoz
	add byte [rsi], 0x20		; If so, convert input char to lowercase
	inc rsi
	jmp os_string_lowercase_more

os_string_lowercase_noatoz:
	inc rsi
	jmp os_string_lowercase_more

os_string_lowercase_done:
	pop rsi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_time_string -- Store the current time in a string in format "HH:MM:SS"
;  IN:	RDI = location to store string (must be able to fit 9 bytes, 8 data plus null terminator)
; OUT:	All registers preserved
os_get_time_string:
	push rdi
	push rbx
	push rax

os_get_time_string_wait:
	mov al, 10
	out 0x70, al
	in al, 0x71
	test al, 0x80			; Is there an update in progress?
	jne os_get_time_string_wait	; If so then try again
	mov al, 0x04			; Hours
	out 0x70, al
	xor eax, eax
	in al, 0x71
	cmp al, 9
	jg os_get_time_string_lead_hours
	call os_leading_zero
os_get_time_string_lead_hours:
	call os_int_to_string
	sub rdi, 1
	mov al, ':'
	stosb
	mov al, 0x02			; Minutes
	out 0x70, al
	xor eax, eax
	in al, 0x71
	cmp al, 9
	jg os_get_time_string_lead_minutes
	call os_leading_zero
os_get_time_string_lead_minutes:
	call os_int_to_string
	sub rdi, 1
	mov al, ':'
	stosb
	mov al, 0x00			; Seconds
	out 0x70, al
	xor eax, eax
	in al, 0x71
	cmp al, 9
	jg os_get_time_string_lead_seconds
	call os_leading_zero
os_get_time_string_lead_seconds:
	call os_int_to_string
	stosb

	pop rax
	pop rbx
	pop rdi
	ret

os_leading_zero:
	push ax
	mov al, '0'
	stosb
	pop ax
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_get_date_string -- Store the current time in a string in format "YYYY/MM/DD"
;  IN:	RDI = location to store string (must be able to fit 11 bytes, 10 data plus null terminator)
; OUT:	All registers preserved
; Note:	Uses the os_get_time_string_processor function
os_get_date_string:
	push rdi
	push rbx
	push rax

os_get_date_string_wait:
	mov al, 10
	out 0x70, al
	in al, 0x71
	test al, 0x80			; Is there an update in progress?
	jne os_get_date_string_wait	; If so then try again
;	mov al, 0x32			; Century
;	out 0x70, al
	xor eax, eax
;	in al, 0x71
	mov al, 20
	call os_int_to_string
	sub rdi, 1
	mov al, 0x09			; Year
	out 0x70, al
	xor eax, eax
	in al, 0x71
	call os_int_to_string
	sub rdi, 1
	mov al, '/'
	stosb
	mov al, 0x08			; Month
	out 0x70, al
	xor eax, eax
	in al, 0x71
	call os_int_to_string
	sub rdi, 1
	mov al, '/'
	stosb
	mov al, 0x07			; Day
	out 0x70, al
	xor eax, eax
	in al, 0x71
	call os_int_to_string
;	sub rdi, 1
;	mov al, 0x00			; Terminate the string
	stosb

	pop rax
	pop rbx
	pop rdi
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_is_digit -- Check if character is a digit
;  IN:	AL  = ASCII char
; OUT:	EQ flag set if numeric
; Note:	JE (Jump if Equal) can be used after this function is called
os_is_digit:
	cmp al, '0'
	jb os_is_digit_not_digit
	cmp al, '9'
	ja os_is_digit_not_digit
	cmp al, al			; To set the equal flag

os_is_digit_not_digit:
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_is_alpha -- Check if character is a letter
;  IN:	AL  = ASCII char
; OUT:	EQ flag set if alpha
; Note:	JE (Jump if Equal) can be used after this function is called
os_is_alpha:
	cmp al, ' '
	jb os_is_alpha_not_alpha
	cmp al, 0x7E
	ja os_is_alpha_not_alpha
	cmp al, al			; To set the equal flag

os_is_alpha_not_alpha:
	ret
; -----------------------------------------------------------------------------


; -----------------------------------------------------------------------------
; os_string_parse -- Parse a string into individual words
;  IN:	RSI = Address of string
; OUT:	RCX = word count
; Note:	This function will remove "extra" whitespace in the source string
;	"This is  a test. " will update to "This is a test."
os_string_parse:
	push rsi
	push rdi
	push rax

	xor ecx, ecx			; RCX is our word counter
	mov rdi, rsi

	call os_string_chomp		; Remove leading and trailing spaces
	
	cmp byte [rsi], 0x00		; Check the first byte
	je os_string_parse_done		; If it is a null then bail out
	inc rcx				; At this point we know we have at least one word

os_string_parse_next_char:
	lodsb
	stosb
	cmp al, 0x00			; Check if we are at the end
	je os_string_parse_done		; If so then bail out
	cmp al, ' '			; Is it a space?
	je os_string_parse_found_a_space
	jmp os_string_parse_next_char	; If not then grab the next char

os_string_parse_found_a_space:
	lodsb				; We found a space.. grab the next char
	cmp al, ' '			; Is it a space as well?
	jne os_string_parse_no_more_spaces
	jmp os_string_parse_found_a_space

os_string_parse_no_more_spaces:
	dec rsi				; Decrement so the next lodsb will read in the non-space
	inc rcx
	jmp os_string_parse_next_char

os_string_parse_done:
	pop rax
	pop rdi
	pop rsi
ret
; -----------------------------------------------------------------------------


; =============================================================================
; EOF
