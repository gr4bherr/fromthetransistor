#!/usr/bin/env python3
from enum import Enum
from capstone import *

conditions = {
  "EQ" : "0000",
  "NE" : "0001",
  "CS" : "0010",
  "CC" : "0011",
  "MI" : "0100",
  "PL" : "0101",
  "VS" : "0110",
  "VC" : "0111",
  "HI" : "1000",
  "LS" : "1001",
  "GE" : "1010",
  "LT" : "1011",
  "GT" : "1100",
  "LE" : "1101",
  "AL" : "1110"
}
opcodes = {
  # multiply long
  "UMULL": "2",
  "UMLAL": "2",
  "SMULL": "2",
  "SMLAL": "2",
  # data processing
  ## double operand instructions
  "AND"  : "0000",
  "EOR"  : "0001",
  "SUB"  : "0010",
  "RSB"  : "0011",
  "ADD"  : "0100",
  "ADC"  : "0101",
  "SBC"  : "0110",
  "RSC"  : "0111",
  "ORR"  : "1100",
  "BIC"  : "1110",
  ## instructions which do not produce a result (flag setting instructins)
  "TST"  : "1000",
  "TEQ"  : "1001",
  "CMP"  : "1010",
  "CMN"  : "1011",
  ## single operand instructions
  "MOV"  : "1101",
  "MVN"  : "1111",
  # psr transfer
  "MRS"  : "0",
  "MSR"  : "0",
  # multiply
  "MUL"  : "1",
  "MLA"  : "1",
  # single data swap
  "SWP"  : "3",
  # single data trasfer (halfword data transfer)
  "LDR"  : "7",
  "STR"  : "7",
  # block data transfer
  "LDM"  : "9",
  "STM"  : "9",
  # coprocessor data transfer
  "LDC"  : "11",
  "STC"  : "11",
  # coprocessor data operation
  "CDP"  : "12",
  # coprocessor register transfer
  "MRC"  : "13",
  "MCR"  : "13",
  # software interrupt
  "SWI"  : "14",
  # branch and exchange
  "BX"   : "4",
  # branch
  "BL"   : "10",
  "B"    : "10"
}
directives = {
  "arm":"0",
  "code32":"0",
  "thumb":"1",
  "thumb":"1"
}
registers = {
  # general registers and program counter
  "R0":"0000",
  "R1":"0001",
  "R2":"0010",
  "R3":"0011",
  "R4":"0100",
  "R5":"0101",
  "R6":"0110",
  "R7":"0111",
  "R8":"1000",
  "R9":"1001",
  "R10":"1010",
  "R11":"1011",
  "R12":"1100",
  ## stack pointer
  "R13":"1101",
  "SP":"1101",
  ## link register
  "R14":"1110",
  "LR":"1110",
  ## program counter
  "PC":"1111",
  "R15":"1111",
  # program status registers
  "CPSR":"0",
  "SPSR":"1"
}
shiftname = {
  "LSL":"00",
  "ASL":"00",
  "LSR":"01",
  "ASR":"10",
  "ROR":"11",
  "RRX":"11" #todo
}

f = open("instruction.s","r")

thumb = False  #thumb / arm
bigendian = False # big endian / litte endian
# TODO:
# arm or gnu assembly?
# code types (directives, etc.)
# comments
# set flags
# registers as class?
# work in hexa?

class Mnemonic:
  def __init__(self,instr):
    # mnemonic = opcodes[code] + {cond} + {extra}
    for item in opcodes:
      self.name = item
      if item in instr:
        self.code = opcodes[item]
        self.extra = instr[len(item):]
        if self.extra[:2] in conditions:
          self.cond = conditions[self.extra[:2]]
          self.extra = self.extra[2:]
        else:
          self.cond = "1110"
        break

class Operands:
  def __init__(self,instr):
    self.name = [x.strip() for x in instr.split(",")]
    self.value = []
    self.type = []
    self.extra = []
    for i,item in enumerate(self.name):
      shift = False
      # shift
      if item[:3] in shiftname:
        shift = True
      # extra
      if item[-1] in ["!","^"]:
        self.extra.append(item[-1])
        item = item[:-1]
      elif "_" in item:
        self.extra.append(item[item.index("_")+1:])
        item = item[:item.index("_")]
      else:
        self.extra.append("")
      self.name[i] = item
      ## immediate value
      if "#" in item or item[:3] == "RRX":
        self.type.append("Imm")
        if shift:
          if item[:3] == "RRX":
            shiftamount = "00000"
          else:
            shiftamount = Immediate(item, 5)
          self.value.append(shiftamount+shiftname[item[:3]]+"0")
        else:
          self.value.append(Immediate(item, 8, True))
      ## register
      else:
        self.type.append("Reg")
        if shift:
          self.value.append(registers[item[4:]]+"0"+shiftname[item[:3]]+"1")
        else:
          self.value.append(registers[item[0:]])

      if shift:
        self.type[-1] += "Shift"
        

