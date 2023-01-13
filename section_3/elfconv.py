#!/usr/bin/env python3
from elftools.elf.elffile import ELFFile
import struct
import glob
import os

print("converting...")

for test in glob.glob("riscv-tests/isa/rv32ui-p*"):
  if not test.endswith(".dump") and os.path.isfile(test):
    name = test[25:]
    with open(test, "rb") as bintest:
      elftest = ELFFile(bintest)
      d1 = elftest.get_segment(1).data()
    with open(f"converted-tests/{name}.bin", "wb") as f:
      f.write(d1)
    print(f"{name}: done")