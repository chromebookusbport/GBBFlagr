# Building GBBflaggr: 
### Dependencies
You only need gcc, make, and musl-tools! All static libs are inside `lib/`

```
Debian-based systems: sudo apt install gcc make musl-tools
Arch-based systems: sudo pacman -S gcc make musl
Alpine-based systems: apk add gcc make
```

### Compiling: 
To compile GBBflagr, you only need to run a few commands

```
# First, clone the repo (insiders, use KVS-private)
git clone https://github.com/kxtzownsu/KVS

# Second, go into the directory (again, insiders, use KVS-private)
cd KVS

# Third, run two command to compile the KVS & KVG binary
make kvs # final binary is at ./build/bin/kvs
make kvg # final binary is at ./build/bin/kvg

# (OPTIONAL) Fourth, run the shim builder
sudo make shim-builder

# You can also run this instead of make
cd shim-builder/
sudo bash builder.sh
```

# Building it: 
### Dependencies
Same as KVS, you only need `gcc`, `make`, and `musl`

```
Debian-based systems: sudo apt install gcc make musl-tools
Arch-based systems: sudo pacman -S gcc make musl
Alpine-based systems: apk add gcc make
```

### Compiling 

```
git clone https://github.com/kxtzownsu/KVS # insiders, use KVS-private

cd KVS

make kvg # final binary will be at ./build/bin/kvg
```

# Cross-compiling
See [cross-compilation.md](cross-compilation.md).
