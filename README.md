# `based`

## Development

### Build

```sh
nasm -f elf64 ./src/based.asm -o ./build/based.o
```

### Link

```sh
ld ./build/based.o -o ./based
```

### Execute

```sh
./based
```

---

## 📄 License

[MIT License](./LICENSE)
