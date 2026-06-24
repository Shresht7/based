%include "library/syscalls.asm"
%include "src/core/radix.asm"

section .data
    msg db "usage: based <value>", 10               ; message to print, followed by a newline character
    msg_len equ $ - msg                             ; calculate the length of the message. `$` means current address, so `$ - msg` gives the length of the message in bytes

    parse_err_msg db "error: invalid input", 10     ; error message for invalid input, followed by a newline character
    parse_err_msg_len equ $ - parse_err_msg         ; calculate the length of the error message

    newline db 10                                   ; newline character

section .text
; The main entry-point of the program
global _start
_start:
    ; [rsp]             = argc
    ; [rsp+8]           = argv[0] (program name)
    ; [rsp+16]          = argv[1] (first argument)
    mov rax, [rsp]      ; load argc into rax
    cmp rax, 2          ; need at least 2 arguments (program name + one argument)
    jl .usage           ; if less than 2, jump to usage message

    mov rdi, [rsp+16]       ; load the pointer to the first argument (argv[1]) into rdi
    call parse_decimal      ; parse the first argument (argv[1]) as a decimal number, result in rax
    test rdx, rdx           ; check the status returned by parse_decimal (rdx = 0 means success, rdx = 1 means invalid input)
    jnz .parse_error        ; if rdx is not zero, jump to parse_error

    ; Exit with decimal for testing
    mov rdi, rax            ; move the parsed decimal value into rdi for exit code
    EXIT rdi                ; exit the program with the parsed decimal value as the exit code

.usage:
    PRINT msg                   ; print the usage message
    EXIT EXIT_FAILURE           ; exit the program with failure code

.parse_error:
    PRINT parse_err_msg         ; print the parse error message
    EXIT EXIT_FAILURE           ; exit the program with failure code
