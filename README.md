# `based`

A simple command-line utility to convert numbers between different bases.

## Usage

```sh
Usage: based [options] <value>

Options:
  -f, --from, --from-base <base>   Source base (default: 10)
  -t, --to, --to-base <base>       Target base (default: 2)
  -d, --delimiter <delimiter>      Delimiter for multiple values (default: newline)
  -h, --help                       Show this help message
  -v, --version                    Show version information

Notes:
  Prefixes 0x (hex), 0b (bin), and 0o (oct) are automatically detected from the value

```

### Examples

#### 1. Binary to Decimal:

```sh
$ ./based 1011 --from 2 --to 10
11
```

#### 2. Decimal to Hexadecimal:

```sh
$ ./based --from 10 --to 16 175
AF
```

#### 3. Hexadecimal to Octal:

```sh
$ ./based 0x1A3 --to 8
643
```

#### 4. Using Prefixes for Automatic Base Detection:

```sh
$ ./based 0b1101 --to 10
13
$ ./based 0xFF --to 2
11111111
$ ./based 0o77 --to 16
3F
```

---

## Development

### "Standard Library"

I have a makeshift "standard library" for assembly: https://github.com/Shresht7/Learning-Assembly

The code in the [`library`](./library/) folder has been copy-pasted from there.

### Build

Create a `build` directory if it doesn't exist:

```sh
mkdir -p build
```

Then, assemble the source code:

```sh
nasm -f elf64 ./src/based.asm -o ./build/based.o
```

### Link

Link the object file to create the executable:

```sh
ld ./build/based.o -o ./based
```

### Execute

Make it executable and run:

```sh
chmod +x ./based
```

```sh
./based --help
```

### Windows

Cursed

Compile the [`radix.asm`](./src/core/radix.asm) file with the `win64` output format:

```sh
nasm -f win64 ./src/based.asm -o ./build/based.obj
```

Then let `gcc` handle the rest:

```sh
gcc ./src/based.c ./build/based.obj -o ./based.exe
```

---

## 📄 License

[MIT License](./LICENSE)
