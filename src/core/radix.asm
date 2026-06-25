%ifndef RADIX_ASM
%define RADIX_ASM

section .text
    
    ; detect_base
    ; 
    ; Peeks at the string representation at rdi and updates the base (rsi) if necessary
    ; 
    ; @param rdi: pointer to the string representation of the unsigned integer
    ; @returns rdi: pointer to the string representation advanced by 2 characters
    ; @returns rsi: Updates the rsi to the correct base
    detect_base:
        mov cx, word [rdi]          ; Peek at the first two characters

        cmp cx, '0x'                ; If the prefix is '0x'
        je .is_hexadecimal          ; the string is in hexadecimal representation
        cmp cx, '0o'                ; If the prefix is '0o'
        je .is_octal                ; the string is in octal representation
        cmp cx, '0b'                ; If the prefix is '0b'
        je .is_binary               ; the string is in binary representation
        jmp .no_match               ; If none of the above match, 

        .is_hexadecimal:
            mov rsi, 16             ; Override base to be 16
            add rdi, 2              ; Advance the pointer forward skipping the '0x' prefix
            ret

        .is_octal:
            mov rsi, 8              ; Override base to 8
            add rdi, 2              ; Advance the pointer forward skipping the '0o' prefix
            ret

        .is_binary:
            mov rsi, 2              ; Override base to 2
            add rdi, 2              ; Advance the pointer forward skipping the '0b' prefix
            ret

        .no_match:
            ; mov rsi, 10             ; Override the base to 10
            ; No need to advance the pointer since there's no prefix

            ; If none of the above match, there is no prefix.
            ; In this case, the number may or may not be in decimal representation. We will leave the base as is (rsi) and let the caller handle it.
            ; A value of 111 can be in base 2 and base 7 as well as base 10. If the caller explicitly asked for base 2 but did not provide a prefix
            ; then we respect that choice and leave it be.
            ret

    ; parse_uint
    ;
    ; Parses a string representation of an unsigned integer in a given base (2-16) and returns the value as a uint64
    ;
    ; @param rdi: pointer to the string representation of the unsigned integer
    ; @param rsi: base (2-16)
    ; @returns rax: the parsed unsigned integer value
    ; @returns rdx: 0 on success, 1 on invalid character, 2 on overflow
    parse_uint:
        ; If the value has a prefix (like 0x for hex, or 0b for binary), we need to detect the base and adjust the string pointer accordingly
        ; detect_base will update rsi to the correct base and advance rdi if necessary
        call detect_base

        xor rax, rax                ; Clear rax (the result aggregator)
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
    ; @param rsi: pointer to the buffer where the formatted string will be stored
    ; @param rdx: base (2-16)
    ; @returns rax: pointer to the formatted string (null-terminated)
    format_uint:
        mov rax, rdi                    ; Move the number to be formatted into rax
        mov r9, rdx                     ; Move the base into r9
        lea r10, [rsi + 64]             ; Point r10 to the end of the buffer
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