def Immediate(val,size,rotate=False):
  val = val[val.index("#")+1:]
  # hex
  if len(val) > 2 and val[1] == "X":
    val = str(int(val[2:],16))
  num = bin(int(val))[2:].zfill(size)
  # rotate
  if rotate:
    if len(num) > size:
      a = num.index("1")
      b = max(i for i, val in enumerate(num) if val == "1") + 1
      if b % 2 != 0:
        b += 1
      num = str(bin(b//2)[2:]).zfill(4) + num[a:b].zfill(8)
    else:
      num = "0000" + num
  return num


def advance(mnemonic,operands):
  print(mnemonic,operands)
  m = Mnemonic(mnemonic)
  print([m.name,m.code,m.cond,m.extra])
  o = Operands(operands)
  print([o.name,o.value,o.type,o.extra])
  
  # data processing
  if len(m.code) == 4:
    # MOV, MVN
    if m.name in ["MOV","MVN"]:
      rn = "0000"
      rd = o.value[0]
      rm = o.value[1]
    # CMP, CMN, TEQ, TST
    elif m.name in ["CMP","CMN","TEQ","TST"]:
      rn = o.value[0]
      rd = "0000"
      rm = o.value[1]
    # AND,EOR, SUB, RSB, ADD,ADC, SBC, RSC, ORR, BIC
    else:
      rn = o.value[1]
      rd = o.value[0]
      rm = o.value[2]
    #i = "1" if o.type[-1] == "Imm" else "0"
    s = "1" if m.extra == "S" else "0"
    # operand 2 is imm / reg
    if o.type[-1] == "Imm":
      i = "1"
      operand2 = o.value[-1]
    else:
      i = "0"
      if "Shift" in o.type[-1]:
        operand2 = o.value[-1] + rm
      else:
        operand2 = "0"*8 + rm
    result = m.cond+"00"+i+m.code+s+rn+rd+operand2 

  # psr transfer
  elif m.code == "0":
    # MRS
    if m.name == "MRS":
      i = "0" # srouce op type
      p = o.value[1] # destination psr
      result = m.cond+"00"+i+"10"+p+"001111"+"0"*16
    # MSR
    else:
      # source op is imm
      if o.type[1] == "Imm":
        i = "1"
        sourceoperand = o.value[1]
      # source op is reg
      else:
        i = "0"
        sourceoperand = "0"*8+o.value[1]
      n = "1" if o.extra[0] == "" else "0" # 0 if flag present
      p = o.value[0]
      result = m.cond+"00"+i+"10"+p+"10100"+n+"1111"+sourceoperand
  # multiply
  elif m.code == "1":
    result = m.code
  # multiply long
  elif m.code == "2":
    result = m.code
  # single data swap
  elif m.code == "3":
    result = m.code
  # branch and exchange
  elif m.code == "4":
    result = m.code
  # single data transfer (halfword data transfer)
  elif m.code == "7":
    result = m.code
  # block data transfer
  elif m.code == "9":
    result = m.code
  # branch
  elif m.code == "10":
    result = m.code
  # coprocesssor data transfer
  elif m.code == "11":
    result = m.code
  # coprocessor data operation
  elif m.code == "12":
    result = m.code
  # coprocessor register transfer
  elif m.code == "13":
    result = m.code
  # software interrupt
  elif m.code == "14":
    result = m.code



  print("result:",end=" ") 
  for i in range(0,len(result),4):
    print(result[i:i+4],end=" ")
  try:
    print("---- %08x" % int(result, 2))
  except:
    print("---- not valid hexa")
  print()

if __name__ == "__main__":
  for line in f:
    if "@" in line: # comments
      line = line[:line.index("@")]
    if line.strip() == "" or line[0] in [".","_"]: # comment line or directive
      continue
    else:
      advance(*line.upper().strip().split(" ",1))
