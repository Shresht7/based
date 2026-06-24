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
    "$test_file"
    if [ $? -eq 0 ]; then
        echo -e "\nTest passed: $test_file ✅"
    else
        echo -e "\nTest failed: $test_file ❌"
    fi
done
