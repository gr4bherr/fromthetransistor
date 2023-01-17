#!/usr/bin/env python3
import glob
import re

# used to convert .dump files to:
# - assembly (for assembler input)
# - machine code (for assembler output testing)

for path in sorted(glob.glob("mytests/*.dump")):
#for path in glob.glob("dump/*"):
  name = path[8:path.index(".dump")]
  outa = open(f"mytests/{name}.s", "w") # out assembly
  outm = open(f"mytests/{name}-cmp.txt", "w") # out machine code
  print(name)
  with open(path, "r") as f:
    for line in f:
      if "#" in line: # comment
        line = line[:line.index("#")]
      line = line.replace("<", "")
      line = line.replace(">", "")
      line = line.strip().split()
      #print(line)
      # assembly
      if line != [] and line[0][0] == "8":
        # label
        if ":" in line[1]:
          outa.write(str(line[1]) + "\n")
        # instruction
        else:
          if len(line) > 4:  # has label reference
            mnem = line[2]
            op = line[-2][:-8]
            num = (int(line[-2][-8:], 16) - int(line[0][:-1], 16))
            label = line[-1]
            if "+0x" not in line[-1]: # label 
              outa.write(f"{mnem} {op}{label}\n")
            else: # label with +
              outa.write(f"{mnem} {op}{num}\n")
          else:
            outa.write(" ".join(line[2:]) + "\n")
      # machine code
      if len(line) > 2:
        if re.search("^[0-9a-f]{8}$", line[1]):
          outm.write(line[1] + "\n")
          # unimp (end)
          if line[1] == "c0001073":
            break

outa.close()
outm.close()
