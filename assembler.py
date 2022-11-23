#!/usr/bin/env python3
import re

# assembler for ARM7TDMI
# no wrong input checking 
# no coprocessor
# no thumb mode
# TODO:
# code types (directives, etc.)
# registers as class?
# work in hexa?

f = open("assembly.s", "r")
out = open("assout.txt", "w")

condnames = ["EQ", "NE", "CS", "CC", "MI", "PL", "VS", "VC", "HI", "LS", "GE", "LT", "GT", "LE", "AL"]
conditions = {f"{val}": f"{i:04b}" for i, val in enumerate(condnames)}

mlist  = [
  "UMULL", "UMLAL", "SMULL", "SMLAL",
  "LDR", "STR",
  "MRS", "MSR",
  "MUL", "MLA",
  "SWP",
  "LDM", "STM",
  "SWI",
  "AND", "EOR", "SUB", "RSB",
  "ADD", "ADC", "SBC", "RSC",
  "TST", "TEQ", "CMP", "CMN",
  "ORR", "MOV", "BIC", "MVN",
  "BX",
  "BL", "B"
] 
opcodes = {f"{val}": f"{i:04b}" for i, val in enumerate(mlist[14:30])}

registers = {f"R{i}": f"{i:04b}" for i in range(16)} |\
            {f"C{i}": f"{i:04b}" for i in range(16)} |\
            {f"{val}": f"{i:04b}" for i, val in enumerate(["SP", "LR", "PC"], 13)} |\
            {"CPSR": "0", "SPSR": "1"}

shiftname = {f"{val}": f"{i:02b}" for i, val in enumerate(["LSL", "LSR", "ASR", "ROR"])} |\
            {"ASL": "00", "RRX": "11"}

class Mnemonic:
  def __init__(self,instr):
    for item in mlist:
      self.name = item
      # instr found in mlist
      if item in instr:
        print(item)
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
    self.name = [x.strip() for x in instr.split(",")]
    self.opnum = len(self.name)
    self.value = []
    self.type = []
    self.extra = []
    for i, item in enumerate(self.name):
      shift = False
      # shift
      if item[:3] in shiftname:
        shift = True
      # extra
      self.extra.append("")
      for j in range(len(item) - 1, -1, -1):
        if item[j] in ["!", "^", "[", "]", "+", "-", "{", "}"]:
          # only if "-" not representing range
          if item[j] != "-" or j < 2:
            self.extra[i] = item[j] + self.extra[i]
            item = item[:j] + item[j + 1:]
      ## flag
      if "_" in item:
        self.extra[i] += item[item.index("_") + 1:]
        item = item[:item.index("_")]
      self.name[i] = item
      ## immediate value
      if "#" in item or item[:3] == "RRX":
        self.type.append("Imm")
        if shift:
          if item[:3] == "RRX":
            shiftamount = "00000"
          else:
            shiftamount = Immediate(item, 5)
          self.value.append(f"{shiftamount}{shiftname[item[:3]]}0")
        else:
          self.value.append(Immediate(item, 8, True))
      ## register
      else:
        self.type.append("Reg")
        if shift:
          self.value.append(f"{registers[item[4:]]}0{shiftname[item[:3]]}1")
        else:
          # range of registers
          if "-" in item:
            self.value.append(registers[item[:item.index("-")]] + registers[item[item.index("-") + 1:]])
          elif item in registers:
            self.value.append(registers[item[0:]])
          else:
            self.value.append(item)
      # add shift to type
      if shift:
        self.type[-1] += "Shift"

