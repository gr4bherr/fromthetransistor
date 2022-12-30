#!/usr/bin/env python3
import re
import time

# ./assembler.py assin.s && ./cpu.py

infile = open("assout.txt", "r")

#todo: not finshed, got bored

# **** print function **** 
# print register bank content
def regprint():
  print("registers","-"*51)
  for key, val in regs.items():
    if key == 16:
      print(f"CPSR {val:08x}")
    else:
      print(f"R{key:<2}: {val:08x}", end="\t")
    if (key+1) % 4 == 0:
      print()

# **** INIT ****
class Memory:
  def __init__(self, memsize):
    # memsize in bytes
    self.memory = {x:0 for x in range(0, memsize, 1)}

  def print(self):
    print("memory", "-" * 54)
    for key, val in self.memory.items():
      if (key) % 4 == 0: print(f"M{key:<2}: ", end="")
      print(f"{val:02x}", end = "")
      if (key + 1) % 4 == 0: print("\t", end = "")
      if (key + 1) % 16 == 0: print()

  def store(self, val, adr, bytenum = 4):
    val = f"{val:08x}"
    for i in range(bytenum):
      self.memory[adr+i] = int(val[i*2:i*2+2], 16)

  def load(self, adr, bytenum = 4):
    res = ""
    for i in range(bytenum):
      res += f"{self.memory[adr+i]:02x}"
    return int(res, 16)


regs = {x:0 for x in range(17)}
mem = Memory(64)
ins = []
PC = 15
CPSR = 16
# FIQ disable, IRQ disable, T clear, mode: supervisor
regs[CPSR] = 0b111010011 
# pipeline cache
instructions = []
controlsignals= []

# not a valid clock of course (waits on instructions to be done)
def clk():
  time.sleep(0.1) # 10 Hz
  return True
# store instructions into memory at the beginning
def programstore():
  for i, line in enumerate(infile):
    line = int(line.strip(), 16)
    mem.store(line, i * 4)
  
# if val negative -> two's complement
def totwoscomp(val, bits = 32):
  # if val negative
  if (val & (1 << (bits-1))) != 0: val = val - (1 << bits)
  # sign extend
  return val & ((2 ** bits) - 1)

# **** COMPONENTS **** 
def alu(opcode, s, dest, op1, op2):
  if opcode == 0: res = op1 & op2 # AND
  elif opcode == 1: res = op1 ^ op2 # EOR
  elif opcode == 2: res = op1 - op2 # SUB
  elif opcode == 3: res = op2 - op1 # RSB
  elif opcode == 4: res = op1 + op2 # ADD
  elif opcode == 5: res = op1 + op2 + int(f"{regs[CPSR]:032b}"[2]) # ADC
  elif opcode == 6: res = op1 - op2 + int(f"{regs[CPSR]:032b}"[2]) # SBC
  elif opcode == 7: res = op2 - op1 + int(f"{regs[CPSR]:032b}"[2]) # RSC
  elif opcode == 8: res = op1 & op2 # TST
  elif opcode == 9: res = op1 ^ op2 # TEQ
  elif opcode == 10: res = op1 - op2 # CMP
  elif opcode == 11: res = op1 + op2 # CMN
  elif opcode == 12: res = op1 | op2 # ORR
  elif opcode == 13: res = op2 # MOV
  elif opcode == 14: res = op1 & ~op2 # BIC
  elif opcode == 15: res = ~op2 # MVN
  # format
  res = totwoscomp(res)
  bop1 = f"{op1:032b}"
  bop2 = f"{op1:032b}"
  bres = f"{res:032b}"
  # write to reg
  if opcode not in [5, 6, 7, 8]: regs[dest] = res
  # set flags
  if s == 1 and dest != 15:
    # N
    if bres[0] == "1": regs[CPSR] = regs[CPSR] | 0x80000000
    else: regs[CPSR] = regs[CPSR] & 0x7fffffff
    # Z
    if res == 0: regs[CPSR] = regs[CPSR] | 0x40000000
    else: regs[CPSR] = regs[CPSR] & 0xbfffffff
    # C
    # sub
    if opcode in [2, 3 ,6, 7, 10]:
      if op1 < op2: regs[CPSR] = regs[CPSR] & 0xdfffffff
      else: regs[CPSR] = regs[CPSR] | 0x20000000
    # add
    if opcode in [4, 5, 11]:
      # unsigned overflow
      if bop1[0] == "1" and bop2[0] == "1": regs[CPSR] = regs[CPSR] | 0x20000000
      else: regs[CPSR] = regs[CPSR] & 0xdfffffff
    # V
    if opcode in [2,3,4,5,6,7,10]:
      # signed overflow
      if bop1[0] == "0" and bop2[0] == "0" and bres[0] == "1": regs[CPSR] = regs[CPSR] | 0x10000000
      else: regs[CPSR] = regs[CPSR] & 0xefffffff
    
