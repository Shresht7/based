section .data
    msg db "based hello world!", 10     ; message to print, followed by a newline character
    msg_len equ $ - msg                 ; calculate the length of the message. `$` means current address, so `$ - msg` gives the length of the message in bytes

section .text
; The main entry-point of the program
global _start
_start:
    mov rax, 1          ; syscall: write
    mov rdi, 1          ; file descriptor: stdout
    mov rsi, msg        ; pointer to the message buffer to write
    mov rdx, msg_len    ; length of the message
    syscall

    mov rax, 60        ; syscall: exit
    mov rdi, 0         ; exit code 0
    syscall
