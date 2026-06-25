#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"

// FOREIGN FUNCTION INTERFACE
// --------------------------

// The following functions are implemented in assembly and are linked with this C code.

// Maps to: parse_uint(rdi: *str, rsi: uint64_t base) -> rax: uint64_t parsed_value
extern uint64_t parse_uint(const char *str, uint64_t base);

// Maps to: format_uint(rdi: uint64_t value, rsi: *buffer, rdx: uint64_t base) -> rax: *char buffer
extern char *format_uint(uint64_t value, char *buffer, uint64_t base);

// HELP
// ----

void print_help()
{
    printf("Usage: based <number> <base>\n");
}

// MAIN
// ----

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        print_help();
        return 1;
    }

    char *number_str = argv[1];
    uint64_t base = atoi(argv[2]);
    printf("Input number: %s\n", number_str);
    printf("Input base: %llu\n", base);

    uint64_t parsed_number = parse_uint(number_str, 10);

    // Create a 65-byte buffer to hold the binary representation of a 64-bit number (64 bits + null terminator) on the C stack
    char output_buffer[65];

    char *base_str = format_uint(parsed_number, output_buffer, base);

    printf("Parsed number: %llu\n", parsed_number);
    printf("Formatted number: %s\n", base_str);

    return 0;
}
