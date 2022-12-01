#!/usr/bin/env python3

# disassembler for ARM7TDMI

#fl = open("machinecode.txt","r")
fl = open("assout.txt","r")
out = open("disassout.txt","w")

conditions = {
  "0000": "EQ", "0001": "NE", "0010": "CS", "0011": "CC", 
  "0100": "MI", "0101": "PL", "0110": "VS", "0111": "VC", 
  "1000": "HI", "1001": "LS", "1010": "GE", "1011": "LT", 
  "1100": "GT", "1101": "LE", "1110": "AL" 
}

mlist  = [
  "UMULL", "UMLAL", "SMULL", "SMLAL",
  "LDR", "STR", "LDM", "STM",
  "MRS", "MSR", "MUL", "MLA",
  "SWP", "SWI",
  "AND", "EOR", "SUB", "RSB",
  "match", "ADC", "SBC", "RSC",
  "TST", "TEQ", "CMP", "CMN",
  "ORR", "MOV", "BIC", "MVN",
  "BX", "BL", "B"
] 

instructionset = {
  1  : "xxxx00xxxxxxxxxxxxxxxxxxxxxxxxxx", # data processing / psr transfer
  2  : "xxxx000000xxxxxxxxxxxxxx1001xxxx", # multiply
  3  : "xxxx00001xxxxxxxxxxxxxxx1001xxxx", # multiply long
  4  : "xxxx00010x00xxxxxxxx00001001xxxx", # single data swap
  5  : "xxxx000100101111111111110001xxxx", # branch and exchange
  6  : "xxxx000xx0xxxxxxxxxx00001xx1xxxx", # halfword data transfer: register offset
  7  : "xxxx000xx1xxxxxxxxxxxxxx1xx1xxxx", # halfword data transfer: immediate offset
  8  : "xxxx01xxxxxxxxxxxxxxxxxxxxxxxxxx", # single data transfer
  9  : "xxxx011xxxxxxxxxxxxxxxxxxxx1xxxx", # undefinded
  10 : "xxxx100xxxxxxxxxxxxxxxxxxxxxxxxx", # block data transfer
  11 : "xxxx101xxxxxxxxxxxxxxxxxxxxxxxxx", # branch
  12 : "xxxx110xxxxxxxxxxxxxxxxxxxxxxxxx", # coprocessor data trasnfer
  13 : "xxxx1110xxxxxxxxxxxxxxxxxxx0xxxx", # coprocessor data operation
  14 : "xxxx1110xxxxxxxxxxxxxxxxxxx1xxxx", # coprocessor register transfer
  15 : "xxxx1111xxxxxxxxxxxxxxxxxxxxxxxx"  # software interrupt
}


regs = {x:0 for x in range(16)}
memsize = 64 # in bytes
memory = {x:"a"*8 for x in range(0, memsize, 4)}

# some printing functions
def memoryprint():
  print("memory","-"*54)
  for key, value in memory.items():
    print(f"M{key:<2}: {value}", end="\t")
    if (key+4) % 16 == 0:
      print()
def regsprint():
  print("registers","-"*51)
  for key, value in regs.items():
    print(f"R{key:<2}: {value:08x}", end="\t")
    if (key+1) % 4 == 0:
      print()

# load program into memroy (done by os?)
def load():
  for i,line in enumerate(fl):
    memory[i*4] = line.strip()

# finds best match from instruction set
def ismatch(pattern, b):
  score = 0
  match = True
  # cycle through characters of pattern
  for i in range(len(pattern)):
    if pattern[i] == b[i]:
      score += 1
    elif pattern[i] != "x":
      match = False
      break
  return match, score

# determines current instruction type
def checktype(b):
  # finds best match in instruction set
  maxscore = 0
  # cycle through instrucitonset
  for name, pattern in instructionset.items():
    match, score = ismatch(pattern, b)
    #fuck = ismatch(pattern, b)
    if match and score > maxscore:
      res = name
      maxscore = score
  return res

# main program
def advance():
  instr = f"{bin(int(memory[regs[15]], 16))[2:]:>032}"
  print(instr)
  #memoryprint()
  regsprint()
  #print(instr)
  #cond = conditions[instr[0:4]]
  instype = checktype(instr)
  print(instype)



  # SWI
  if instype == 15:
    #pc = 8 # todo
    exit()
  regs[15] += 4 # pc + 4



if __name__ == "__main__":
  load()
  memoryprint()
  print()
  while True:
    print()
    advance()


# MRS R0,CPSR
# xxxxxxxxxxxx
# 1110 0001 0000 1111 0000 0000 0000 0000
# cond 00x1 0x00 _rn_ _rd_ 0000 0000 0000

# MSR CPSR,R0
# 1110 0001 0010 1001 1111 0000 0000 0000