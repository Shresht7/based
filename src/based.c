// Library
#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"
#include "string.h"
#include "getopt.h"

// Didn't want to deal with Windows shenanigans
// So this C program wraps the core radix conversion functions implemented in assembly
// Platform specific stuff and command line parsing are C and GCC's problem now

// FOREIGN FUNCTION INTERFACE
// --------------------------

// The following functions are implemented in assembly and are linked with this C code.
// Following the System V AMD64 ABI calling convention, the first six integer or pointer arguments are passed in registers RDI, RSI, RDX, RCX, R8, and R9.
// The return value is placed in RAX.

// Maps to: parse_uint(rdi: *str, rsi: uint64_t base) -> rax: uint64_t parsed_value
extern uint64_t parse_uint(const char *str, uint64_t base);

// Maps to: format_uint(rdi: uint64_t value, rsi: *buffer, rdx: uint64_t base) -> rax: *char buffer
extern char *format_uint(uint64_t value, char *buffer, uint64_t base);

// HELP
// ----

const char *HELP_MESSAGE = "Usage: based [options] <value>\n"
                           "\n"
                           "Options:\n"
                           "  -f, --from, --from-base <base>   Source base (default: 10)\n"
                           "  -t, --to, --to-base <base>       Target base (default: 2)\n"
                           "  -h, --help                       Show this help message\n"
                           "  -v, --version                    Show version information\n"
                           "\n"
                           "Notes:\n"
                           "  Prefixes 0x (hex), 0b (bin), and 0o (oct) are automatically detected from the value\n";

void print_help()
{
    printf("%s", HELP_MESSAGE);
}

const char *VERSION = "v0.3.0";

void print_version()
{
    printf("%s\n", VERSION);
}

// BASED
// -----

/// @brief Converts a number from one base to another and prints the result to stdout.
/// @param input The input number as a string.
/// @param from_base The base of the input number.
/// @param to_base The base to convert the number to.
void convert(const char *input, uint64_t from_base, uint64_t to_base)
{
    // Parse the input number from the specified base
    uint64_t parsed_number = parse_uint(input, from_base);

    // TODO: Handle parsing errors (e.g., invalid characters for the base, overflow, etc.)

    // Create a 65-byte buffer to hold the binary representation of a 64-bit number (64 bits + null terminator) on the C stack
    char output_buffer[65];

    // Format the parsed number into the target base and store it in the output buffer
    char *formatted_number = format_uint(parsed_number, output_buffer, to_base);

    // Print the formatted number to stdout
    printf("%s\n", formatted_number);
}

// MAIN
// ----

// The main entrypoint of the application
int main(int argc, char *argv[])
{
    // Check if the user provided any argumets at all
    if (argc < 2)
    {
        print_help();
        return EXIT_SUCCESS;
    }

    // Default Arguments
    uint64_t from_base = 10;
    uint64_t to_base = 2;
    char *target_number = NULL;

    // Define Command Line Options
    struct option long_options[] = {
        {"from", required_argument, 0, 'f'},
        {"from-base", required_argument, 0, 'f'},
        {"to", required_argument, 0, 't'},
        {"to-base", required_argument, 0, 't'},
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}};

    // Parse Command Line Options
    int opt;
    while ((opt = getopt_long(argc, argv, "f:t:hv", long_options, NULL)) != -1)
    {
        switch (opt)
        {
        case 'f':
            from_base = atoi(optarg);
            break;
        case 't':
            to_base = atoi(optarg);
            break;
        case 'h':
            print_help();
            return EXIT_SUCCESS;
        case 'v':
            print_version();
            return EXIT_SUCCESS;
        default:
            print_help();
            return EXIT_FAILURE;
        }
    }

    if (optind < argc)
    {
        // Convert each remaining argument (number) from the specified source base to the target base
        for (int i = optind; i < argc; i++)
        {
            convert_one(argv[i], from_base, to_base);
        }
    }
    else
    {
        // No number provided for conversion. Show an error message and the help message.
        fprintf(stderr, "Error: No number provided for conversion.\n");
        print_help();
        return EXIT_FAILURE;
    }

    // Exit the program successfully
    return EXIT_SUCCESS;
}