# rotate: False -> shift, rotate: True -> rotate (no rrx) (used for imm num formating)
def barrelshifter(n, shiftam, shift, rotate = False):
  width = 32
  # LSL (ASL)
  if shift == 0:
    if shiftam == 32:
      carry, res = bin(n)[-1], 0
    elif shiftam > 32:
      carry, res = 0, 0
    else:
      tmp = bin(n << shiftam)
      carry = int(tmp[-33]) if len(tmp) - 2 > 32 else 0
      res = n << shiftam & 0xffffffff
  # LSR
  elif shift == 1:
    if shiftam == 32:
      carry, res = bin(n)[2], 0
    elif shiftam > 32:
      carry, res = 0, 0
    else:
      carry, res = int(f"{n:032b}"[-shiftam]), n >> shiftam
  # ASR
  elif shift == 2:
    if shiftam >= 32:
      carry, res = bin(n[2]), n
    else:
      carry = int(f"{n:032b}"[-shiftam])
      num = (f"{n:032b}"[0] * shiftam) + "0" * (width - shiftam)
      res = n >> shiftam | int(num, 2)
  # ROR, RRX
  elif shift == 3:
    carry = int(f"{n:032b}"[-shiftam])
    # rrx
    if shiftam == 0 and not rotate:
      shiftam = 1
      res = n >> shiftam | int(f"{regs[CPSR]:032b}"[2]) << (width - 1)
    # ror
    else:
      if shiftam == 32:
        carry, res = bin(n[2]), n
      else:
        shiftam = shiftam % 32
        res = (n >> shiftam | n << (width - shiftam)) & (2 ** width - 1)
  # don't set flags when doing op2
  if rotate: 
    if carry == 1: regs[CPSR] = regs[CPSR] & 0x20000000
    else: regs[CPSR] = regs[CPSR] ^ 0x20000000
  return res

def conditioncheck(cond):
  n, z, c, v = [int(x) for x in f"{regs[CPSR]:032b}"[:4]]
  if cond == 0 and z: return True # EQ
  elif cond == 1 and not z: return True # NE
  elif cond == 2 and c: return True # CS
  elif cond == 3 and not c: return True # CC
  elif cond == 4 and n: return True # MI
  elif cond == 5 and not n: return True # PL
  elif cond == 6 and v: return True # VS
  elif cond == 7 and not v: return True # VC
  elif cond == 8 and c and not z: return True # HI
  elif cond == 9 and not c and z: return True # LS
  elif cond == 10 and z == v: return True # GE
  elif cond == 11 and z != v: return True # LT
  elif cond == 12 and not z and n == v: return True # GT
  elif cond == 13 and (z or n != v): return True # LE
  elif cond == 14: return True # AL
  else: return False # invalid

