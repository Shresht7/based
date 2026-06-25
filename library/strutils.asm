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

    ; strcmp(rdi: *str1, rsi: *str2) -> rax: result
    ; Compares two null-terminated strings.
    ;
    ; @param rdi: pointer to the first null-terminated string
    ; @param rsi: pointer to the second null-terminated string
    ; @return rax: 0 if the strings are equal, a negative value if str1 < str2, and a positive value if str1 > str2
    strcmp:
        xor rax, rax                    ; Clear rax to use it as a result accumulator
        .strcmp_loop:
            mov al, byte [rdi]              ; Load the current byte of str1 into al
            mov bl, byte [rsi]              ; Load the current byte of str2 into bl
            cmp al, bl                      ; Compare the two bytes
            jl .strcmp_less                 ; If str1 < str2, jump to the `.strcmp_less` label
            jg .strcmp_greater              ; If str1 > str2, jump to the `.strcmp_greater` label
            test al, al                     ; Check if we reached the null terminator of str1 (and str2, since they are equal so far)
            je .strcmp_equal                 ; If we reached the null terminator, the strings are equal, jump to the `.strcmp_equal` label
            inc rdi                         ; Move to the next byte in str1
            inc rsi                         ; Move to the next byte in str2
            jmp .strcmp_loop                ; Jump back to the start of the loop for the next comparison
        .strcmp_less:
            mov rax, -1                     ; Set rax to -1 to indicate str1 < str2
            ret                             
        .strcmp_greater:
            mov rax, 1                      ; Set rax to 1 to indicate str1 > str2
            ret                             
        .strcmp_equal:
            xor rax, rax                    ; Set rax to 0 to indicate str1 == str2
            ret  

    ; itoa(rdi: int, rsi: *buffer) -> rax: pointer to the null-terminated string
    ; Converts an integer to a null-terminated string.
    ;
    ; @param rdi: integer to convert
    ; @param rsi: pointer to the buffer where the string will be stored
    ; @return none (the result is stored in the buffer pointed to by rsi)
    itoa:
        mov rax, rdi                    ; Move the integer into rax for processing
        mov rcx, 10                     ; Set the divisor to 10 for decimal conversion
        mov r8, 0                       ; Initialize a counter for the number of digits

        .divide_loop:
            xor rdx, rdx                ; Clear rdx before division (to hold the remainder)
            div rcx                     ; Divide rax by 10, quotient in rax, remainder in rdx

            add dl, '0'                 ; Convert the remainder (0-9) to ASCII ('0'-'9')
                                        ; (dl is the lowest 8 bits of the rdx register)

            push rdx                    ; Push the ASCII character onto the stack (we'll have to reverse the order later 
                                        ;as we build the string from least significant digit to most significant digit)
            inc r8                      ; Increment the digit counter
 
            cmp rax, 0                  ; Check if the quotient is zero (we've processed all digits)
            jne .divide_loop            ; If not zero, continue the loop to process the next digit

        ; Now we have all digits on the stack in reverse order, and r8 contains the number of digits
        ; We will now pop the digits from the stack and store them in the buffer pointed to by rsi

        .store_loop:
            pop rdx                     ; Pop the next digit from the stack into rdx
            mov [rsi], dl               ; Store the ASCII character in the buffer
            inc rsi                     ; Move to the next position in the buffer
            dec r8                      ; Decrement the digit counter
            cmp r8, 0                   ; Check if we have processed all digits
            jne .store_loop             ; If not, continue storing the next digit

        ; Null-terminate the string
        mov byte [rsi], 0               ; Store the null terminator at the end
        ret                             ; Return from the function, with the string stored in the buffer pointed to by rsi


%endif ; STRUTILS_ASM
