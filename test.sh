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
