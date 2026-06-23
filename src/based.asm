%include "src/linux/syscall.asm"

section .data
    msg db "usage: based <value>", 10       ; message to print, followed by a newline character
    msg_len equ $ - msg                     ; calculate the length of the message. `$` means current address, so `$ - msg` gives the length of the message in bytes
    newline db 10                           ; newline character

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

    PRINT [rsp+16]      ; print the first argument (argv[1])
    PRINT newline       ; print a newline character

    EXIT SUCCESS        ; exit the program with success code

.usage:
    PRINT msg           ; print the usage message
    EXIT FAILURE        ; exit the program with failure code

