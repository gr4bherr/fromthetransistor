#!/usr/bin/env python3
import glob
import re

# used to convert .dump files to machine code and assembly

for path in glob.glob("dump/rv32ui-p-simple.dump"):
#for path in glob.glob("dump/*"):
  name = path[path.index("-p-")+3:path.index(".dump")]
  outm = open(f"mtest/{name}.txt", "w") # out assembly
  outa = open(f"atest/{name}.s", "w") # out machine code
  print(name)
  with open(path, "r") as f:
    for line in f:
      if "#" in line: # comment
        line = line[:line.index("#")]
      line = line.replace("<", "")
      line = line.replace(">", "")
      line = line.strip().split()
      #print(line)
      # machine code
      if len(line) > 2:
        if re.search("^[0-9a-f]{8}$", line[1]):
          outm.write(line[1] + "\n")
      # assembly
      if line != []:
        if line[0][0] == "8":
          # label
          if ":" in line[1]:
            outa.write(str(line[1]) + "\n")
          # instruction
          else:
            if len(line) > 4:  # has label reference
              mnem = line[2]
              op = line[-2][:-8]
              num = (int(line[-2][-8:], 16) - int(line[0][:-1], 16)) // 4
              label = line[-1]
              if "+0x" not in line[-1]: # label 
                outa.write(f"{mnem} {op}{label}\n")
              else: # label with +
                outa.write(f"{mnem} {op}{num}\n")
            else:
              outa.write(" ".join(line[2:]) + "\n")

outm.close()
outa.close()

# beq t5, t6, 
#          t6    t5
# 0000001 11111 11110 000 00000 1100011

# beq t6,x0,          (beqz t6, )
#          x0    t5
# 0000000 00000 11110 000 01000 1100011

#  0000 0001 0000 0
#  0000 0000 0100 0


# 0000001 11111 11110 000 10000 1100011 beq	t5,t6,8000003c <write_tohost>
# 0000001 11111 11110 000 01000 1100011 beq	t5,t6,8000003c <write_tohost>
# 0000001 11111 11110 000 00000 1100011 beq	t5,t6,8000003c <write_tohost>
# 0000000 00000 11110 000 01000 1100011 beqz	t5,8000002c <trap_vector+0x28>
# 0000000 00000 11110 101 01000 1100011 bgez	t5,80000038 <handle_exception>
# 0000000 00100 00000 000 00000 1101111 j	80000038 <handle_exception>




