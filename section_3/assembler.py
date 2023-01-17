#!/usr/bin/env python3

import glob
import struct

# two pass
# case insensitive
# rv32i base instruction set + (some) pseudo instructions + (some) privileged instrucitons

# **** CONSTANTS ****
TP = 0
OP = 1
F3 = 2
RTYPE = 0
ITYPE = 1
STYPE = 2
BTYPE = 3
UTYPE = 4
JTYPE = 5

symboltable = { # [type, opcode, funct3]
  # r-type
  "add"    : [RTYPE, "0110011", "000"],
  "sub"    : [RTYPE, "0110011", "000"],
  "sll"    : [RTYPE, "0110011", "001"],
  "slt"    : [RTYPE, "0110011", "010"],
  "sltu"   : [RTYPE, "0110011", "011"],
  "xor"    : [RTYPE, "0110011", "100"],
  "srl"    : [RTYPE, "0110011", "101"],
  "sra"    : [RTYPE, "0110011", "101"],
  "or"     : [RTYPE, "0110011", "110"],
  "and"    : [RTYPE, "0110011", "111"],
  # i-type
  "lb"     : [ITYPE, "0000011", "000"],
  "lh"     : [ITYPE, "0000011", "001"],
  "lw"     : [ITYPE, "0000011", "010"],
  "lbu"    : [ITYPE, "0000011", "100"],
  "lhu"    : [ITYPE, "0000011", "101"],
  "addi"   : [ITYPE, "0010011", "000"],
  "slti"   : [ITYPE, "0010011", "010"],
  "sltiu"  : [ITYPE, "0010011", "011"],
  "xori"   : [ITYPE, "0010011", "100"],
  "ori"    : [ITYPE, "0010011", "110"],
  "andi"   : [ITYPE, "0010011", "111"],
  "slli"   : [ITYPE, "0010011", "001"],
  "srli"   : [ITYPE, "0010011", "101"],
  "srai"   : [ITYPE, "0010011", "101"],
  "jalr"   : [ITYPE, "1100111", "000"],
  # s-type
  "sb"     : [STYPE, "0100011", "000"],
  "sh"     : [STYPE, "0100011", "001"],
  "sw"     : [STYPE, "0100011", "010"],
  # b-type
  "beq"    : [BTYPE, "1100011", "000"],
  "bne"    : [BTYPE, "1100011", "001"],
  "blt"    : [BTYPE, "1100011", "100"],
  "bge"    : [BTYPE, "1100011", "101"],
  "bltu"   : [BTYPE, "1100011", "110"],
  "bgeu"   : [BTYPE, "1100011", "111"],
  # u-type
  "lui"    : [UTYPE, "0110111", None],
  "auipc"  : [UTYPE, "0010111", None],
  # j-type
  "jal"    : [JTYPE, "1101111", None],
  # other (i-type i guess)
  "fence"  : [None, "0001111", "000"],
  "fence.i": [None, "0001111", "001"],
  "ecall"  : [None, "1110011", "000"],
  "ebreak" : [None, "1110011", "000"],
  "csrrw"  : [None, "1110011", "001"],
  "csrrs"  : [None, "1110011", "010"],
  "csrrc"  : [None, "1110011", "011"],
  "csrrwi" : [None, "1110011", "101"],
  "csrrsi" : [None, "1110011", "110"],
  "csrrci" : [None, "1110011", "111"],
  # privileged (r-type i guess)
  #"sret"  : [None, "1110011", "000", "0001000"],
  "mret"  : [None, "1110011", "000"]
}

# machine instruction registers
miregs = {
  "mcause" : bin(0x342),
  "mhartid" : bin(0xf14),
  "mtvec" : bin(0x305),
  "satp" : bin(0x180),
  "pmpaddr0" : bin(0x3b0),
  "pmpcfg0" : bin(0x3a0),
  "mie" : bin(0x304),
  "medeleg" : bin(0x302),
  "mideleg" : bin(0x303),
  "stvec" : bin(0x105),
  "mstatus" : bin(0x300),
  "mepc" : bin(0x341),
  "cycle" : bin(0xc00)
}

