#!/usr/bin/env sh

TESTS="tests"
BUILD="build"

# Create build directory
mkdir -p "$BUILD"

# Compile test files
for test_file in "$TESTS"/*.test.asm; do
    test_name=$(basename "$test_file" .test.asm)
    nasm -f elf64 "$test_file" -o "$BUILD/$test_name.o"
    ld "$BUILD/$test_name.o" -o "$BUILD/$test_name.test"
    chmod +x "$BUILD/$test_name.test"
done

# Run tests
for test_file in "$BUILD"/*.test; do
    echo "Running test: $test_file"
    OUTPUT=$("$test_file")
    echo "$OUTPUT"
    if echo "$OUTPUT" | grep -q "FAIL"; then
        echo -e "\nTests failed: $test_file ❌"
        exit 1
    else
        echo -e "\nTests passed: $test_file ☑️"
    fi
done

# Build the main program
nasm -f elf64 src/based.asm -o "$BUILD/based.o"
ld "$BUILD/based.o" -o "./based"

# Make it executable
chmod +x "./based"

# Run integration tests
echo -e "\nRunning integration tests..."

# ./based       should print usage when no arguments are provided
OUTPUT=$(./based)
if echo "$OUTPUT" | grep -q "usage"; then
    echo "Integration test passed: ./based with no arguments prints usage ☑️"
else
    echo "Integration test failed: ./based with no arguments does not print usage ❌"
    exit 1
fi

# ./based --help     should print usage when --help is provided
OUTPUT=$(./based --help)
if echo "$OUTPUT" | grep -q "usage"; then
    echo "Integration test passed: ./based with --help prints usage ☑️"
else
    echo "Integration test failed: ./based with --help does not print usage ❌"
    exit 1
fi

# ./based --from 10 --to 2 15     should convert 15 from base 10 to base 2
OUTPUT=$(./based --from 10 --to 2 15)
if echo "$OUTPUT" | grep -q "1111"; then
    echo "Integration test passed: ./based --from 10 --to 2 15 converts to 1111 ☑️"
else
    echo "Integration test failed: ./based --from 10 --to 2 15 does not convert to 1111 ❌"
    exit 1
fi

# ./based --from 2 --to 10 1111     should convert 1111 from base 2 to base 10
OUTPUT=$(./based --from 2 --to 10 1111)
if echo "$OUTPUT" | grep -q "15"; then
    echo "Integration test passed: ./based --from 2 --to 10 1111 converts to 15 ☑️"
else
    echo "Integration test failed: ./based --from 2 --to 10 1111 does not convert to 15 ❌"
    exit 1
fi

# ./based --from 16 --to 10 F     should convert F from base 16 to base 10
OUTPUT=$(./based --from 16 --to 10 F)
if echo "$OUTPUT" | grep -q "15"; then
    echo "Integration test passed: ./based --from 16 --to 10 F converts to 15 ☑️"
else
    echo "Integration test failed: ./based --from 16 --to 10 F does not convert to 15 ❌"
    exit 1
fi

# ./based 12 --from 10 --to 16     should accept arguments in any order
OUTPUT=$(./based 12 --from 10 --to 16)
if echo "$OUTPUT" | grep -q "C"; then
    echo "Integration test passed: ./based 12 --from 10 --to 16 converts to C ☑️"
else
    echo "Integration test failed: ./based 12 --from 10 --to 16 does not convert to C ❌"
    exit 1
fi

# ./based 14 --to 2     should default to base 10 when --from is not provided
OUTPUT=$(./based 14 --to 2)
if echo "$OUTPUT" | grep -q "1110"; then
    echo "Integration test passed: ./based 14 --to 2 converts to 1110 ☑️"
else
    echo "Integration test failed: ./based 14 --to 2 does not convert to 1110 ❌"
    exit 1
fi

# ./based A --from 16     should default to base 2 when --to is not provided
if ./based A --from 16 | grep -q "1010"; then
    echo "Integration test passed: ./based A --from 16 converts to 1010 ☑️"
else
    echo "Integration test failed: ./based A --from 16 does not convert to 1010 ❌"
    exit 1
fi

#./based 0xAF --to 10     should detect base from prefix
OUTPUT=$(./based 0xAF --to 10)
if echo "$OUTPUT" | grep -q "175"; then
    echo "Integration test passed: ./based 0xAF --to 10 converts to 175 ☑️"
else
    echo "Integration test failed: ./based 0xAF --to 10 does not convert to 175 ❌"
    exit 1
fi

# ./based 0b11011 --to 10     should detect base from prefix
OUTPUT=$(./based 0b11011 --to 10)
if echo "$OUTPUT" | grep -q "27"; then
    echo "Integration test passed: ./based 0b11011 --to 10 converts to 27 ☑️"
else
    echo "Integration test failed: ./based 0b11011 --to 10 does not convert to 27 ❌"
    exit 1
fi

# ./based 10 --from-base 2 --to-base 10     should support --from-base and --to-base as aliases for --from and --to
OUTPUT=$(./based 10 --from-base 2 --to-base 10)
if echo "$OUTPUT" | grep -q "2"; then
    echo "Integration test passed: ./based 10 --from-base 2 --to-base 10 converts to 2 ☑️"
else
    echo "Integration test failed: ./based 10 --from-base 2 --to-base 10 does not convert to 2 ❌"
    exit 1
fi
