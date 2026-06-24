%ifndef SYSCALLS_ASM
%define SYSCALLS_ASM

; --------
; SYSCALLS
; --------

; Syscalls
SYSCALL_READ    equ 0
SYSCALL_WRITE   equ 1
SYSCALL_EXIT    equ 60

; File Descriptors
STDIN           equ 0
STDOUT          equ 1
STDERR          equ 2

; Exit Status Codes
EXIT_SUCCESS    equ 0
EXIT_FAILURE    equ 1

; WRITE <file-descriptor>, <*buffer>, <count>
;
; Writes data from a buffer to a file descriptor (e.g., stdout, stderr).
;
; @param file-descriptor: The file descriptor to write to (e.g., STDOUT, STDERR)
; @param *buffer: Pointer to the buffer containing the data to write
; @param count: The number of bytes to write from the buffer
; @returns rax: The number of bytes written or a negative value if an error occurred
%macro WRITE 3
    mov rax, SYSCALL_WRITE          ; syscall: write
    mov rdi, %1                     ; file descriptor: (e.g., STDOUT, STDERR)
    mov rsi, %2                     ; buffer: pointer to the string to write
    mov rdx, %3                     ; count: length of the bytes to write
    syscall                         ; execute syscall
%endmacro

; READ <file-descriptor>, <*buffer>, <count>
;
; Reads data from a file descriptor (e.g., stdin) into a buffer.
;
; @param file-descriptor: The file descriptor to read from (e.g., STDIN)
; @param *buffer: Pointer to the buffer where the read data will be stored
; @param count: The maximum number of bytes to read into the buffer
; @returns rax: The number of bytes read or a negative value if an error occurred
%macro READ 3
    mov rax, SYSCALL_READ           ; syscall: read
    mov rdi, %1                     ; file descriptor: (e.g., STDIN)
    mov rsi, %2                     ; buffer: pointer to the buffer to store the read data
    mov rdx, %3                     ; count: number of bytes to read from the file descriptor
    syscall                         ; execute syscall
%endmacro

; PRINT <defined-string>
;
; Prints the defined string to STDOUT
;
; @param *str: The defined string to print to stdout. (must also have ..._len defined alongside it)
; @returns rax: The number of bytes written or a negative value if an error occurred
%macro PRINT 1
    mov rax, SYSCALL_WRITE          ; syscall: write
    mov rdi, STDOUT                 ; file descriptor: stdout
    mov rsi, %1                     ; buffer: pointer to the string to write
    mov rdx, %1_len                 ; count: length of the string
    syscall                         ; execute syscall
%endmacro

; ERROR <defined-string>
;
; Prints the defined string to STDERR
;
; @param *str: The defined string to print to stderr. (must also have ..._len defined alongside it)
; @returns rax: The number of bytes written or a negative value if an error occurred
%macro ERROR 1
    mov rax, SYSCALL_WRITE          ; syscall: write
    mov rdi, STDERR                 ; file descriptor: stderr
    mov rsi, %1                     ; buffer: pointer to the error message
    mov rdx, %1_len                 ; count: length of the error message
    syscall                         ; execute syscall
%endmacro

; EXIT <exit-code>
;
; Exits the program with the specified exit code.
;
; @param exit-code: The exit code to return to the operating system (e.g., EXIT_SUCCESS, EXIT_FAILURE, 0, 1, 255, etc.)
; @returns: This macro does not return; it terminates the program.
%macro EXIT 1
    mov rax, SYSCALL_EXIT           ; syscall: exit
    mov rdi, %1                     ; status: exit code
    syscall                         ; execute
%endmacro



%endif; SYSCALLS_ASM
