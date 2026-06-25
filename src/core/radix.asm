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
        xor rax, rax            ; Clear rax (the result)
        mov rdx, 1              ; Set error flag to 1 (invalid character)
        jmp .done               ; Exit the loop

    .overflow:
        xor rax, rax            ; Clear rax (the result)
        mov rdx, 2              ; Set error flag to 2 (overflow)
        jmp .done               ; Exit the loop

    .done:
        ret                     ; Return with rax = result, rdx = error flag

    
    ; format_uint
    ;
    ; Formats a uint64 value into a string representation in a given base (2-16)
    ;
    ; @param rdi: the uint64 value to format
    ; @param rsi: base (2-16)
    ; @returns rax: pointer to the formatted string (null-terminated)
    format_uint:
        mov rax, rdi                    ; Move the number to be formatted into rax
        mov r9, rsi                     ; Move the base into r9
        lea r10, [radix_buffer + 64]    ; Point r10 to the end of the buffer
        mov byte [r10], 0               ; Null-terminate the string

        test rax, rax
        jnz .format_loop                ; If rax is not zero, continue formatting
        dec r10                         ; If rax is zero, just return "0"
        mov byte [r10], '0'
        jmp .done_formatting

        .format_loop:
            test rax, rax
            jz .done_formatting          ; If rax is zero, we're done formatting
            xor rdx, rdx                 ; Clear rdx for division
            div r9                        ; Divide rax by base (r9), quotient in rax, remainder in rdx

            cmp rdx, 10
            jl .digit_0_9                ; If remainder < 10, it's a digit
            add rdx, 'A' - 10            ; Convert to ASCII 'A'-'F'
            jmp .store_digit

        .digit_0_9:
            add rdx, '0'                 ; Convert to ASCII '0'-'9'

        .store_digit:
            dec r10                       ; Move buffer pointer back
            mov [r10], dl                 ; Store the character in the buffer
            jmp .format_loop              ; Repeat the loop

        .done_formatting:
            mov rax, r10                    ; Return pointer to the start of the formatted string
            ret


%endif; RADIX_ASM
