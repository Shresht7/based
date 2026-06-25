#!/usr/bin/env sh

# VARS
# ----

SRC="src"
TESTS="tests"
BUILD="build"
NAME="based"
WRAPPER_NAME="based_c"

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

# BUILD C WRAPPER EXECUTABLE
# --------------------------

nasm -f elf64 src/core/radix.asm -o "$BUILD/radix.o"
gcc "$SRC/$NAME.c" "$BUILD/radix.o" -o "./$WRAPPER_NAME"

# INTEGRATION TESTS
# -----------------

echo -e "\n${YELLOW}=== Running Integration Tests ===${RESET}\n"

# Usage: assert_exact <command> <arguments> <expected_output> <test_description>
assert_exact() {
    TOTAL=$((TOTAL + 1))  # Increment total test count
    local command="$1"
    local args="$2"
    local expected="$3"
    local description="$4"

    # Run the command and capture output
    local output=$(eval "$command $args")
    
    if [ "$output" = "$expected" ]; then
        echo -e "[ ${GREEN}PASS${RESET} ]: $description"
    else
        echo -e "[ ${RED}FAIL${RESET} ]: $description"
        echo -e "       Expected: '${GREEN}$expected${RESET}'"
        echo -e "       Got:      '${RED}$output${RESET}'\n"
        FAILURES=$((FAILURES + 1))
    fi
}

# Usage: assert_contains <command> <arguments> <expected_substring> <test_description>
assert_contains() {    
    TOTAL=$((TOTAL + 1))  # Increment total test count
    local command="$1"
    local args="$2"
    local expected_substring="$3"
    local description="$4"

    # Run the command and capture output
    local output=$(eval "$command $args")
    
    if [[ "$output" == *"$expected_substring"* ]]; then
        echo -e "[ ${GREEN}PASS${RESET} ]: $description"
    else
        echo -e "[ ${RED}FAIL${RESET} ]: $description"
        echo -e "       Expected to contain: '${GREEN}$expected_substring${RESET}'"
        echo -e "       Got:                 '${RED}$output${RESET}'\n"
        FAILURES=$((FAILURES + 1))
    fi
}

# PURE ASSEMBLY CLI INTEGRATION TESTS
# -----------------------------------

echo -e "\n${YELLOW}=== Pure Assembly CLI Integration Tests ===${RESET}\n"

# Help and Usage
assert_contains "./$NAME" ""                           "Usage"  "asm cli should print usage when no arguments are provided"
assert_contains "./$NAME" "--help"                     "Usage"  "asm cli should print usage when --help is provided"
assert_contains "./$NAME" "-h"                         "Usage"  "asm cli should print usage when -h is provided"

# Conversion Tests
assert_exact "./$NAME" "--from 10 --to 2 15"           "1111"   "asm cli should convert 15 from base 10 to base 2"
assert_exact "./$NAME" "--from 2 --to 10 1111"         "15"     "asm cli should convert 1111 from base 2 to base 10"
assert_exact "./$NAME" "--from 16 --to 10 F"           "15"     "asm cli should convert F from base 16 to base 10"
assert_exact "./$NAME" "--from 8 --to 16 77"           "3F"     "asm cli should convert 77 from base 8 to base 16"

# Argument Order and Defaults
assert_exact "./$NAME" "12 --from 10 --to 16"          "C"      "asm cli should accept arguments in any order"
assert_exact "./$NAME" "14 --to 2"                     "1110"   "asm cli should default to base 10 when --from is not provided"
assert_exact "./$NAME" "A --from 16"                   "1010"   "asm cli should default to base 2 when --to is not provided"

# Prefix Detection
assert_exact "./$NAME" "0xAF --to 10"                  "175"    "asm cli should detect base from prefix 0x for hexadecimal"
assert_exact "./$NAME" "0b11011 --to 10"               "27"     "asm cli should detect base from prefix 0b for binary"
assert_exact "./$NAME" "0o77 --to 16"                  "3F"     "asm cli should detect base from prefix 0o for octal"

# Aliases for --from and --to
assert_exact "./$NAME" "10 --from-base 2 --to-base 10" "2"      "asm cli should support aliases for --from and --to"

# C WRAPPER CLI INTEGRATION TESTS
# -------------------------------

echo -e "\n${YELLOW}=== C Wrapper CLI Integration Tests ===${RESET}\n"

# Help and Usage
assert_contains "./$WRAPPER_NAME" ""                                         "Usage"  "wrapper cli should print usage when no arguments are provided"
assert_contains "./$WRAPPER_NAME" "--help"                                   "Usage"  "wrapper cli should print usage when --help is provided"

# Numeric and named-base conversions
assert_exact "./$WRAPPER_NAME" "--from 10 --to 16 175"                       "AF"     "wrapper cli should convert 175 from base 10 to base 16"
assert_exact "./$WRAPPER_NAME" "--from decimal --to hex 175"                 "AF"     "wrapper cli should support long named base aliases"
assert_exact "./$WRAPPER_NAME" "--from hex --to decimal FF"                  "255"    "wrapper cli should support short named base aliases"
assert_exact "./$WRAPPER_NAME" "--from-base octal --to-base binary 77"       "111111" "wrapper cli should support named aliases with long option aliases"
assert_exact "./$WRAPPER_NAME" "--from b --to h 11111111"                    "FF"     "wrapper cli should support one-letter base aliases"

# Multiple values and delimiter handling
assert_exact "./$WRAPPER_NAME" "--from 2 --to 10 1011 1111 --delimiter ', '" "11, 15" "wrapper cli should convert multiple values with a custom delimiter"

# Prefix detection and stdin conversion
assert_exact "./$WRAPPER_NAME" "0xAF --to 10"                                "175"    "wrapper cli should detect base from prefix 0x"
assert_exact "./$WRAPPER_NAME" "0o77 --to decimal"                           "63"     "wrapper cli should detect base from prefix 0o with named target base"
assert_exact "printf 'FF A\n' | ./$WRAPPER_NAME --from hex --to decimal --delimiter ':'" "" "255:10" "wrapper cli should read multiple values from stdin with a custom delimiter"

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