def Immediate(val, size, rotate = False):
  val = val[val.index("#") + 1:]
  # hex
  if len(val) > 2 and val[1] == "X":
    val = str(int(val[2:], 16))
  num = bin(int(val))[2:].zfill(size)
  # rotate
  if rotate:
    # number needs rotating
    if len(num) > size:
      a = num.index("1")
      b = max(i for i, val in enumerate(num) if val == "1") + 1
      b += 1 if b % 2 != 0 else 0
      num = str(bin(b // 2)[2:]).zfill(4) + num[a:b].zfill(8)
    else:
      num = f"0000{num}"
  return num

def advance(mnemonic,operands):
  #print(mnemonic, operands)
  m = Mnemonic(mnemonic)
  #print([m.name, m.code, m.cond, m.extra])
  o = Operands(operands)
  #print([o.name, o.value, o.type, o.extra])
  
  # data processing
  if m.name in opcodes:
    # MOV, MVN
    if m.name in ["MOV", "MVN"]:
      rn = "0000"
      rd = o.value[0]
      rm = o.value[1]
    # CMP, CMN, TEQ, TST
    elif m.name in ["CMP", "CMN", "TEQ", "TST"]:
      rn = o.value[0]
      rd = "0000"
      rm = o.value[1]
    # AND,EOR, SUB, RSB, ADD,ADC, SBC, RSC, ORR, BIC
    else:
      rn = o.value[1]
      rd = o.value[0]
      rm = o.value[2]
    s = 1 if m.extra == "S" else 0
    # operand 2 is imm / reg
    if o.type[-1] == "Imm":
      i = 1
      operand2 = o.value[-1]
    else:
      i = 0
      if "Shift" in o.type[-1]:
        operand2 = o.value[-1] + rm
      else:
        operand2 = "0" * 8 + rm
    return f"{m.cond}00{i}{m.code}{s}{rn}{rd}{operand2}"
  # psr transfer
  elif m.name in ["MRS", "MSR"]:
    # MRS
    if m.name == "MRS":
      i = 0 # srouce op type
      p = o.value[1] # destination psr
      return f"{m.cond}00{i}10{p}001111{str(0)*16}"
    # MSR
    else:
      # source op is imm
      if o.type[1] == "Imm":
        i = 1
        sourceoperand = o.value[1]
      # source op is reg
      else:
        i = 0
        sourceoperand = "0" * 8 + o.value[1]
      n = 0 if o.extra[0] == "FLG" else 1 # 0 if flag present
      p = o.value[0]
      return f"{m.cond}00{i}10{p}10100{n}1111{sourceoperand}"
  # multiply and multiply-accumulate
  elif m.name in ["MUL", "MLA"]:
    a = 1 if m.name == "MLA" else 0
    s = 1 if m.extra == "S" else 0
    rn = o.value[3] if m.name == "MLA" else "0000"
    return f"{m.cond}000000{a}{s}{o.value[0]}{rn}{o.value[2]}1001{o.value[1]}"
  # multiply long and multiply-accumulate long
  elif m.name in ["UMULL", "UMLAL", "SMULL", "SMLAL"]:
    u = 1 if m.name[0] == "S" else 0
    a = 1 if m.name[1:] == "MLAL" else 0
    s = 1 if m.extra == "S" else 0
    return f"{m.cond}00001{u}{a}{s}{o.value[1]}{o.value[0]}{o.value[3]}1001{o.value[2]}"
  # single data swap
  elif m.name == "SWP":
    b = 1 if m.extra == "B" else 0
    rn = "0000" if o.opnum < 3 else o.value[2]
    rd = o.value[0]
    rm = o.value[1]
    return f"{m.cond}00010{b}00{rn}{rd}00001001{rm}"
  # branch and exchange
  elif m.name == "BX":
    rm = o.value[0]
    return f"{m.cond}000100101111111111110001{rm}"
  # single data transfer (halfword and signed data transfer)
  elif m.name in ["LDR", "STR"]:
    # 01
    const = "01"
    # post / pre index
    p = 0 if "]" in o.extra[1] else 1
    # down / up bit
    u = 0 if o.opnum > 2 and "-" in o.extra[2] else 1
    # byte / word bit
    b = 1 if "B" in m.extra else 0
    #  no / write back
    w = 1 if "!" in o.extra[-1] else 0
    # load / store
    l = 1 if m.name == "LDR" else 0
    # registers
    rd = o.value[0]
    rn = o.value[1]
    # imm / reg offset
    if o.type[-1] == "Imm":
      i = 0
      offset = o.value[-1]
    else:
      i = 1
      if "Shift" in o.type[-1]:
        rm = o.value[-2]
        offset = o.value[-1] + rm
      else:
        rm = o.value[-1] 
        offset = "0" * 8 + rm
    # halfword and signed
    if m.extra in ["H", "SH", "SB"]:
      const = "00"
      i = 0
      b = 1 if o.opnum < 3 or "#" in o.name[-1] else 0
      p = 1 if o.opnum < 3 else p
      # S,H
      s = 1 if "S" in m.extra else 0
      h = 1 if "H" in m.extra else 0
      # imm / reg offset
      if o.type[-1] == "Imm":
        of1, of2 = o.value[-1][4:8], o.value[-1][8:]
        offset = f"{of1}1{s}{h}1{of2}"
      else:
        rm = o.value[-1]
        offset = f"00001{s}{h}1{rm }"
    return f"{m.cond}{const}{i}{p}{u}{b}{w}{l}{rn}{rd}{offset}"
  # block data transfer
  elif m.name in ["LDM", "STM"]:
    # do not / load psr
    s = 1 if "^" in o.extra[-1] else 0
    # no / write back
    w = 1 if "!" in o.extra[0] else 0
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
    rn = o.value[0]
    # reglist
    reglist = ["0"] * 16
    for i in range(1,o.opnum):
      # range
      if len(o.value[i]) > 4: 
        x = 15-int(o.value[i][:4], 2)
        y = 15-int(o.value[i][4:], 2)
        for j in range(y,x+1):
          reglist[j] = "1"
      # one register
      else:
        reglist[15-int(o.value[i], 2)] = "1"
    reglist = "".join(reglist)
    return f"{m.cond}100{p}{u}{s}{w}{l}{rn}{reglist}"
  # branch and branch with link
  elif m.name in ["B", "BL"]:
    l = 1 if m.name == "BL" else 1
    offset = "0"*24 # todo idk man
    return f"{m.cond}101{l}{offset}"
  # software interrupt
  elif m.name == "SWI":
    # dont konw if the comment field is important 
    return f"{m.cond}1111{str(0)*24}"

if __name__ == "__main__":
  for line in f:
    if "@" in line: # comments
      line = line[:line.index("@")]
    if line.strip() == "" or line[0] in [".", "_"]: # comment line or directive
      out.write("\n")
      continue
    else:
      try:
        #print("%08x\n" % int(advance(*line.upper().strip().split(" ", 1)), 2))
        out.write("%08x\n" % int(advance(*line.upper().strip().split(" ", 1)), 2))
      except:
        #print("---- not valid hexa")
        out.write("x\n"*8)