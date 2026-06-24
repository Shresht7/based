%include "library/syscalls.asm"
%include "library/strutils.asm"
%include "src/core/radix.asm"
%include "tests/assert.asm"

section .data
    DEFINE_STR test_parse_decimal_str, "12345", 0    ; Define a null-terminated test string for parse_decimal

section .bss
        __test_number_buffer resb 96    ; Reserve 96 bytes for the test number buffer
        __test_str_buffer resb 96       ; Reserve 96 bytes for the test string buffer

section .text
global _start

_start:

    ; parse_decimal
    ; -------------

    TESTCASE "parse_decimal should parse valid decimal strings correctly"
        mov rdi, test_parse_decimal_str
        call parse_decimal
        ASSERT_EQ rax, 12345, "should parse '12345' as 12345"

    ; All tests passed, exit with status 0
    EXIT EXIT_SUCCESS
