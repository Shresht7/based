%include "library/syscalls.asm"
%include "library/strutils.asm"
%include "src/core/radix.asm"
%include "tests/assert.asm"

section .data
    DEFINE_STR test_parse_decimal_str, "12345", 0           ; Define a null-terminated test string for parse_decimal
    DEFINE_STR test_parse_invalid_str, "12G45", 0           ; Define a null-terminated test string for parse_decimal with an invalid character

    DEFINE_STR test_parse_hex_str, "1A3F", 0                ; Define a null-terminated test string for parse_hexadecimal
    DEFINE_STR test_parse_invalid_hex_str, "3G", 0          ; Define a null-terminated test string for parse_hexadecimal with an invalid character

    DEFINE_STR test_parse_octal_str, "755", 0               ; Define a null-terminated test string for parse_octal
    DEFINE_STR test_parse_invalid_octal_str, "78", 0        ; Define a null-terminated test string for parse_octal with an invalid character

    DEFINE_STR test_parse_binary_str, "1101", 0             ; Define a null-terminated test string for parse_binary
    DEFINE_STR test_parse_invalid_binary_str, "1102", 0     ; Define a null-terminated test string for parse_binary with an invalid character

    DEFINE_STR test_parse_overflow_str, "18446744073709551616", 0       ; Define a null-terminated test string for parse_uint that causes overflow (2^64)
    DEFINE_STR test_parse_max_uint64_str, "18446744073709551615", 0     ; Define a null-terminated test string for parse_uint that is the maximum uint64 value (2^64 - 1)

    DEFINE_STR test_detect_base_unspecified, "75", 0        ; Define a string for detect_base with unspecified base
    DEFINE_STR test_detect_base_hexadecimal, "0xAF", 0      ; Define a hexadecimal string for detect_base
    DEFINE_STR test_detect_base_octal, "0o755", 0           ; Define a octal string for detect_base
    DEFINE_STR test_detect_base_binary, "0b11011", 0        ; Define a binary string for detect_base
    DEFINE_STR test_detect_base_unspecified_unprefixed, "75", 0
    DEFINE_STR test_detect_base_hexadecimal_unprefixed, "AF", 0
    DEFINE_STR test_detect_base_octal_unprefixed, "755", 0
    DEFINE_STR test_detect_base_binary_unprefixed, "11011", 0

section .bss
        __test_number_buffer resb 96    ; Reserve 96 bytes for the test number buffer
        __test_str_buffer resb 96       ; Reserve 96 bytes for the test string buffer

section .text
global _start

