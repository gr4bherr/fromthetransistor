#!/usr/bin/env python3

# disassembler for ARM7TDMI

f = open("machinecode.txt","r")
out = open("disassout.txt","w")

conditions = {
  "0000": "EQ", "0001": "NE", "0010": "CS", "0011": "CC", 
  "0100": "MI", "0101": "PL", "0110": "VS", "0111": "VC", 
  "1000": "HI", "1001": "LS", "1010": "GE", "1011": "LT", 
  "1100": "GT", "1101": "LE", "1110": "AL" 
}




def advance(instr):
  print(instr)
  cond = conditions[instr[0:4]]



  print(cond)
  print()


# checking only a few instr
fuck = 0 
if __name__ == "__main__":
  for line in f:
    line = line.strip()
    if fuck == 5:
      exit()
    # remove this if statement later
    if "@" in line:
      print("-" * 8, line[line.index("@"):])
      line = line[:line.index("@")-1]
    if line != "":
      fuck += 1
      b = ""
      # hex to bin
      for char in line:
        b += bin(int(char, 16))[2:].zfill(4)
      advance(b)