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

    mov rsi, [rsp+16]  ; load argv[1] (first argument) into rsi

    mov rdi, rsi
    xor rcx, rcx          ; clear rcx to use it as a counter
.strlen:
    cmp byte [rdi + rcx], 0  ; check if the current character is null terminator
    je .have_len            ; if yes, we have the length
    inc rcx                 ; otherwise, increment the counter
    jmp .strlen             ; repeat the loop
.have_len:
    mov rdx, rcx            ; move the length of the string into rdx

    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, rsi            ; pointer to the string (argv[1])
    ; rdx already contains the length of the string
    syscall                 ; invoke the syscall

    ; trailing new-line
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, newline         ; pointer to the newline character
    mov rdx, 1              ; length of the newline character
    syscall

    mov rax, 60        ; syscall: exit
    mov rdi, 0         ; exit code 0
    syscall

.usage:
    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, msg            ; pointer to the usage message
    mov rdx, msg_len        ; length of the usage message
    syscall                 ; invoke the syscall

    mov rax, 60        ; syscall: exit
    mov rdi, 1         ; exit code 1 (indicating an error)
    syscall

