%ifndef SYSCALL_ASM
%define SYSCALL_ASM

%include "src/helpers/strutils.asm"

; Syscalls
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_EXIT    equ 60

; File Descriptors
STDIN       equ 0
STDOUT      equ 1
STDERR      equ 2

; Exit Codes
EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

section .text

    ; sys_write(fd, buf, count) -> rax
    ; This function performs the write syscall to write data to a file descriptor.
    ; Arguments:
    ;   rdi: file descriptor (e.g., STDOUT)
    ;   rsi: pointer to the buffer containing data to write
    ;   rdx: number of bytes to write
    ; Returns:
    ;   rax: number of bytes written on success, or a negative error code on failure
    sys_write:
        mov rax, SYS_WRITE      ; syscall number for write
        syscall                 ; invoke the syscall
        ret

    ; sys_exit(status) -> ! (does not return)
    ; This function performs the exit syscall to terminate the program with a given status code.
    ; Arguments:
    ;   rdi: exit status code (e.g., EXIT_SUCCESS or EXIT_FAILURE)
    sys_exit:
        mov rax, SYS_EXIT       ; syscall number for exit
        syscall                 ; invoke the syscall

    ; print_string(ptr)
    ; This function prints a null-terminated string to STDOUT.
    ; Arguments:
    ;   rdi: pointer to the null-terminated string
    ; Clobbers: rax, rcx, rdx, rsi, rdi
    print_string:
        push rdi                ; save the pointer to the string
        call strlen             ; calculate the length of the string, result in rax
        mov rdx, rax            ; move the length into rdx for sys_write
        pop rsi                 ; restore the pointer to the string into rsi
        mov rdi, STDOUT         ; set file descriptor to STDOUT
        call sys_write          ; call sys_write to print the string
        ret

%macro PRINT 1
    mov rdi, %1             ; move the pointer to the string into rdi
    call print_string       ; call print_string to print the string
%endmacro

%macro EXIT 1
    mov rdi, EXIT_%1        ; move the exit status code into rdi
    call sys_exit           ; call sys_exit to terminate the program
%endmacro

%endif ; SYSCALL_ASM