# **** PIPELIINE **** 
def decode(ins):
  if conditioncheck(int(ins[:4], 2)): # if condition valid
    if ins[4:6] == "00":
      if ins[6] == "0":
        # DATA PROCESSING: reg {shift} (1/2)
        if not re.match("10..0", ins[7:12]) and (re.match("...0", ins[24:28]) or re.match("0..1", ins[24:28])):
          return {"insnum": 0x0, "i": int(ins[6], 2), "opcode": int(ins[7:11], 2), "s": int(ins[11]), "rn": regs[int(ins[12:16], 2)], "rd": int(ins[16:20], 2), "shiftam": int(ins[20:25], 2), "shift": int(ins[25:27], 2), "t": int(ins[27], 2), "rm": regs[int(ins[28:], 2)]}
        elif re.match("10..0", ins[7:12]) and re.match("0...", ins[24:28]):
          if re.match("0...", ins[24:28]):
            # PSR TRANSFER: mrs reg, msr reg (1/2)
            if ins[25:28] == "000":
              return {"insnum": 0x1, "i": int(ins[6]), "psr": int(ins[9], 2), "direction": int(ins[10], 2), "rd": int(ins[16:20], 2), "rm": regs[int(ins[28:], 2)]}
            elif ins[25:28] == "001":
              # BRANCH AND EXCHANGE
              if ins[9:11] == "01":
                return {"insnum": 0x5, "rn": regs[int(ins[28:], 2)]}
        elif re.match("0....", ins[7:12]) and re.match("1001", ins[24:28]):
          if ins[24:28] == "1001":
            # MULTIPLY
            if re.match("00..", ins[8:12]):
              return {"insnum": 0x2, "a": int(ins[10], 2), "s": int(ins[11], 2), "rd": int(ins[12:16], 2), "rn": regs[int(ins[16:20], 2)], "rs": regs[int(ins[20:24], 2)], "rm": regs[int(ins[28:], 2)]}
            # MULTIPLY LONG
            elif re.match("1...", ins[8:12]):
              return {"insnum": 0x3, "u": int(ins[9], 2), "a": int(ins[10], 2), "s": int(ins[11], 2), "rdhi": int(ins[12:16], 2), "rdlo": int(ins[16:20], 2), "rs": regs[int(ins[20:24], 2)], "rm": regs[int(ins[28:], 2)]}
        # HALF WORD DATA TRANSFER
        elif (not re.match("0..1.", ins[7:12]) or re.match("0xx10", ins[7:12])) and (ins[24:28] in ["1011", "1101", "1111"]):
          # if i == 1 and l == 1 and rn == 1111 -> literal offset
          return {"p": int(ins[7], 2), "u": int(ins[8], 2), "i": int(ins[9], 2), "w": int(ins[10], 2), "l": int(ins[11], 2), "rn": int(ins[12:16], 2), "rd": int(ins[16:20], 2), "off1": ins[20:24], "sh": int(ins[25:27], 2), "off2": ins[28:] if i == 0 else regs[int(ins[28:], 2)], "insnum": 0x6 if i == 0 else 0x7}
        # SINGLE DATA SWAP
        # 1110 00 0 10000 11110000000000000000
        elif re.match("10.00", ins[7:12]) and ins[20:28] == "00001001":
          return {"insnum": 0x4, "b": int(ins[9], 2), "rn": regs[int(ins[12:16], 2)], "rd": regs[int(ins[16:20], 2)], "rm": regs[int(ins[28:], 2)]}
      elif ins[6] == "1":
        # DATA PROCESSING: imm (2/2)
        if not re.match("10..0", ins[7:12]):
          return {"insnum": 0x0, "i": int(ins[6], 2), "opcode": int(ins[7:11], 2), "s": int(ins[11], 2), "rn": regs[int(ins[12:16], 2)], "rd": int(ins[16:20], 2), "rotate": int(ins[20:24], 2) * 2, "imm": int(ins[24:], 2)}
        # PSR TRANSFER: msr imm (2/2)
        elif re.match("10.10", ins[7:12]):
          return {"insnum": 0x1, "i": int(ins[6]), "psr": int(ins[9], 2), "direction": int(ins[10], 2), "rotate": int(ins[20:24], 2), "imm": int(ins[24:], 2)}
    # SINGE DATA TRANSFER
    elif ins[4:6] == "01":
      tmp = {"insnum": 0x8, "i": int(ins[6], 2), "p": int(ins[7], 2), "u": int(ins[8], 2), "b": int(ins[9], 2), "w": int(ins[10], 2), "l": int(ins[11], 2), "rn": int(ins[12:16], 2), "rd": int(ins[16:20], 2)}
      if tmp["i"] == 0: 
        tmp["imm"] = int(ins[20:], 2)
      else:
        tmp["shiftam"] = int(ins[20:25], 2)
        tmp["shift"] = int(ins[25:27], 2)
        tmp["rm"] = regs[int(ins[28:], 2)]
      return tmp
    elif ins[4:6] == "10":
      # BLOCK DATA TRANSFER
      if ins[6] == "0":
        return {"insnum": 0xa, "p": int(ins[7], 2), "u": int(ins[8], 2), "s": int(ins[9], 2), "w": int(ins[10], 2), "l": int(ins[11], 2), "rn": regs[int(ins[12:16], 2)], "reglist": int(ins[16:], 2)}
      # BRANCH
      elif ins[6] == "0":
        return {"insnum": 0xb, "l": int(ins[7], 2), "offset": int(ins[8:], 2)}
    elif ins[4:6] == "11":
      # UNDEFINED
      if re.match("00000.", ins[6:12]):
        return {"insnum": 0x9}
      # SOFTWARE INTERRUPT
      elif re.match("110000", ins[6:12]):
        return {"insnum": 0xf}
      # # COPROCESSOR DATA TRANSFER
      # elif re.match("0....0", ins[6:12]) and not re.match("000.00", ins[6:12]):
      #   print("stc")
      #   return {"insnum": 0xc}
      # elif re.match("0....1", ins[6:12]) and not re.match("000.01", ins[6:12]):
      #   return {"insnum": 0xc}
      #   if ins[11:15] == "1111":
      #     print("ldc (imm)")
      #   else:
      #     print("ldc (literal")
      # # COPROCESSOR DATA OPERATION
      # elif re.match("10....", ins[6:12]) and ins[27] == "0":
      #   print("cdp")
      #   return {"insnum": 0xd}
      # # COPROCESSOR REGISTER TRANSFER
      # elif re.match("10...0", ins[6:12]) and ins[27] == "1":
      #   print("mcr")
      #   return {"insnum": 0x3}
      # elif re.match("10...1", ins[6:12]) and ins[27] == "1":
      #   print("mrc")
      #   return {"insnum": 0xe}
  else: return {"insnum": -1}

