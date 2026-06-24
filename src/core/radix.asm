%ifndef RADIX_ASM
%define RADIX_ASM

section .text

    ; parse_decimal(rdi) -> rax
    ; This function parses a decimal number from a null-terminated string pointed to by rdi. The parsed integer is returned in rax.
    ; Arguments:
    ;   rdi: pointer to the null-terminated string containing the decimal number
    ;   rdx: status: 0 = ok, 1 = invalid input (bad char, or empty string)
    ; Returns:
    ;   rax: the parsed integer value
    parse_decimal:
        xor rax, rax                    ; clear rax to accumulate the result
        xor r8, r8                      ; clear r8 to count the number of valid digits processed

    .parse_decimal_loop:
        movzx rcx, byte [rdi]           ; load the current character into rcx
        cmp rcx, 0                      ; check for null terminator
        je .parse_decimal_done          ; if null terminator, we're done

        cmp rcx, '0'                    ; check if the character is less than '0'
        jl .parse_decimal_invalid       ; if less than '0', it's invalid
        cmp rcx, '9'                    ; check if the character is greater than '9'
        jg .parse_decimal_invalid       ; if greater than '9', it's invalid

        ; ASCII digits are contiguous ('0'=0x30 through '9'=0x39), so subtracting the ASCII code of '0'
        ; converts the character directly to its numeric value (e.g. '7' - '0' = 7)
        sub rcx, '0'                    ; convert ASCII character to integer (0-9).
        imul rax, rax, 10               ; multiply the current result by 10 to shift left
        add rax, rcx                    ; add the new digit to the result
        inc r8                          ; increment the count of valid digits processed
        inc rdi                         ; move to the next character in the string
        jmp .parse_decimal_loop         ; repeat the loop for the next character

    .check_empty:
        cmp r8, 0                       ; check if any valid digits were processed
        je .parse_decimal_invalid       ; if no valid digits, it's invalid

    .parse_decimal_invalid:
        xor rax, rax                    ; clear rax to indicate failure (or could set to a specific error code)
        mov rdx, 1                      ; set status to 1
        ret

    .parse_decimal_done:
        ; rax now contains the parsed integer value
        xor rdx, rdx                    ; set status to 0 (ok)
        ret

%endif; RADIX_ASM
