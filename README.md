# `based`

## Development

### "Standard Library"

I have a makeshift "standard library" for assembly: https://github.com/Shresht7/Learning-Assembly

The code in the [`library`](./library/) folder has been copy-pasted from there.

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
