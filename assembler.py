#!/usr/bin/env python3
import sys
import re


# assembler for ARM7TDMI
# no wrong input checking 
# no coprocessor
# no thumb mode
# TODO:
# code types (directives, etc.)
# registers as class?
# work in hexa?

f = open(sys.argv[1], "r")
out = open("assout.txt", "w")

condnames = ["EQ", "NE", "CS", "CC", "MI", "PL", "VS", "VC", "HI", "LS", "GE", "LT", "GT", "LE", "AL"]
conditions = {f"{val}": f"{i:04b}" for i, val in enumerate(condnames)}

mlist  = [
  "UMULL", "UMLAL", "SMULL", "SMLAL",
  "LDR", "STR", "LDM", "STM",
  "MRS", "MSR", "MUL", "MLA",
  "SWP", "SWI",
  "AND", "EOR", "SUB", "RSB",
  "ADD", "ADC", "SBC", "RSC",
  "TST", "TEQ", "CMP", "CMN",
  "ORR", "MOV", "BIC", "MVN",
  "BX", "BL", "B"
] 
opcodes = {f"{val}": f"{i:04b}" for i, val in enumerate(mlist[14:30])}

registers = {f"R{i}": f"{i:04b}" for i in range(16)} |\
            {f"C{i}": f"{i:04b}" for i in range(16)} |\
            {f"{val}": f"{i:04b}" for i, val in enumerate(["SP", "LR", "PC"], 13)} |\
            {"CPSR": "0", "SPSR": "1"}

shiftname = {f"{val}": f"{i:02b}" for i, val in enumerate(["LSL", "LSR", "ASR", "ROR"])} |\
            {"ASL": "00", "RRX": "XX"}

class Mnemonic:
  def __init__(self,instr):
    for item in mlist:
      self.name = item
      # instr found in mlist
      if item in instr:
        self.code = opcodes[item] if item in opcodes else ""
        self.extra = instr[len(item):]
        # instr has condition 
        if self.extra[:2] in conditions:
          self.cond = conditions[self.extra[:2]]
          self.extra = self.extra[2:]
        else:
          self.cond = "1110"
        break

class Operands:
  def __init__(self,instr):
    self.regs = [registers[it] for it in re.findall("[R|C][0-9]+|SP|LR|PC|CPSR|SPSR", instr)]
    self.imm = re.findall("#[+|-]?[0-9]x?[A-Z0-9]*", instr)
    self.imm = self.imm[0] if self.imm else None
    self.shift = [shiftname[it] for it in re.findall("LSL|LSR|ASR|ROR|ASL|RRX", instr)]
    self.shift = self.shift[0] if self.shift else None
    self.extra = re.findall(",|!|\^|\[|\]|{|}|_|-", instr)

  def _immediate(self, val, size, rotate = False): 
    # remove #
    val = val[val.index("#") + 1:]
    # remove -
    val = val[1:] if "-" in val else val
    # hex
    if len(val) > 2 and val[1] == "X":
      val = f"{int(val[2:], 16)}"
    num = f"{int(val):0{size}b}"
    # rotate
    if rotate:
      # number needs rotating
      if "1" in num and num[-1] != "1":
        # (a,b) is range of ones
        a = num.index("1")
        b = max(i for i, val in enumerate(num) if val == "1") + 1
        b += 1 if b % 2 != 0 else 0
        # num = rotate + num
        num = f"{b//2:04b}{num[a:b]:0>8}"
    return num

  def opnum(self):
    return len(self.regs) + (1 if self.imm else 0)
   
  def operand2(self, rotate = True, noshiftsize = 12):
    # shift
    if self.shift:
      # reg with imm shift
      if self.imm:
        shift = self._immediate(self.imm, 5) + self.shift + "0"
        rm = self.regs[-1]
      # reg with reg shift or rrx
      else:
        # rrx
        if self.shift == "XX":
          shift = "00000110" # todo technically an imm shift
          rm = self.regs[-1]
        else:
          shift = f"{self.regs[-1]}0{self.shift}1"
          rm = self.regs[-2]
      return shift + rm
    # no shift
    else:
      # imm
      if self.imm:
        return self._immediate(self.imm, noshiftsize, rotate)
      # reg
      else:
        return "0" * (noshiftsize-4) + self.regs[-1]

  def bit32imm(self):
    return self._immediate(self.imm, 12, True)

  def mode2(self):
    return self.operand2(False)
  
  def mode3(self, s, h):
    offset = self.operand2(False, 8)
    return f"{offset[:4]}1{s}{h}1{offset[4:]}"

  def addressing(self):
    #pre indexed
    if self.extra.index("[") - self.extra.index("]") == -1:
      return True
    # post indexed
    else:
      return False

  def reglist(self):
    res = ["0"] * 16
    x = self.extra.index("{") 
    i = 1
    while i < len(self.regs):
      if self.extra[x+i] == "-":
        a = 15-int(self.regs[i], 2)
        b = 15-int(self.regs[i+1], 2)
        for s in range(b, a+1):
          res[s] = "1"
        i += 2
      else:
        res[15 - int(self.regs[i], 2)] = "1"
        i += 1
    return "".join(res)

# 1110 1111 000000000000000000000000

