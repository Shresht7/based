#!/usr/bin/env sh

# VARS
# ----

SRC="src"
TESTS="tests"
BUILD="build"
NAME="based"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Ensure that the build directory exists
mkdir -p "$BUILD"

# STATE
# -----

FAILURES=0  # Track the number of failed tests
TOTAL=0     # Track the total number of tests run

# UNIT TESTS (PURE ASSEMBLY)
# --------------------------

for test_file in "$TESTS"/*.test.asm; do
    [ -e "$test_file" ] || continue                             # Skip if no test files are found

    test_name=$(basename "$test_file" .test.asm)                # Extract base-name
    nasm -f elf64 "$test_file" -o "$BUILD/$test_name.o"         # Compile the test file
    ld "$BUILD/$test_name.o" -o "$BUILD/$test_name.test"        # Link the object file to create an executable
    chmod +x "$BUILD/$test_name.test"                           # Make the test executable

    echo -e "\n${YELLOW}=== Running Unit Test: $test_name ===${RESET}"

    OUTPUT=$("$BUILD/$test_name.test")                          # Run the test and capture output
    echo "$OUTPUT"                                              # Print the output to view the assertion logs

    if echo "$OUTPUT" | grep -q "FAIL"; then                    # Check for "FAIL" in the output
        echo -e "\n${RED}Tests failed: $test_name ❌${RESET}"
        FAILURES=$((FAILURES + 1))                              # Increment failure count
    else
        echo -e "\n${GREEN}Tests passed: $test_name ☑️${RESET}"
    fi

    TOTAL=$((TOTAL + 1))                                        # Increment total test count
done

# BUILD MAIN EXECUTABLE
# ---------------------

nasm -f elf64 src/based.asm -o "$BUILD/$NAME.o"
ld "$BUILD/$NAME.o" -o "./$NAME"
chmod +x "./$NAME"

# INTEGRATION TESTS
# -----------------

echo -e "\n${YELLOW}=== Running Integration Tests ===${RESET}\n"

# Usage: assert_exact <arguments> <expected_output> <test_description>
assert_exact() {
    TOTAL=$((TOTAL + 1))  # Increment total test count
    local args="$1"
    local expected="$2"
    local description="$3"

    # Run the command and capture output
    local output=$(./$NAME $args)
    
    if [ "$output" = "$expected" ]; then
        echo -e "[ ${GREEN}PASS${RESET} ]: $description"
    else
        echo -e "[ ${RED}FAIL${RESET} ]: $description"
        echo -e "       Expected: '${GREEN}$expected${RESET}'"
        echo -e "       Got:      '${RED}$output${RESET}'\n"
        FAILURES=$((FAILURES + 1))
    fi
}

# Usage: assert_contains <arguments> <expected_substring> <test_description>
assert_contains() {    
    TOTAL=$((TOTAL + 1))  # Increment total test count
    local args="$1"
    local expected_substring="$2"
    local description="$3"

    # Run the command and capture output
    local output=$(./$NAME $args)
    
    if [[ "$output" == *"$expected_substring"* ]]; then
        echo -e "[ ${GREEN}PASS${RESET} ]: $description"
    else
        echo -e "[ ${RED}FAIL${RESET} ]: $description"
        echo -e "       Expected to contain: '${GREEN}$expected_substring${RESET}'"
        echo -e "       Got:                 '${RED}$output${RESET}'\n"
        FAILURES=$((FAILURES + 1))
    fi
}

# Help and Usage
assert_contains ""                          "Usage"     "should print usage when no arguments are provided"
assert_contains "--help"                    "Usage"     "should print usage when --help is provided"
assert_contains "-h"                        "Usage"     "should print usage when -h is provided"

# Conversion Tests
assert_exact "--from 10 --to 2 15"          "1111"      "should convert 15 from base 10 to base 2"
assert_exact "--from 2 --to 10 1111"        "15"        "should convert 1111 from base 2 to base 10"
assert_exact "--from 16 --to 10 F"          "15"        "should convert F from base 16 to base 10"

# Argument Order and Defaults
assert_exact "12 --from 10 --to 16"          "C"         "should accept arguments in any order"
assert_exact "14 --to 2"                     "1110"      "should default to base 10 when --from is not provided"
assert_exact "A --from 16"                   "1010"      "should default to base 2 when --to is not provided"

# Prefix Detection
assert_exact "0xAF --to 10"                  "175"       "should detect base from prefix 0x for hexadecimal"
assert_exact "0b11011 --to 10"               "27"        "should detect base from prefix 0b for binary"

# Aliases for --from and --to
assert_exact "10 --from-base 2 --to-base 10" "2"        "should support aliases for --from and --to"

# SUMMARY REPORT
# --------------

echo -e "\n${YELLOW}=== Test Summary ===${RESET}\n"

echo -e "Total tests run: ${TOTAL}"
echo -e "Tests passed:    ${GREEN}$((TOTAL - FAILURES))${RESET}"
echo -e "Tests failed:    ${RED}$FAILURES${RESET}\n"

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}All Unit and Integration tests passed! ☑️${RESET}\n"
    exit 0
else
    echo -e "${RED}Encountered $FAILURES test failure(s). ❌${RESET}\n"
    exit 1
fi
