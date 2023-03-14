#1/bin/bash
# converts .c files to .s using gcc

mkdir mytests

for file in c-testsuite/tests/single-exec/*.c; do
  riscv64-unknown-elf-gcc -S $file -o mytests/${file:30:5}.s
done
