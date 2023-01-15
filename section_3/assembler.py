#!/usr/bin/env python3

# two pass
# case insensitive
# rv32i base instruction set + pseudo instructions + (some) privileged instrucitons

# todo:
# local references


assout = open("assout.txt", "w")
comp = []
with open("ass-test/mtest/simple.txt", "r") as f:
  for line in f:
    comp.append(line.strip())

TP = 0
OP = 1
F3 = 2
F7 = 3

RTYPE = 0
ITYPE = 1
STYPE = 2
BTYPE = 3
UTYPE = 4
JTYPE = 5

# fix values
symboltable = { # [type, opcode, funct3, funct7]
  # r-type
  "slli"   : [RTYPE, "0010011", "001", "0000000"],
  "srli"   : [RTYPE, "0010011", "101", "0000000"],
  "srai"   : [RTYPE, "0010011", "101", "0100000"],
  "add"    : [RTYPE, "0110011", "000", "0000000"],
  "sub"    : [RTYPE, "0110011", "000", "0100000"],
  "sll"    : [RTYPE, "0110011", "001", "0000000"],
  "slt"    : [RTYPE, "0110011", "010", "0000000"],
  "sltu"   : [RTYPE, "0110011", "011", "0000000"],
  "xor"    : [RTYPE, "0110011", "100", "0000000"],
  "srl"    : [RTYPE, "0110011", "101", "0000000"],
  "sra"    : [RTYPE, "0110011", "101", "0100000"],
  "or"     : [RTYPE, "0110011", "110", "0000000"],
  "and"    : [RTYPE, "0110011", "111", "0000000"],
  # i-type
  "lb"     : [ITYPE, "0000011", "000", None],
  "lh"     : [ITYPE, "0000011", "001", None],
  "lw"     : [ITYPE, "0000011", "010", None],
  "lbu"    : [ITYPE, "0000011", "100", None],
  "lhu"    : [ITYPE, "0000011", "101", None],
  "addi"   : [ITYPE, "0010011", "000", None],
  "slti"   : [ITYPE, "0010011", "010", None],
  "sltiu"  : [ITYPE, "0010011", "011", None],
  "xori"   : [ITYPE, "0010011", "100", None],
  "ori"    : [ITYPE, "0010011", "110", None],
  "andi"   : [ITYPE, "0010011", "111", None],
  "jalr"   : [ITYPE, "1100111", "000", None],
  # s-type
  "sb"     : [STYPE, "0100011", "000", None],
  "sh"     : [STYPE, "0100011", "001", None],
  "sw"     : [STYPE, "0100011", "010", None],
  # b-type
  "beq"    : [BTYPE, "1100011", "000", None],
  "bne"    : [BTYPE, "1100011", "001", None],
  "blt"    : [BTYPE, "1100011", "100", None],
  "bge"    : [BTYPE, "1100011", "101", None],
  "bltu"   : [BTYPE, "1100011", "110", None],
  "bgeu"   : [BTYPE, "1100011", "111", None],
  # u-type
  "lui"    : [UTYPE, "0110111", None, None],
  "auipc"  : [UTYPE, "0010111", None, None],
  # j-type
  "jal"    : [JTYPE, "1101111", None, None],
  # other (i-type i guess)
  "fence"  : [None, "0001111", "000", None],
  "fence.i": [None, "0001111", "001", None],
  "ecall"  : [None, "1110011", "000", None],
  "ebreak" : [None, "1110011", "000", None],
  "csrrw"  : [None, "1110011", "001", None],
  "csrrs"  : [None, "1110011", "010", None],
  "csrrc"  : [None, "1110011", "011", None],
  "csrrwi" : [None, "1110011", "101", None],
  "csrrsi" : [None, "1110011", "110", None],
  "csrrci" : [None, "1110011", "111", None],

  # privileged (r-type i guess)
  "sret"  : [None, "0001000", "000", "1110011"],
  "mret"  : [None, "0011000", "000", "1110011"]
}