def advance(mnemonic,operands):
  #print()
  #print(mnemonic, operands)
  m = Mnemonic(mnemonic)
  #print([m.name, m.code, m.cond, m.extra])
  o = Operands(operands)
  #print([o.regs, o.imm, o.shift, o.extra])
  
  # BRANCH AND EXCHANGE
  if m.name == "BX":
    return f"{m.cond}000100101111111111110001{o.regs[0]}"
  # BRANCH AND BRANCH WITH LINK
  elif m.name in ["B", "BL"]:
    l = 1 if m.name == "BL" else 1
    offset = "0"*24 # todo idk man
    return f"{m.cond}101{l}{offset}"
  # DATA PROCESSING
  elif m.name in opcodes:
    # MOV, MVN
    if m.name in ["MOV", "MVN"]:
      rn = "0000"
      rd = o.regs[0]
    # CMP, CMN, TEQ, TST
    elif m.name in ["CMP", "CMN", "TEQ", "TST"]:
      rn = o.regs[0]
      rd = "0000"
    # AND,EOR, SUB, RSB, ADD,ADC, SBC, RSC, ORR, BIC
    else:
      rn = o.regs[1]
      rd = o.regs[0]
    s = 1 if m.extra == "S" else 0
    # operand 2 is imm / reg
    i = 1 if o.imm and not o.shift else 0
    return f"{m.cond}00{i}{m.code}{s}{rn}{rd}{o.operand2()}"
  # PSR TRANSFER
  elif m.name in ["MRS", "MSR"]:
    # MRS
    if m.name == "MRS":
      i = 0 # srouce op type
      p = o.regs[1] # destination psr
      return f"{m.cond}00{i}10{p}001111{str(0)*16}"
    # MSR
    else:
      # source op is imm
      if o.imm and not o.shift:
        i = 1
        sourceoperand = o.bit32imm()
      # source op is reg
      else:
        i = 0
        sourceoperand = "0" * 8 + o.regs[1]
      n = 0 if "_" in o.extra else 1 # 0 if flag present
      p = o.regs[0]
      return f"{m.cond}00{i}10{p}10100{n}1111{sourceoperand}"
  # MULTIPLY AND MULTIPLY-ACCUMULATE
  elif m.name in ["MUL", "MLA"]:
    a, rn = (1, o.regs[3]) if m.name == "MLA" else (0, "0000")
    s = 1 if m.extra == "S" else 0
    return f"{m.cond}000000{a}{s}{o.regs[0]}{rn}{o.regs[2]}1001{o.regs[1]}"
  # MULTIPLY LONG AND MULTIPLY-ACCUMULATE LONG
  elif m.name in ["UMULL", "UMLAL", "SMULL", "SMLAL"]:
    u = 1 if m.name[0] == "S" else 0
    a = 1 if m.name[1:] == "MLAL" else 0
    s = 1 if m.extra == "S" else 0
    return f"{m.cond}00001{u}{a}{s}{o.regs[1]}{o.regs[0]}{o.regs[3]}1001{o.regs[2]}"
  # SINGLE DATA TRANSFER (HALFWORD AND SIGNED DATA TRANSFER)
  elif m.name in ["LDR", "STR"]:
    # 01
    const = "01"
    # post / pre index
    p = 0 if o.addressing() else 1
    # down / up bit
    u = 0 if "-" in o.extra else 1
    # byte / word bit
    b = 1 if "B" in m.extra else 0
    #  no / write back
    w = 1 if "!" == o.extra[-1] else 0
    # load / store
    l = 1 if m.name == "LDR" else 0
    # imm / reg offset
    i = 0 if o.imm and not o.shift else 1
    offset = o.mode2()
    # HALFWORD AND SIGNED
    if m.extra in ["H", "SH", "SB"]:
      const = "00"
      i = 0
      # 1 if expression or rm
      b = 1 if o.imm or len(o.regs) < 3 else 0
      # 0 if not expression or rm
      p = 1 if o.opnum() < 3 else p
      # S,H
      s = 1 if "S" in m.extra else 0
      h = 1 if "H" in m.extra else 0
      offset = o.mode3(s, h)
    return f"{m.cond}{const}{i}{p}{u}{b}{w}{l}{o.regs[1]}{o.regs[0]}{offset}"
  # BLOCK DATA TRANSFER
  elif m.name in ["LDM", "STM"]:
    # do not / load psr
    s = 1 if "^" == o.extra[-1] else 0
    # no / write back
    w = 1 if "!" == o.extra[0] else 0
    # load / store
    if m.name == "LDM":
      l = 1
      # post / pre index
      p = 1 if m.extra in ["EA", "ED", "IB", "DB"] else 0 #str [F,B]
      # down / up bit
      u = 1 if m.extra in ["ED", "FD", "IB", "IA"] else 0 #str [A,B]
    else: 
      l = 0
      p = 1 if m.extra in ["FA", "FD", "IB", "DB"] else 0 #str [F,B]
      u = 1 if m.extra in ["EA", "FA", "IB", "IA"] else 0 #str [A,B]
    return f"{m.cond}100{p}{u}{s}{w}{l}{o.regs[0]}{o.reglist()}"
  # SINGLE DATA SWAP
  elif m.name == "SWP":
    b = 1 if m.extra == "B" else 0
    return f"{m.cond}00010{b}00{o.regs[2]}{o.regs[0]}00001001{o.regs[1]}"
  # SOFTWARE INTERRUPT
  elif m.name == "SWI":
    # dont konw if the comment field is important 
    return f"{m.cond}1111{str(0)*24}"
  # UNDEFINED 
  else:
    return f"{m.cond}011{str(0)*20}10000"

if __name__ == "__main__":
  print("assembling...")
  for line in f:
    if "@" in line: # comments
      line = line[:line.index("@")]
    if line.strip() == "" or line[0] in [".", "_"]: # comment line or directive
      continue
    else:
      #try:
        #print("%08x\n" % int(advance(*line.upper().strip().split(" ", 1)), 2))
      out.write("%08x\n" % int(advance(*line.upper().strip().split(" ", 1)), 2))
      #except:
        #print("---- not valid hexa")
        #out.write("x"*8+"\n")