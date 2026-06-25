%include "library/syscalls.asm"
%include "library/strutils.asm"
%include "library/stdio.asm"
%include "src/core/radix.asm"

section .data

    DEFINE_STR NAME,    "based"     , 0
    DEFINE_STR VERSION, "v0.1.0"    , 0

    ; Help / Usage Message
    ; --------------------

    HELP db "Usage: based [options] <value>"                                                                 , 0xA
            db ""                                                                                           , 0xA
            db "Options:"                                                                                   , 0xA
            db "  -f, --from, --from-base <base>   Source base (default: 10)"                               , 0xA
            db "  -t, --to, --to-base <base>       Target base (default: 2)"                                , 0xA
            db "  -h, --help                       Show this help message"                                  , 0xA
            db "  -v, --version                    Show version information"                                , 0xA
            db ""                                                                                           , 0xA
            db "Notes:"                                                                                     , 0xA
            db "  Prefixes 0x (hex), 0b (bin), and 0o (oct) are automatically detected from the value"      , 0xA
        HELP_len equ $ - HELP


    ; Flags / Options
    ; ---------------

    flag_from               db "--from", 0
    flag_from_base          db "--from-base", 0

    flag_to                 db "--to", 0
    flag_to_base            db "--to-base", 0

    flag_help               db "--help", 0
    flag_help_short         db "-h", 0

    flag_version            db "--version", 0
    flag_version_short      db "-v", 0

    ; Error Messages
    ; --------------

    DEFINE_STR err_missing_value, "error: missing base value after flag", 0xA
    DEFINE_STR err_invalid_char,  "error: invalid character for the specified base", 0xA
    DEFINE_STR err_overflow,      "error: uint64 overflow. number too large!", 0xA
    DEFINE_STR err_generic,       "error: something bad happened!", 0xA

    arg_from_base   dq 10
    arg_to_base     dq 2

    newline db 10                                   ; newline character

section .bss
    arg_value       resq 1

    ; We need the space for a base-2 representation of the max uint64: i.e. 64 bits. +1 for null terminator
    radix_buffer resb 65

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
        lea rsi, [rel flag_help]
        call strcmp
        cmp rax, 0
        je print_usage                              ; If the argument is "--help", jump to print_usage

        ; Check for the "-h" flag
        mov rdi, r14
        lea rsi, [rel flag_help_short]
        call strcmp
        cmp rax, 0
        je print_usage                              ; If the argument is "-h", jump to print_usage

        ; Check for the "--version" flag
        mov rdi, r14
        lea rsi, [rel flag_version]
        call strcmp
        cmp rax, 0
        je print_version                           ; If the argument is "--version", jump to print_version

        ; Check for the "-v" flag
        mov rdi, r14
        lea rsi, [rel flag_version_short]
        call strcmp
        cmp rax, 0
        je print_version                           ; If the argument is "-v", jump to print_version

        ; Check for the "--from" flag
        mov rdi, r14
        lea rsi, [rel flag_from]
        call strcmp
        cmp rax, 0
        je .handle_from_flag                        ; If the argument is "--from", handle it

        ; Check for the "--from-base" flag
        mov rdi, r14
        lea rsi, [rel flag_from_base]
        call strcmp
        cmp rax, 0
        je .handle_from_flag                        ; If the argument is "--from-base", handle it

        ; Check for the "--to" flag
        mov rdi, r14
        lea rsi, [rel flag_to]
        call strcmp
        cmp rax, 0
        je .handle_to_flag                          ; If the argument is "--to", handle it

        ; Check for the "--to-base" flag
        mov rdi, r14
        lea rsi, [rel flag_to_base]
        call strcmp
        cmp rax, 0
        je .handle_to_flag                          ; If the argument is "--to-base", handle it

        ; If the argument is not a recognized flag, treat it as the value to convert
        mov [rel arg_value], r14                    ; Store the value in arg_value
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
            mov [rel arg_from_base], rax            ; Store the parsed base value in arg_from_base
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
            mov [rel arg_to_base], rax              ; Store the parsed base value in arg_to_base
            jmp .command_line_parse_next_arg

        .command_line_parse_next_arg:
            dec r12                                 ; Decrement the argument count
            add r13, 8                              ; Move to the next argument
            jmp .command_line_parse_loop            ; Repeat the loop

        .missing_value_error:
            PRINT err_missing_value
            EXIT EXIT_FAILURE

        .parse_error:
            cmp rdx, 1                              ; Check if the error was due to an invalid character
            je .invalid_char_error
            cmp rdx, 2                              ; Check if the error was due to overflow
            je .overflow_error

            ; Fallback to a generic error message if the error code is unexpected
            PRINT err_generic
            EXIT EXIT_FAILURE                       

            .invalid_char_error:
                PRINT err_invalid_char
                EXIT EXIT_FAILURE

            .overflow_error:
                PRINT err_overflow
                EXIT EXIT_FAILURE


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
            mov rsi, [rel arg_from_base]            ; Load the source base into rsi
            call parse_uint                         ; Parse the value from the source base
            cmp rdx, 0                              ; Check if parsing was successful
            jne .parse_error                        ; If there was an error, jump to parse_error

            mov rdi, rax                            ; Move the parsed value into rdi for formatting
            lea rsi, [rel radix_buffer]             ; Load the address of the buffer to store the formatted string
            mov rdx, [rel arg_to_base]              ; Load the target base into rdx
            call format_uint                        ; Format the value into the target base

            mov rdi, rax                            ; Move the pointer to the formatted string into rdi
            call print_str                          ; Print the formatted string
            WRITE STDOUT, newline, 1                ; Print a newline character

            EXIT EXIT_SUCCESS

print_usage:
    PRINT HELP
    EXIT EXIT_SUCCESS

print_version:
    PRINT VERSION
    WRITE STDOUT, newline, 1
    EXIT EXIT_SUCCESS