def execute(cs):
  # data processing
  if cs["insnum"] == 0x0:
    print("instruction:", hex(cs["insnum"]))
    # reg
    if cs["i"] == 0: op2 = barrelshifter(cs["rm"], cs["shiftam"], cs["shift"], True)
    # imm
    else: op2 = barrelshifter(cs["imm"], cs["rotate"], 3, True)
    alu(cs["opcode"], cs["s"], cs["rd"], cs["rn"], op2)
    # psr transfer
  elif cs["insnum"] == 0x1:
    print("instruction:", hex(cs["insnum"]))
    # SPSR not supported
    # mrs
    if cs["direction"] == 0: regs[cs["rd"]] = regs[CPSR]
    # msr
    else:
      if cs["i"] == 0: regs[CPSR] = cs["rm"] # reg
      else: regs[CPSR] = barrelshifter(cs["imm"], cs["rotate"], 3, True) # imm
  # multiply
  elif cs["insnum"] == 0x2:
    print("instruction:", hex(cs["insnum"]))
    # mul
    if cs["a"] == 0: res = cs["rm"] * cs["rs"]
    # mla
    else: res = cs["rm"] * cs["rs"] + cs["rn"]
    # set flags
    if cs["s"]:
      # N
      if f"{res:032b}"[0] == "1": regs[CPSR] = regs[CPSR] | 0x80000000
      else: regs[CPSR] = regs[CPSR] & 0x7fffffff
      # Z
      if res == 0: regs[CPSR] = regs[CPSR] | 0x40000000
      else: regs[CPSR] = regs[CPSR] & 0xbfffffff
    regs[cs["rd"]] = res
  # multiply long
  elif cs["insnum"] == 0x3:
    print("instruction:", hex(cs["insnum"]))
    # mull
    if cs["a"] == 0: res = cs["rm"] * cs["rs"]
    # mlal
    else: 
      rn = int(f"{regs[cs['rdhi']]:032b}{regs[cs['rdlo']]:032b}", 2)
      res = cs["rm"] * cs["rs"] + cs["rn"]
    # set flags
    if cs["s"]:
      # N
      if f"{res:064b}"[0] == "1": regs[CPSR] = regs[CPSR] | 0x80000000
      else: regs[CPSR] = regs[CPSR] & 0x7fffffff
      # Z
      if res == 0: regs[CPSR] = regs[CPSR] | 0x40000000
      else: regs[CPSR] = regs[CPSR] & 0xbfffffff
    regs[cs["rdhi"]] = int(f"{res:064b}"[:32], 2)
    regs[cs["rdlo"]] = int(f"{res:064b}"[32:], 2)
  # single data swap
  elif cs["insnum"] == 0x4:
    print("instruction:", hex(cs["insnum"]))
  # branch and exchange
  elif cs["insnum"] == 0x5:
    print("instruction:", hex(cs["insnum"]))
  # half word data transfer (register offset)
  elif cs["insnum"] == 0x6:
    print("instruction:", hex(cs["insnum"]))
  # half word data transfer (immediate offset)
  elif cs["insnum"] == 0x7:
    print("instruction:", hex(cs["insnum"]))
  # single data transfer
  elif cs["insnum"] == 0x8:
    print("instruction:", hex(cs["insnum"]))
    # byte / word
    if cs["b"]: bytenum = 1
    else: bytenum = 4
    # imm
    if cs["i"] == 0: offset = cs["imm"]
    else: offset = barrelshifter(cs["rm"], cs["shiftam"], cs["shift"])
    # pre index
    if cs["p"] == 1:
      if cs["u"]: address = regs[cs["rn"]] + offset
      else: address = regs[cs["rn"]] - offset
    # post index
    else: address = regs[cs["rn"]]
    # write back
    if cs["u"]: writeback = regs[cs["rn"]] + offset
    else: writeback = regs[cs["rn"]] - offset
    if cs["w"] == 1: regs[cs["rn"]] = writeback
    # ldr
    if cs["l"] == 1: regs[cs["rd"]] = mem.load(address, bytenum)
    # str
    else: mem.store(regs[cs["rd"]], address, bytenum)
  # undefined
  elif cs["insnum"] == 0x9:
    print("instruction:", hex(cs["insnum"]))
  # block data transfer
  elif cs["insnum"] == 0xa:
    print("instruction:", hex(cs["insnum"]))
  # branch
  elif cs["insnum"] == 0xb:
    print("instruction:", hex(cs["insnum"]))
  # software interrupt
  elif cs["insnum"] == 0xf:
    print("instruction:", hex(cs["insnum"]))
  # # coprocessor data transfer
  # elif cs["insnum"] == 0xc:
  #   print("instruction:", hex(cs["insnum"]))
  # # coprocessor data operation
  # elif cs["insnum"] == 0xd:
  #   print("instruction:", hex(cs["insnum"]))
  # # coprocessor register transfer
  # elif cs["insnum"] == 0xe:
  #   print("instruction:", hex(cs["insnum"]))

# **** MAIN FUNCTION **** 
def advance():
  cycle = regs[PC] // 4
  # **** FETCH ****
  if int(f"{mem.load(regs[PC]):032b}", 2) != 0:
    print("f", hex(int(f"{mem.load(regs[PC]):032b}", 2)))
    instructions.append(f"{mem.load(regs[PC]):032b}")

  # **** DECODE **** 
  if cycle > 0 and len(instructions) != len(controlsignals):
    print("d", hex(int(instructions[cycle - 1], 2)))
    controlsignals.append(decode(instructions[cycle - 1]))

  # **** EXECUTE ****
  if cycle > 1:
    if cycle > len(controlsignals) + 1:
      quit()
    print("e", controlsignals[cycle - 2])
    execute(controlsignals[cycle - 2])

  regs[PC] += 4
  mem.print()
  regprint()
  print()

if __name__ == "__main__":
  programstore()
  print("\n**** ARM7TDMI ****\n")
  while clk():
    advance()