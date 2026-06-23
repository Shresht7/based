%ifndef STRUTILS_ASM
%define STRUTILS_ASM

section .text

    ; strlen(rdi: pointer to null-terminated string) -> rax: length of the string
    ; This function calculates the length of a null-terminated string pointed to by rdi. The length is returned in rax.
    ; Clobbers rcx
    strlen:
        xor rcx, rcx                ; clear rcx to use it as a counter
    .strlen_loop:
        cmp byte [rdi + rcx], 0     ; check if the current character is null terminator
        je .strlen_done             ; if yes, we have the length
        inc rcx                     ; otherwise, increment the counter
        jmp .strlen_loop            ; repeat the loop
    .strlen_done:
        mov rax, rcx                ; move the length of the string into rax
        ret

%endif ; STRUTILS_ASM
