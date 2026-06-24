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
