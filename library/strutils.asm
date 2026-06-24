%ifndef STRUTILS_ASM
%define STRUTILS_ASM

section .text

    ; strlen(rdi: *str) -> rax: length
    ; Returns the length of a null-terminated string.
    ;
    ; @param rdi: pointer to the null-terminated string
    ; @return rax: length of the string (not including the null terminator)
    strlen:
        mov rax, 0                      ; Initialize length counter to 0
        .strlen_loop:
            cmp byte [rdi + rax], 0         ; Compare the current byte (at memory address rdi (start) + rax (counter)) with the null terminator
            je .strlen_done                 ; Jump if equal (found null terminator) to the `.strlen_done` label
            inc rax                         ; Otherwise, increment the length counter
            jmp .strlen_loop                ; Jump back to the start of the loop for the next byte/character
        .strlen_done:
            ret                             ; Return from the function, with rax containing the length of the string


%endif ; STRUTILS_ASM
