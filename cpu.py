#!/usr/bin/env python3

# disassembler for ARM7TDMI

#fl = open("machinecode.txt","r")
fl = open("assout.txt","r")
out = open("disassout.txt","w")
"""
conditions = {
  "0000": "EQ", "0001": "NE", "0010": "CS", "0011": "CC", 
  "0100": "MI", "0101": "PL", "0110": "VS", "0111": "VC", 
  "1000": "HI", "1001": "LS", "1010": "GE", "1011": "LT", 
  "1100": "GT", "1101": "LE", "1110": "AL" 
}
"""

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
  1 : "xxxx00xxxxxxxxxxxxxxxxxxxxxxxxxx", # data processing / psr transfer
  2 : "xxxx000000xxxxxxxxxxxxxx1001xxxx", # multiply
  3 : "xxxx00001xxxxxxxxxxxxxxx1001xxxx", # multiply long
  4 : "xxxx00010x00xxxxxxxx00001001xxxx", # single data swap
  5 : "xxxx000100101111111111110001xxxx", # branch and exchange
  6 : "xxxx000xx0xxxxxxxxxx00001xx1xxxx", # halfword data transfer: register offset
  7 : "xxxx000xx1xxxxxxxxxxxxxx1xx1xxxx", # halfword data transfer: immediate offset
  8 : "xxxx01xxxxxxxxxxxxxxxxxxxxxxxxxx", # single data transfer
  9 : "xxxx011xxxxxxxxxxxxxxxxxxxx1xxxx", # undefinded
  10: "xxxx100xxxxxxxxxxxxxxxxxxxxxxxxx", # block data transfer
  11: "xxxx101xxxxxxxxxxxxxxxxxxxxxxxxx", # branch
  12: "xxxx110xxxxxxxxxxxxxxxxxxxxxxxxx", # coprocessor data trasnfer
  13: "xxxx1110xxxxxxxxxxxxxxxxxxx0xxxx", # coprocessor data operation
  14: "xxxx1110xxxxxxxxxxxxxxxxxxx1xxxx", # coprocessor register transfer
  15: "xxxx1111xxxxxxxxxxxxxxxxxxxxxxxx"  # software interrupt
}
psrset = {
  1: "xxxx00010x001111xxxx000000000000",
  2: "xxxx00010x101001111100000000xxxx",
  3: "xxxx00x10x1010001111000000000000"
}


regs = {x:0 for x in range(16)} 
cprs = "0"*32
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
  print("CPRS:", cprs)

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


def alu(opcode, a, b):
  # status in and out over cpsr
  # AND
  if opcode == 0:
    None
  # EOR
  elif opcode == 1:
    None
  # SUB
  elif opcode == 2:
    None
  # RSB
  elif opcode == 3:
    None
  # ADD
  elif opcode == 4:
    None
  # ADC
  elif opcode == 5:
    None
  # SBC
  elif opcode == 6:
    None
  # RSC
  elif opcode == 7:
    None
  # TST
  elif opcode == 8:
    None
  # TEQ
  elif opcode == 9:
    None
  # CMP
  elif opcode == 10:
    None
  # CMN
  elif opcode == 11:
    None
  # ORR
  elif opcode == 12:
    None
  # MOV
  elif opcode == 13:
    return int(b, 2)
  # BIC
  elif opcode == 14:
    None
  #MVN
  elif opcode == 15:
    None

def barrelshifter(n, shiftammount, shift = 4):
  # todo rrx
  width = 32
  # LSL (ASL)
  if shift == 0:
    return n << shiftammount
  # LSR
  elif shift == 1:
    return n >> shiftammount
  # ASR
  elif shift == 2:
    num = (f"{n:032b}"[0] * shiftammount) + "0" * (width - shiftammount)
    return n >> shiftammount | int(num, 2)
  # ROR
  elif shift == 3:
    return (n >> shiftammount | n << (width - shiftammount)) & (2 ** width - 1)
  # 
  else:
    None

#mov r1, #5
#mov r2, r1, lsl #6
#mov r3, r1, lsr #6
#mov r4, r1, asr #6
#mov r5, r1, ror #6
#mov r6, r1, rrx
#1110 0011 1010 0000 0001 0000 0000 0101
#1110 0001 1010 0000 0010 0011 0000 0001
#1110 0001 1010 0000 0011 0011 0010 0001
#1110 0001 1010 0000 0100 0011 0100 0001
#1110 0001 1010 0000 0101 0011 0110 0001
#1110 0001 1010 0000 0110 0000 0110 0001

def operand2(val, i):
  # register
  if i == 0:
    None #todo
  # immediate value
  else:
    None






# main program
def advance():

  # FETCH
  instr = f"{bin(int(memory[regs[15]], 16))[2:]:>032}"
  print(instr)
  #memoryprint()
  regsprint()

  # DECODE
  cond = instr[0:4]
  instype = checktype(instr)
  #print(instype)
  opcode = int(instr[7:11], 2)
  #print(opcode)


  # EXECUTE
  if instype == 1:
    # psr transfer
    if ismatch(psrset[1], instr)[0] or ismatch(psrset[2], instr)[0] or ismatch(psrset[3], instr)[0]:
      print("psr")
    # data processing
    else:
      #111000111010 0000 0111 0000 0000 0001
      rd = int(instr[16:20], 2)
      rn = int(instr[12:16], 2)
      op2 = instr[20:32] # rm
      i = instr[6]
      print(rd, rn, op2, i)
      regs[rd] = alu(opcode, rn, op2)

   




  # SWI
  if instype == 15:
    #pc = 8 # todo
    print("SWI *********")
    exit()
  regs[15] += 4 # pc + 4



if __name__ == "__main__":
  load()
  memoryprint()
  print("\n"*4)
  while True:
    print()
    advance()


# MRS R0,CPSR
# xxxxxxxxxxxx
# 1110 0001 0000 1111 0000 0000 0000 0000
# cond 00x1 0x00 _rn_ _rd_ 0000 0000 0000

# MSR CPSR,R0
# 1110 0001 0010 1001 1111 0000 0000 0000