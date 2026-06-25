%include "library/syscalls.asm"
%include "library/strutils.asm"
%include "library/stdio.asm"
%include "src/core/radix.asm"

section .data
    msg db "usage: based <value>", 10               ; message to print, followed by a newline character
    msg_len equ $ - msg                             ; calculate the length of the message. `$` means current address, so `$ - msg` gives the length of the message in bytes

    parse_err_msg db "error: invalid input", 10     ; error message for invalid input, followed by a newline character
    parse_err_msg_len equ $ - parse_err_msg         ; calculate the length of the error message

    flag_from   db "--from", 0
    flag_to     db "--to", 0
    flag_help   db "--help", 0

    arg_from_base   dq 10
    arg_to_base     dq 2

    newline db 10                                   ; newline character

section .bss
    arg_value       resq 1

section .text
; The main entry-point of the program
global _start
_start:
    mov r12, [rsp]                                  ; r12 = argc (number of command-line arguments)
    lea r13, [rsp + 8]                              ; r13 = argv (pointer to the array of command-line arguments)

    ; Check if the user provided any arguments at all
    cmp r12, 1                                      ; Compare argc with 1 (the program name itself)
    jle print_usage                                 ; If argc <= 1, jump to print_usage

    ; Skip argv[0] (the program name) and start processing the remaining arguments
    dec r12                                         ; Decrement argc to account for the program name
    add r13, 8                                      ; Move the pointer to the next argument (argv[1])

    .command_line_parse_loop:
        cmp r12, 0                                  ; Check if there are any more arguments to process
        je .command_line_parse_done                 ; If no more arguments, exit the loop

        mov r14, [r13]                              ; Load the current argument into r14

        ; Check for the "--help" flag
        mov rdi, r14
        lea rsi, [flag_help]
        call strcmp
        cmp rax, 0
        je print_usage                              ; If the argument is "--help", jump to print_usage

        ; Check for the "--from" flag
        mov rdi, r14
        lea rsi, [flag_from]
        call strcmp
        cmp rax, 0
        je .handle_from_flag                        ; If the argument is "--from", handle it

        ; Check for the "--to" flag
        mov rdi, r14
        lea rsi, [flag_to]
        call strcmp
        cmp rax, 0
        je .handle_to_flag                          ; If the argument is "--to", handle it

        ; If the argument is not a recognized flag, treat it as the value to convert
        mov [arg_value], r14                        ; Store the value in arg_value
        jmp .command_line_parse_next_arg

        .handle_from_flag:
            ; Move to the next argument to get the --from base value
            dec r12                                 ; decrement from remaining argument count
            add r13, 8                              ; move to the next argument
            cmp r12, 0                              ; Check if there is a next argument
            je .missing_value_error

            mov rdi, [r13]                          ; Load the next argument (the base value) into rdi
            mov rsi, 10                             ; Set the base for conversion to 10 (decimal)
            call parse_uint
            mov [arg_from_base], rax                ; Store the parsed base value in arg_from_base
            jmp .command_line_parse_next_arg

        .handle_to_flag:
            ; Move to the next argument to get the --to base value
            dec r12                                 ; decrement from remaining argument count
            add r13, 8                              ; move to the next argument
            cmp r12, 0                              ; Check if there is a next argument
            je .missing_value_error

            mov rdi, [r13]                          ; Load the next argument (the base value) into rdi
            mov rsi, 10                             ; Set the base for conversion to 10 (decimal)
            call parse_uint
            mov [arg_to_base], rax                  ; Store the parsed base value in arg_to_base
            jmp .command_line_parse_next_arg

        .missing_value_error:
            PRINT parse_err_msg
            EXIT EXIT_FAILURE

        .command_line_parse_next_arg:
            dec r12                                 ; Decrement the argument count
            add r13, 8                              ; Move to the next argument
            jmp .command_line_parse_loop            ; Repeat the loop

        .command_line_parse_done:
            ; After parsing all command-line arguments, check if the value to convert was provided
            mov rdi, [rel arg_value]
            cmp rdi, 0
            je print_usage                          ; If no value was provided, print usage and exit

            ; If the value is provided, proceed to execute the logic
            jmp .execute_logic

        .execute_logic:
            ; Load the value to convert and the bases
            mov rdi, [rel arg_value]                ; Load the value to convert into rdi
            mov rsi, [arg_from_base]                ; Load the source base into rsi
            call parse_uint                         ; Parse the value from the source base
            cmp rdx, 0                              ; Check if parsing was successful
            jne .parse_error                        ; If there was an error, jump to parse_error

            mov rdi, rax                            ; Move the parsed value into rdi for formatting
            mov rsi, [arg_to_base]                  ; Load the target base into rsi
            call format_uint                        ; Format the value into the target base

            mov rdi, rax                            ; Move the pointer to the formatted string into rdi
            call print_str                          ; Print the formatted string
            WRITE STDOUT, newline, 1                ; Print a newline character

            EXIT EXIT_SUCCESS

        .parse_error:
            PRINT parse_err_msg                     ; Print the error message for invalid input
            EXIT EXIT_FAILURE                       ; Exit with failure status

print_usage:
    PRINT msg
    EXIT EXIT_SUCCESS
