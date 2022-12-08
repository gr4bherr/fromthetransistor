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

class Regs:
  def __init__(self):
    # 16 registers
    self.regs = {x:0 for x in range(16)} 
    self.cpsr = ["0"] * 32
  
  def write(self, regnum, val):
    #self.regs[regnum] = twoscomp(val)
    self.regs[regnum] = val

  def read(self, regnum):
    #res = self.regs[regnum]
    ## negative value (two's complement)
    #if len(bin(res)) == 34:
      #res = -res
    #return res
    return self.regs[regnum]
  
  def increment(self, regnum):
    self.regs[regnum] += 4
  
  def setflag(self, flag, val):
    self.cpsr[flag] = str(val)

  def getflag(self, flag):
    return int(self.cpsr[flag])



r = Regs()
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
  for key, value in r.regs.items():
    print(f"R{key:<2}: {value:08x}", end="\t")
    if (key+1) % 4 == 0:
      print()
  tmp = "".join(r.cpsr)
  print(f"CPSR: {tmp} {int(tmp, 2):08x}")

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

# if val is negative
def twoscomp(val, bits=32):
  if (val & (1 << (bits-1))) != 0:
    val = val - (1 << bits)
  return val & ((2 ** bits) - 1)

# true = positive, false = negative
def sign(val):
  signextend = f"{val:032b}"
  return True if signextend[0] == "0" else False

def alu(opcode, dest, op1, op2):
  print("alu", dest, op1, op2)
  #print(opcode)
  print()
  cin = r.getflag(2)
  # status in and out over cpsr
  # AND
  if opcode == 0:
    res = op1 & op2
  # EOR
  elif opcode == 1:
    res = op1 ^ op2
  # SUB
  elif opcode == 2:
    res = op1 - op2
  # RSB
  elif opcode == 3:
    res = op2 - op1
  # ADD
  elif opcode == 4:
    res = op1 + op2
  # ADC
  elif opcode == 5:
    res = op1 + op2 + r.getflag(2)
  # SBC
  elif opcode == 6:
    res = op1 - op2 + r.getflag(2) - 1
  # RSC
  elif opcode == 7:
    res = op2 - op1 + r.getflag(2) - 1
  # TST
  elif opcode == 8:
    res = op1 & op2
  # TEQ
  elif opcode == 9:
    res = op1 ^ op2
  # CMP
  elif opcode == 10:
    res = op1 - op2
  # CMN
  elif opcode == 11:
    res = op1 + op2
  # ORR
  elif opcode == 12:
    res = op1 | op2
  # MOV
  elif opcode == 13:
    res = op2
  # BIC
  elif opcode == 14:
    res = op1 & ~op2
  #MVN
  elif opcode == 15:
    res = ~op2

  print(res)
  #res = twoscomp(res)
  #print(res)
  
  #if opcode not in [8,9,10,11]:
    #r.write(dest, res)

  # if S = 1
  # N
  # normal negative or two's complement negative
  if res < 0 or (len(bin(res)) == 34 and bin(res)[2] == "1"):
    r.setflag(0, 1)
  else:
    r.setflag(0, 0)
  # Z
  if res == 0:
    r.setflag(1, 1)
  else:
    r.setflag(1, 0)
  # C
  # add (unsigned overflow)
  if opcode in [4,5,11] and len(bin(res)) > max(len(bin(op1)), len(bin(op2))):
    print("a")
    r.setflag(2, 1)
  # sub (unsigned underflow)
  elif opcode in [2,3,6,710] and len(bin(res)) < max(len(bin(op1)), len(bin(op2))):
    print("b")
    r.setflag(2, 1)
  else:
    r.setflag(2, 0)
  # V
  # signed overflow or singed underflow
  print(sign(res))
  if (not sign(res) and sign(op1) and sign(op2)) or (sign(res) and not sign(op1) and not sign(op2)):
    r.setflag(3, 1)
  else:
    r.setflag(3, 0)



  res = twoscomp(res)
  if opcode not in [8,9,10,11]:
    r.write(dest, res)

def barrelshifter(n, shiftamount, shift = 4):
  # todo set carry flag
  width = 32
  # LSL (ASL)
  if shift == 0:
    return n << shiftamount
  # LSR
  elif shift == 1:
    return n >> shiftamount
  # ASR
  elif shift == 2:
    num = (f"{n:032b}"[0] * shiftamount) + "0" * (width - shiftamount)
    return n >> shiftamount | int(num, 2)
  # ROR, RRX
  elif shift == 3:
    # rrx
    if shiftamount == 0:
      carry = int(cpsr[2])
      shiftamount = 1
      return n >> shiftamount | carry << (width - 1)
    # ror
    else:
      return (n >> shiftamount | n << (width - shiftamount)) & (2 ** width - 1)

def operand2(val, i):
  # register
  if i == "0":
    shifttype = int(val[5:7], 2)
    # shift by imm
    if val[7] == "0":
      shiftam = int(val[:5], 2)
    # shift by reg
    else:
      shiftam = regs[int(val[:4], 2)]
    rm = r.read(int(val[8:], 2))
    return barrelshifter(rm, shiftam, shifttype)
  # immediate value
  else:
    rotate = int(val[:4], 2) * 2
    imm = int(val[4:], 2)
    if rotate == 0:
      return imm
    else:
      #res = barrelshifter(imm, rotate, 3)
      ## negative value (two's complement)
      #if len(bin(res)) == 34: 
        #res = -res
      #return res
      return barrelshifter(imm, rotate, 3)







# main program
def advance():

  # FETCH
  instr = f"{bin(int(memory[r.read(15)], 16))[2:]:>032}"
  #memoryprint()
  regsprint()
  print("\nINSTRUCION:", instr)

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
      rd = int(instr[16:20], 2)
      rn = int(instr[12:16], 2)
      rn = r.read(rn)
      i = instr[6]
      op2 = operand2(instr[20:32], i) # rm
      #print(opcode, rd, rn, op2, i)
      alu(opcode, rd, rn, op2)

   


  #regs[15] += 4 # pc + 4
  r.increment(15) # pc  + 4


  # SWI
  if instype == 15:
    #pc = 8 # todo
    print("SWI *********")
    exit()


if __name__ == "__main__":
  load()
  memoryprint()
  print("\n"*4)
  while True:
    advance()


# MRS R0,CPSR
# xxxxxxxxxxxx
# 1110 0001 0000 1111 0000 0000 0000 0000
# cond 00x1 0x00 _rn_ _rd_ 0000 0000 0000

# MSR CPSR,R0
# 1110 0001 0010 1001 1111 0000 0000 0000