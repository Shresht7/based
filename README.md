# `based`

`based` is a small command-line utility for converting unsigned integers between bases.

It started as a learning project, which is why the repository contains both a pure assembly CLI and a C wrapper around the same assembly radix routines. The assembly path was the fun part. The C wrapper came into existence because of my **skill issues** and Windows, and I decided it was `gcc`'s headache now. Learned about Foreign Function Interfaces (FFI) and calling conventions along the way.

This repository is home to two frontends that share the same assembly radix routines:
- `src/core/radix.asm`: A cli written in pure assembly for x86-64 Linux. It is a small, self-contained program that can be built and run on Linux.
- `src/based.c`: A C wrapper that uses the same assembly radix routines and can be built on Linux or Windows. It provides a more user-friendly interface with additional features like named base aliases, delimiter handling, and stdin batch conversion.

> [!WARNING]
> Goes without saying, but this project is **NOT** intended for any serious use. It is a learning exercise and a demonstration of assembly and C interop.

---

## Usage

```text
Usage: based [options] [value ...]

Options:
  -f, --from, --from-base <base>   Source base (default: 10)
  -t, --to, --to-base <base>       Target base (default: 2)
  -d, --delimiter <delimiter>      Delimiter for multiple values (default: newline)
  -h, --help                       Show this help message
  -v, --version                    Show version information

Notes:
  Prefixes 0x (hex), 0b (bin), and 0o (oct) are automatically detected from the value
  Base aliases such as `bin`, `binary`, `oct`, `octal`, `dec`, `decimal`, `hex`, and `hexadecimal` are supported
  If no value is provided, numbers may be read from stdin
```

#### Examples

```sh
./based --from 10 --to 16 175
# AF

./based --from decimal --to hex 175
# AF

./based --from 2 --to 10 1011 1111 --delimiter ", "
# 11, 15

printf "0xFF\n0b1010\n" | ./based --to 10
# 255
# 10
```

---

## Development

### Prerequisites

- `nasm`
- `ld` for the pure assembly Linux build
- `gcc` for the C wrapper build
- a POSIX shell for `build.sh` and `test.sh`

### Architecture

- `src/core/radix.asm`: shared radix logic (`detect_base`, `parse_uint`, `format_uint`)
- `src/based.asm`: pure assembly CLI for Linux
- `src/based.c`: C CLI that wraps the shared assembly radix code and can be built on Linux or Windows
- `library/`: small assembly support routines copied from the author's separate learning repo
- `tests/`: assembly unit tests plus shell-driven integration tests

```
./
├── library/                // small assembly support routines
│   ├── stdio.asm
│   ├── strutils.asm
│   └── syscalls.asm
├── src/                    // source code for the CLI frontends and shared radix logic
│   ├── based.asm           // pure assembly CLI for Linux
│   ├── based.c             // C CLI that wraps the shared assembly radix code
│   └── core/
│       └── radix.asm       // shared radix logic
├── tests/                  // unit tests
│   ├── assert.asm
│   └── radix.test.asm
├── README.md
├── LICENSE
├── .gitignore
├── build.sh                // build script for Linux
└── test.sh                 // test script for Linux
```

### Build The Pure Assembly CLI On Linux

The repo includes `build.sh` for this path:

```sh
./build.sh
```

Equivalent manual steps:

```sh
mkdir -p build
nasm -f elf64 ./src/based.asm -o ./build/based.o
ld ./build/based.o -o ./based
chmod +x ./based
```

### Build The C Wrapper On Linux

```sh
mkdir -p build
nasm -f elf64 ./src/core/radix.asm -o ./build/radix.o
gcc ./src/based.c ./build/radix.o -o ./based
```

### Build The C Wrapper On Windows

```sh
mkdir -p build
nasm -f win64 ./src/core/radix.asm -o ./build/radix.obj
gcc ./src/based.c ./build/radix.obj -o ./based.exe
```

That is the same shared radix code, just assembled for a different object format and ABI.

## OS Shenanigans

The shared radix routines were written around the System V AMD64 calling convention first.

That means the assembly code naturally thinks in terms of:

- integer/pointer arguments in `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`
- return value in `rax`

Windows x64 uses a different ABI:

- the first arguments arrive in `rcx`, `rdx`, `r8`, `r9`
- the callee-saved register set is different

To keep the radix logic shared, `src/core/radix.asm` checks whether NASM is assembling for `win64` and defines `WIN64_ABI` when needed. That path remaps incoming registers and preserves the registers that Windows requires to survive function calls.

So the project sidesteps most of the platform-specific CLI/runtime differences like this:

- Linux assembly build: use the pure assembly CLI directly
- Linux or Windows portable build: compile the radix core for the target format and let the C frontend handle option parsing and stdio


## Tests

Run the current test suite with:

```sh
./test.sh
```

What it covers today:

- unit tests for `parse_uint`, `format_uint`, and `detect_base`
- integration tests for the pure assembly CLI

The test script is shell-based and primarily aimed at Unix-like environments.

> [!NOTE]
> ### Testing Framework
> 
> I rolled my own assertion framework in assembly for this project. It is a small set of macros that allow you to write unit tests in assembly and assert expected values. The framework is located in [`tests/assert.asm`](./tests/assert.asm) and is used by [`tests/radix.test.asm`](./tests/radix.test.asm) to test the shared radix routines.
> 
## Known Limitations

- Parsing the maximum `uint64` value is a known issue.
- The pure assembly CLI is intentionally smaller in scope than the C wrapper due to my **skill issues**. In particular, delimiter handling, stdin batch conversion, and named base aliases are currently only supported in the C wrapper.
- The shared radix routines operate on unsigned integers and support bases `2` through `16`.

---

## What did I Learn doing this?

- `gdb` is the **GOAT**.
- Writing assembly is a pain. ~~and that I am a masochist.~~
- Calling conventions are a thing.
- Foreign Function Interfaces are awesome!
- Windows has to be different for no apparent reason.
- Every assembly project is me _trying_ to reinvent C from first principles.
- Segfaults humbled me.

---

## License

[MIT License](./LICENSE)
