%ifndef RADIX_ASM
%define RADIX_ASM

section .bss
    ; We need the space for a base-2 representation of the max uint64: i.e. 64 bits
    ; +1 for null terminator
    radix_buffer resb 65

section .text

    ; parse_uint
    ;
    ; Parses a string representation of an unsigned integer in a given base (2-16) and returns the value as a uint64
    ;
    ; @param rdi: pointer to the string representation of the unsigned integer
    ; @param rsi: base (2-16)
    ; @returns rax: the parsed unsigned integer value
    ; @returns rdx: 0 on success, 1 on invalid character, 2 on overflow
    parse_uint:
        xor rax, rax                ; Clear rax (the result)
        xor rdx, rdx                ; Clear rdx (error flag)
        xor r8, r8                  ; Clear r8 (the digit counter)
        
        .loop:
            movzx rcx, byte [rdi]   ; Load the next character from the string
            test rcx, rcx           ; Check for null terminator
            jz .done                ; If null terminator, we're done

            ; Convert character to digit based on base
            cmp rcx, '0'
            jl .invalid_char
            cmp rcx, '9'
            jle .digit_0_9
            cmp rcx, 'A'
            jl .invalid_char
            cmp rcx, 'F'
            jle .digit_A_F
            cmp rcx, 'a'
            jl .invalid_char
            cmp rcx, 'f'
            jle .digit_a_f
            jmp .invalid_char

        .digit_0_9:
            sub rcx, '0'            ; Convert ASCII '0'-'9' to 0-9
            jmp .check_digit

        .digit_A_F:
            sub rcx, 'A'            ; Convert ASCII 'A'-'F' to 10-15
            add rcx, 10
            jmp .check_digit

        .digit_a_f:
            sub rcx, 'a'            ; Convert ASCII 'a'-'f' to 10-15
            add rcx, 10
            jmp .check_digit
        
        .check_digit:
            cmp rcx, rsi            ; Check if digit is valid for the base
            jge .invalid_char       ; If digit >= base, it's invalid

            ; Check for overflow before multiplying
            mov r9, rax             ; Store current result in r9
            mov r10, rsi            ; Store base in r10
            mul r10                 ; Multiply current result by base (rax = rax * base)
            cmp rax, r9             ; Check if overflow occurred (rax < previous result)
            jl .overflow             ; If overflow, jump to error handling

            add rax, rcx            ; Add the digit to the result
            inc r8                  ; Increment digit counter
            inc rdi                 ; Move to the next character
            jmp .loop               ; Repeat the loop

    .invalid_char:
        mov rdx, 1              ; Set error flag to 1 (invalid character)
        jmp .done               ; Exit the loop

    .overflow:
        mov rdx, 2              ; Set error flag to 2 (overflow)
        jmp .done               ; Exit the loop

    .done:
        ret                     ; Return with rax = result, rdx = error flag


%endif; RADIX_ASM