# register values (with abi names)
regs =  {f"x{i}": f"{i:05b}" for i in range(32)} | \
        {f"{val}": f"{i:05b}" for i, val in enumerate(["zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1"] + \
          [f"a{x-10}" for x in range(10,18)] + [f"s{x-16}" for x in range(18,28)] + ["t3", "t4", "t5", "t6"])} | \
        {"fp": f"{8:05b}"}
labels = {}

# **** HELPER FUNCTIONS ****
def imm(val, size = 12):
  if isinstance(val, str):
    if "x" in val:
      val = int(val, 16)
    else:
      val = int(val)
  # twos comp
  if val < 0:
    val = ((val * -1) ^ (2 ** size - 1)) + 1
  return f"{val:0{size}b}"

def bracket(val):
  imm12 = imm(val[:val.index("(")])
  reg = val[val.index("(")+1:val.index(")")]
  return imm12, reg

def pseudo(p):
  m = p[0]
  if m == "nop": return ["addi", "x0", "x0", "0"]
  elif m == "li": return ["addi", p[1], "x0", p[2]]
  elif m == "mv": return ["addi", p[1], p[2], "0"]
  elif m == "not": return ["xori", p[1], p[2], -1]
  elif m == "neg": return ["sub", p[1], "x0", p[2]]
  elif m == "negw": return ["subw", p[1], "x0", p[2]]
  elif m == "sext.w": return ["addiw", p[1], p[2], "0"]
  elif m == "seqz": return ["sltiu", p[1], p[2], "1"]
  elif m == "snez": return ["sltu", p[1], "x0", p[2]]
  elif m == "sgtz": return ["slt", p[1], "x0", p[2]]
  elif m == "sltz": return ["slt", p[1], p[2], "x0"]
  elif m == "beqz": return ["beq", p[1], "x0", p[2]]
  elif m == "bnez": return ["bne", p[1], "x0", p[2]]
  elif m == "blez": return ["bge", "x0", p[1], p[2]]
  elif m == "bgez": return ["bge", p[1], "x0", p[2]]
  elif m == "bltz": return ["blt", p[1], "x0", p[2]]
  elif m == "bgtz": return ["blt", "x0", p[1], p[2]]
  elif m == "j": return ["jal", "x0", p[1]]
  elif m == "jr": return ["jalr", "x0", p[1]]
  elif m == "csrr": return ["csrrs", p[1], p[2], "x0"]
  elif m == "csrw": return ["csrrw", "x0", p[1], p[2]]
  elif m == "csrwi": return ["csrrwi", "x0", p[1], p[2]]
  elif m == "unimp": return ["csrrw", "x0", "cycle", "x0"] # trap
  else:
    print(p, "not defined")
    exit()


# **** FIRST PASS ****
def tokenize(name):
  with open(f"mytests/{name}.s", "r") as f:
    res = []
    insnum = 0
    for line in f:
      ins = line.strip()
      # comment delete
      if "#" in ins:
        ins = ins[:ins.index("#")]
      # empty line, directive
      if ins == "" or ins[0] == ".":
        None # todo
      # label
      elif ins[-1] == ":":
        labels[ins[:-1]] = insnum
      # instruction
      else:
        if len(ins.split(None, 1)) > 1: # one or more operands
          spl = ins.lower().split(None, 1)
          mnemonic = [spl[0]]
          operands = [x.strip() for x in spl[1].split(",")]
          tok = mnemonic + operands
        else:
          tok = [ins]
        # pseudo
        if tok[0] not in symboltable:
          tok = pseudo(tok)
        res.append(tok)
        insnum += 1
  return res

