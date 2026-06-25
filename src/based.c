#include "stdio.h"
#include "stdlib.h"

void print_help()
{
    printf("Usage: based <number> <base>\n");
}

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        print_help();
        return 1;
    }

    char *number_str = argv[1];
    char *base_str = argv[2];

    printf("Number: %s\n", number_str);
    printf("Base: %s\n", base_str);

    return 0;
}