# machine instruction registers
miregs = {
  "mcause" : bin(0x342),
  "mhartid" : bin(0xf13),
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


# variable values (with abi names)
regs =  {f"x{i}": f"{i:05b}" for i in range(32)} | \
        {f"{val}": f"{i:05b}" for i, val in enumerate(["zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1"] + \
          [f"a{x-10}" for x in range(10,18)] + [f"s{x-16}" for x in range(18,28)] + ["t3", "t4", "t5", "t6"])} | \
        {"fp": f"{8:05b}"}
labels = {}
insnum = 0

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
  if m == "nop":
    return ["addi", "x0", "x0", "0"]
  elif m == "li":
    return ["addi", p[1], p[1], p[2]]

  elif m == "beqz":
    return ["beq", p[1], "x0", p[2]]
  elif m == "bnez":
    return ["bne", p[1], "x0", p[2]]
  elif m == "blez":
    return ["bge", "x0", p[1], p[2]]
  elif m == "bgez":
    return ["bge", p[1], "x0", p[2]]
  elif m == "bltz":
    return ["blt", p[1], "x0", p[2]]
  elif m == "bgtz":
    return ["blt", "x0", p[1], p[2]]

  elif m == "j":
    return ["jal", "x0", p[1]]
  elif m == "jr":
    return ["jalr", "x0", p[1], "0"]
  

  elif m == "csrr":
    return ["csrrs", p[1], p[2], "x0"]
  elif m == "csrw":
    return ["csrrw", "x0", p[1], p[2]]
  elif m == "csrwi":
    return ["csrrwi", "x0", p[1], p[2]]


  elif m == "unimp": # trap
    return ["csrrw", "x0", "cycle", "x0"]



  else:
    print(p, "not defined")
    exit()

# 110000000000 00000 001 00000 1110011




  #elif m == "mv":
  #  return ["addi", p[1], p[2], "0"]
  #elif m == "not":
  #  return ["xori", p[1], p[2], "-1"] # todo try no string
  #elif m == "neg":
  #  return ["sub", p[1], "x0", p[2]]
  #elif m == "negw":
  #  return ["subw", p[1], "x0", p[2]]
  #elif m == "sext.w":
  #  return ["addiw", p[1], p[2], "0"]
  #elif m == "seqz":
  #  return ["sltiu", p[1], p[2], "1"]
  #elif m == "snez":
  #  return ["sltu", p[1], "x0", p[2]]
  #elif m == "sltz":
  #  return ["slt", p[1], p[2], "x0"]
  #elif m == "sgtz":
  #  return ["slt", p[1], "x0", p[2]]



# **** FIRST PASS ****
tokens = []
def tokenize(ins):
  global insnum
  print([ins], "----------")
  # comment delete
  if "#" in ins:
    ins = ins[:ins.index("#")]
    print("comment", ins)

  # empty line
  if ins == "":
    print("empty")
  # directive
  elif ins[0] == ".":
    print("directive: ", ins)
  # label
  elif ins[-1] == ":":
    print("label:", ins[:-1])
    labels[ins[:-1]] = insnum
  # instruction
  else:
    if len(ins.split(None, 1)) > 1: # one or more arguments
      spl = ins.lower().split(None, 1)
      mnemonic = [spl[0]]
      operands = [x.strip() for x in spl[1].split(",")]
      tok = mnemonic + operands
      insnum += 1
    else:
      tok = [ins]
    # pseudo
    if tok[0] not in symboltable:
      tok = pseudo(tok)
    tokens.append(tok)
    print("added to tokens")

with open("ass-test/atest/simple.s", "r") as f:
  for line in f:
    tokenize(line.strip())

print("tokens:", tokens)
print("labels:", labels)
print()
print()

# **** SECOND PASS ****
res = ""
for i, t in enumerate(tokens):
  st = symboltable[t[0]]
  if st[TP] == RTYPE:
    # funct7, rs2, rs1, funct3, rd, opcode
    if t[0] in ["slli", "srli", "srai"]:
      res = st[F7] + imm(t[3], 5) + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
    else:
      res = st[F7] + regs[t[3]] + regs[t[2]] + st[F3] + regs[t[1]] + st[OP]
  elif st[TP] == ITYPE:
    # imm12, rs1, funct3, rd, opcode
    if "(" in t[-1]: 
      imm12, rs1 = bracket(t[2])
      res = imm12 + regs[rs1] + st[F3] + regs[t[1]] + st[OP]
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
      res = imm20[0] + imm20[9:20] + imm20[9] + imm20[1:9]+ regs[t[1]] + st[OP]
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
      res = miregs[t[2]] + imm(t[3]) + st[F3] + regs[t[1]] + st[OP]


  # compare
  joint = " ".join(t)
  print(f"{i:<3}: {joint:<30}", end = "")
  if f"{int(res, 2):08x}" == comp[i]: # correct
    print("done")
  else: # incorrect
    print(f"{int(res, 2):08x} -> {comp[i]}")
  assout.write(f"{int(res, 2):08x}\n")

assout.close()


# 0000000 00001 00000 100 01000 1100011 / 4 label two lines below (1 between)
# 0000000 00001 00000 100 00100 1100011 / 2 label one line below (0 between)
# 0000000 00001 00000 100 00000 1100011 / 0 its the line
# 1111111 00001 00000 100 11101 1100011 / 4094 label one line above (1 between)
# 1111111 00001 00000 100 11001 1100011 / 4092 label two lines above (2 between)
# 1111111 00001 00000 100 10101 1100011 / 4090


