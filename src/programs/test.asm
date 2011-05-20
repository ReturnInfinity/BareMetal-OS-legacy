[bits 64]
[org 0x0000000000200000]
%include "bmdev.asm"

start:
        mov rsi, corecnt
        call b_print_string
        call b_smp_numcores
        mov rdi, buffer
        call b_int_to_string
        mov rsi, buffer
        call b_print_string
        call b_print_newline
        call task
        mov rbx, 14

cycle:
        push rbx
        mov rax, task
        call b_smp_enqueue
        pop rbx
        dec rbx
        or rbx, rbx
        jnz cycle

        call b_smp_wait
        call b_print_newline
        mov rsi, finmsg
        call b_print_string
        ret

task:
        call b_print_newline
        mov rsi, corenum
        call b_print_string

        call b_smp_get_id
        mov rdi, buffer
        call b_int_to_string
        mov rsi, buffer
        call b_print_string

        mov rsi, separator
        call b_print_string

        inc qword [number]
        mov rax, [number]
        mov rdi, buffer
        call b_int_to_string
        mov rsi, buffer
        call b_print_string

        mov rcx, 24
        call b_delay

        ret

corecnt db "Total Available Cores:",0
corenum db "Core:",0
finmsg  db "Finished.", 0
separator       db "     ",0
number          db 0,0,0,0,0,0,0,0
buffer  resb 64 