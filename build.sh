#!/usr/bin/env sh

SRC="src"
BUILD="build"

NAME="based"

# Create build directory
mkdir -p "$BUILD"

# Compile source files
nasm -f elf64 "$SRC/$NAME.asm" -o "$BUILD/$NAME.o"

# Link object files
ld "$BUILD/$NAME.o" -o "./$NAME"

# Make the output executable file executable
chmod +x "./$NAME"

echo "Build completed successfully. Executable created: ./$NAME ☑️"