_start:

    ; parse_uint decimal
    ; ------------------

    TESTCASE "parse_uint should parse valid decimal strings correctly"
        mov rdi, test_parse_decimal_str
        mov rsi, 10
        call parse_uint
        ASSERT_EQ rax, 12345, "should parse '12345' as 12345"

        mov rdi, test_parse_invalid_str
        mov rsi, 10
        call parse_uint
        ASSERT_EQ rdx, 1, "should return error code 1 for invalid character 'G' in '12G45'"
        ASSERT_EQ rax, 0, "should return 0 in rax for invalid character"

    ; parse_uint hexadecimal
    ; ----------------------

    TESTCASE "parse_uint should parse valid hexadecimal strings correctly"
        mov rdi, test_parse_hex_str
        mov rsi, 16
        call parse_uint
        ASSERT_EQ rax, 6719, "should parse '1A3F' as 6719"

        mov rdi, test_parse_invalid_hex_str
        mov rsi, 16
        call parse_uint
        ASSERT_EQ rdx, 1, "should return error code 1 for invalid character 'G' in '3G'"
        ASSERT_EQ rax, 0, "should return 0 in rax for invalid character"

    ; parse_uint octal
    ; ----------------

    TESTCASE "parse_uint should parse valid octal strings correctly"
        mov rdi, test_parse_octal_str
        mov rsi, 8
        call parse_uint
        ASSERT_EQ rax, 493, "should parse '755' as 493"

        mov rdi, test_parse_invalid_octal_str
        mov rsi, 8
        call parse_uint
        ASSERT_EQ rdx, 1, "should return error code 1 for invalid character '8' in '78'"
        ASSERT_EQ rax, 0, "should return 0 in rax for invalid character"

    ; parse_uint binary
    ; -----------------

    TESTCASE "parse_uint should parse valid binary strings correctly"
        mov rdi, test_parse_binary_str
        mov rsi, 2
        call parse_uint
        ASSERT_EQ rax, 13, "should parse '1101' as 13"

        mov rdi, test_parse_invalid_binary_str
        mov rsi, 2
        call parse_uint
        ASSERT_EQ rdx, 1, "should return error code 1 for invalid character '2' in '1102'"
        ASSERT_EQ rax, 0, "should return 0 in rax for invalid character"

    ; parse_uint overflow
    ; -------------------

    TESTCASE "parse_uint should return error code 2 for overflow"
        mov rdi, test_parse_overflow_str
        mov rsi, 10
        call parse_uint
        ASSERT_EQ rdx, 2, "should return error code 2 for overflow when parsing '18446744073709551616'"
        ASSERT_EQ rax, 0, "should return 0 in rax for overflow"

    ; parse_uint max uint64
    ; ---------------------

    ; TESTCASE "parse_uint should parse the maximum uint64 value correctly"
    ;     mov rdi, test_parse_max_uint64_str
    ;     mov rsi, 10
    ;     call parse_uint
    ;     ASSERT_EQ rax, 18446744073709551615, "should parse '18446744073709551615' as 18446744073709551615"
    ;     ASSERT_EQ rdx, 0, "should return error code 0 for valid input"

    ;     mov rdi, test_parse_max_uint64_str
    ;     mov rsi, 16
    ;     call parse_uint
    ;     ASSERT_EQ rax, 18446744073709551615, "should parse 'FFFFFFFFFFFFFFFF' as 18446744073709551615 in base 16"
    ;     ASSERT_EQ rdx, 0, "should return error code 0 for valid input in base 16"

    ; format_uint
    ; -----------

    TESTCASE "format_uint should format uint correctly"
        mov rdi, 12345
        mov rsi, __test_str_buffer
        mov rdx, 10
        call format_uint
        ASSERT_STR_EQ rax, test_parse_decimal_str, "should format 12345 as '12345' in base 10"

        mov rdi, 6719
        mov rsi, __test_str_buffer
        mov rdx, 16
        call format_uint
        ASSERT_STR_EQ rax, test_parse_hex_str, "should format 6719 as '1A3F' in base 16"

        mov rdi, 493
        mov rsi, __test_str_buffer
        mov rdx, 8
        call format_uint
        ASSERT_STR_EQ rax, test_parse_octal_str, "should format 493 as '755' in base 8"

        mov rdi, 13
        mov rsi, __test_str_buffer
        mov rdx, 2
        call format_uint
        ASSERT_STR_EQ rax, test_parse_binary_str, "should format 13 as '1101' in base 2"

    ; detect_base
    ; -----------

    TESTCASE "detect_base should be able to detect the base!"
        mov r8, rsi
        mov rdi, test_detect_base_unspecified
        call detect_base
        ASSERT_EQ rsi, r8, "should not change the base as there is no prefix"
        ASSERT_STR_EQ rdi, test_detect_base_unspecified_unprefixed, "should not advance the string pointer as there is no prefix"

        mov rdi, test_detect_base_hexadecimal
        call detect_base
        ASSERT_EQ rsi, 16, "should detect hexadecimal string prefixed with '0x'"
        ASSERT_STR_EQ rdi, test_detect_base_hexadecimal_unprefixed, "should advance the pointer foward to skip the '0x'"

        mov rdi, test_detect_base_octal
        call detect_base
        ASSERT_EQ rsi, 8, "should detect octal string prefixed with '0o'"
        ASSERT_STR_EQ rdi, test_detect_base_octal_unprefixed, "should advance the pointer foward to skip the '0o'"

        mov rdi, test_detect_base_binary
        call detect_base
        ASSERT_EQ rsi, 2, "should detect binary string prefixed with '0b'"
        ASSERT_STR_EQ rdi, test_detect_base_binary_unprefixed, "should advance the pointer foward to skip the '0b'"

    ; All tests passed, exit with status 0
    EXIT EXIT_SUCCESS