# **** SECOND PASS ****
def assemble(tok):
  res = ""
  out = []
  for i, t in enumerate(tok):
    st = symboltable[t[0]]
    if st[TP] == RTYPE:
      # funct7, rs2, rs1, funct3, rd, opcode
      funct7 = "0100000" if t[0] in ["sub", "sra"] else "0000000"
      if t[0] in ["slli", "srli", "srai"]:
        res = funct7 + imm(t[3], 5) + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
      else:
        res = funct7 + regs[t[3]] + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
    elif st[TP] == ITYPE:
      # imm12, rs1, funct3, rd, opcode
      if "(" in t[-1]: 
        imm12, rs1 = bracket(t[2])
        res = imm12 + regs[rs1] + st[F3] + regs[t[1]] + st[OP]
      else:
        if t[0] == "jalr" and len(t) == 3: # jalr with only two operands
          res = imm(0, 12) + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
        elif t[0] in ["slli", "srli", "srai"]:
          funct7 = "0100000" if t[0] == "srai" else "0000000"
          res = funct7 + imm(t[3], 5) + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
        else: 
          res = imm(t[3], 12) + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
    elif st[TP] == STYPE or st[TP] == BTYPE:
      # imm7, rs2, rs1, funct3, imm5, opcode
      if "(" in t[-1]: # S
        imm12, rs1 = bracket(t[2])
        res = imm12[:7] + regs[t[1]] + regs[rs1] + st[F3] + imm12[7:] + st[OP]
      else: # B
        if t[3] in labels: # label
          imm12 = imm((labels[t[3]] - i) * 2)
        else: # number
          imm12 = imm(t[3])
        res = imm12[0] + imm12[2:8] + regs[t[2]] + regs[t[1]] + st[F3] + imm12[8:12] + imm12[1] + st[OP]
    elif st[TP] == UTYPE or st[TP] == JTYPE:
      # imm20, rd, opcode
      if t[2] in labels:
        imm20 = imm((labels[t[2]] - i) * 2, 20)
      else:
        imm20 = imm(t[2], 20)
      if t[0] == "jal": # J
        res = imm20[0] + imm20[10:20] + imm20[9] + imm20[1:9]+ regs[t[1]] + st[OP]
      else: # U
        res = imm20 + regs[t[1]] + st[OP]
    else:
      if t[0] == "fence":
        # pred, suc, funct3, opcode
        if len(t) == 1: # todo: technically a pseudo instruction 
          res = f"00001111111100000{st[F3]}00000{st[OP]}"
        else:
          res = f"0000{t[1]}{t[2]}00000{st[F3]}00000{st[OP]}"
      elif t[0] == "fence.i":
        # funct3, opcode
        res = f"00000000000000000{st[F3]}00000{st[OP]}"
      elif t[0] == "ecall":
        # funct3, opcode
        res = f"00000000000000000{st[F3]}00000{st[OP]}"
      elif t[0] == "ebreak":
        # funct3, opcode
        res = f"00000000000000000{st[f3]}00000{st[OP]}"
      elif t[0] in ["csrrw", "csrrs", "csrrc"]:
        # csr, rs1, funct3, rd, opcode
        res = miregs[t[2]] + regs[t[3]] + st[F3] + regs[t[1]] + st[OP]
      elif t[0] in ["csrrwi", "csrrsi", "csrrci"]:
        # csr, zimm, funct3, rd, opcode
        res = miregs[t[2]] + imm(t[3], 5) + st[F3] + regs[t[1]] + st[OP]
      elif t[0] == "mret":
        res = f"00110000001000000{st[F3]}00000{st[OP]}"

    # ** COMPARE **
    joint = " ".join(t)
    #print(f"{i:<3}: {joint:<30}", end = "")
    if f"{int(res, 2):08x}" == comp[i]: # correct
      #print(f"done \t({int(res, 2):08x})")
      None
    else: # incorrect
      print(f"{int(res, 2):08x} -> {comp[i]}")
      exit()
    out.append(int(res, 2))
  return out


# **** MAIN ****
if __name__ == "__main__":
  for test in sorted(glob.glob("mytests/*.s")):
    name = test[8:-2]
    print(f"{name}...")

    # compare to test
    comp = []
    with open(f"mytests/{name}-cmp.txt", "r") as f:
      for line in f:
        comp.append(line.strip())

    # first pass
    tokens = tokenize(name)

    # second pass
    result = assemble(tokens)

    print(name, "passed")

    # write output
    # hex
    with open(f"mytests/{name}-res.txt", "w") as f: 
      for line in result:
        f.write(f"{line:08x}\n")
    # bin
    with open(f"mytests/{name}-res.bin", "wb") as f: 
      # little endian unsigned int
      f.write(struct.pack(f"<{len(result)}I", *result))
