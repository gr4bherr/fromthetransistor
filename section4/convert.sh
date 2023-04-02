#1/bin/bash
# converts .c files to .s (riscv 32 bit assembly) using gcc

mkdir mytests

for file in c-testsuite/tests/single-exec/*.c; do
  riscv64-unknown-elf-gcc -O -S $file -o mytests/${file:30:5}.s -march=rv32imac -mabi=ilp32
done
