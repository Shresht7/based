// Library
#include "stdio.h"
#include "stdlib.h"
#include "stdint.h"
#include "string.h"
#include "getopt.h"
#include "unistd.h"

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
    printf("%s", formatted_number);
}

/// @brief Converts a single number from one base to another and prints the result to stdout.
/// @param from_base The base of the input number.
/// @param to_base The base to convert the number to.
/// @param delimiter The delimiter to use between converted numbers.
void convert_stdin(uint64_t from_base, uint64_t to_base, const char *delimiter)
{
    size_t capacity = 1 << 16; // 64KB buffer
    size_t length = 0;
    char *input_buffer = malloc(capacity);
    if (!input_buffer)
    {
        fprintf(stderr, "Error: Memory allocation failed.\n");
        exit(EXIT_FAILURE);
    }

    size_t bytes_read;
    while ((bytes_read = fread(input_buffer + length, 1, capacity - length, stdin)) > 0)
    {
        length += bytes_read; // Update the length of the data read

        // Check if we need to resize the buffer, and if so, double its size
        if (length >= capacity)
        {
            capacity *= 2; // Double the buffer size
            char *new_buffer = realloc(input_buffer, capacity);
            if (!new_buffer)
            {
                fprintf(stderr, "Error: Memory allocation failed.\n");
                free(input_buffer);
                exit(EXIT_FAILURE);
            }
            input_buffer = new_buffer;
        }

        input_buffer[length] = '\0'; // Null-terminate the string for safety

        // Tokenize the input buffer by whitespace and convert each token (number) from the specified source base to the target base
        char *token = strtok(input_buffer, " \t\r\n");
        while (token)
        {
            convert(token, from_base, to_base); // Convert and print each token (number) from the input buffer
            token = strtok(NULL, " \t\r\n");    // Continue ~~token-ing~~ tokenizing the input buffer for the next number
            if (token)
            {
                printf("%s", delimiter); // Print the delimiter after each converted number
            }
        }

        free(input_buffer); // Free the buffer after processing
    }
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
    uint64_t from_base = 10; // Decimal
    uint64_t to_base = 2;    // Binary
    char *delimiter = "\n";  // Default delimiter is a newline character
    char *target_number = NULL;

    // Define Command Line Options
    struct option long_options[] = {
        {"from", required_argument, 0, 'f'},
        {"from-base", required_argument, 0, 'f'},
        {"to", required_argument, 0, 't'},
        {"to-base", required_argument, 0, 't'},
        {"delimiter", required_argument, 0, 'd'},
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 'v'},
        {0, 0, 0, 0}};

    // Parse Command Line Options
    int opt;
    while ((opt = getopt_long(argc, argv, "f:t:d:hv", long_options, NULL)) != -1)
    {
        switch (opt)
        {
        case 'f':
            from_base = atoi(optarg);
            break;
        case 't':
            to_base = atoi(optarg);
            break;
        case 'd':
            delimiter = optarg;
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
            convert(argv[i], from_base, to_base);
            if (i < argc - 1)
            {
                printf("%s", delimiter); // Print the delimiter after each converted number
            }
        }
    }
    else
    {
        if (isatty(STDIN_FILENO))
        {
            // No positional arguments and nothing piped into stdin, print help and exit
            fprintf(stderr, "Error: No number provided for conversion.\n");
            print_help();
            return EXIT_FAILURE;
        }

        // Read from stdin and convert each number
        convert_stdin(from_base, to_base, delimiter);
    }

    // Exit the program successfully
    return EXIT_SUCCESS;
}
