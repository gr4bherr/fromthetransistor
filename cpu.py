#!/usr/bin/env python3
import re
import time

infile = open("assout.txt", "r")
outfile = open("disassout.txt", "r")

class Regs:
  def __init__(self):
    self.regs = {x:0 for x in range(17)}

  # select: number of register
  # load: if changing value of reg
  # data in: data for the register

  # read is independent of the clock
  

# INIT
r = Regs()
print("\n**** ARM7TDMI ****\n")
memsize = 256 # in bytes
mem = {x:"0" * 8 for x in range(0, memsize, 4)}
PC = 15
CPSR = 16

# not a valid clock of course (wait on instructions to be done)
def clk():
  time.sleep(0.1) # 10 Hz
  return True

# load instructions into memory
def load():
  for i, line in enumerate(infile):
    mem[i*4] = line.strip()

# print memory content
def memprint():
  print("memory", "-" * 54)
  for key, val in mem.items():
    print(f"M{key:<2}: {val}", end="\t")
    if (key+4) % 16 == 0:
      print()
  regprint()
# print register bank content
def regprint():
  print("registers","-"*51)
  for key, val in r.regs.items():
    if key == 16:
      print(f"CPSR {val:08x}")
    else:
      print(f"R{key:<2}: {val:08x}", end="\t")
    if (key+1) % 4 == 0:
      print()


def advance():
  # todo: not sure if this is right
  if int(mem[r.regs[15]], 16) == 0:
    quit()

  # **** FETCH ****
  ins = f"{bin(int(mem[r.regs[15]], 16))[2:]:>032}"
  print(f"\n{ins}")
  #regprint()

  # **** DECODE ****  (control unit)
  cond = int(ins[0:4], 2)
  # if condition valid
  if cond != 0xf:
    if ins[4:6] == "00":
      if ins[6] == "0":
        # DATA PROCESSING: reg {shift}
        if not re.match("10..0", ins[7:12]) and (re.match("...0", ins[24:28]) or re.match("0..1", ins[24:28])):
          print("DATA PROCESSING: reg {shift}")
          opcode = int(ins[7:11]) 
          s = int(ins[11]) # set condition code
          rn = int(ins[12:16])
          rd = int(ins[16:20])
          shift = int(ins[20:25]) # if register, shift right
          shifttype = int(ins[25:27])
          t = int(ins[27]) # 0: imm shift, 1: reg shift
          rm = int(ins[28:])
        elif re.match("10..0", ins[7:12]) and re.match("0...", ins[24:28]):
          if re.match("0...", ins[24:28]):
            # PSR TRANSFER: mrs reg, msr reg
            if ins[25:28] == "000":
              print("PSR TRANSFER: mrs reg, msr reg")
              psr = int(ins[9]) # 0: cpsr, 1: spsr
              direction = int(ins[10]) # 0: mrs, 1: msr
              rd = int(ins[16:20])
              rn = int(ins[28:])
            elif ins[25:28] == "001":
              # BRANCH AND EXCHANGE
              if ins[9:11] == "01":
                print("BRANCH AND EXCHANGE")
                rn = int(ins[28:])
        elif re.match("0....", ins[7:12]) and re.match("1001", ins[24:28]):
          if ins[24:28] == "1001":
            # MULTIPLY
            if re.match("00..", ins[8:12]):
              print("MULTIPLY")
              a = int(ins[10]) # 0: mul, 1: mla
              s = int(ins[11]) # set condition code
              rd = int(ins[12:16])
              rn = int(ins[16:20])
              rs = int(ins[20:24])
              rm = int(ins[28:])
            # MULTIPLY LONG
            elif re.match("1...", ins[8:12]):
              print("MULTIPLY LONG")
              u = int(ins[9]) # 0: unsinged, 1: signed
              a = int(ins[10]) # 0: mul, 1: mla
              s = int(ins[11]) # set condition code
              rdhi = int(ins[12:16])
              rdlo = int(ins[16:20])
              rs = int(ins[20:24])
              rm = int(ins[28:])
        # HALF WORD DATA TRANSFER
        elif (not re.match("0..1.", ins[7:12]) or re.match("0xx10", ins[7:12])) and (ins[24:28] in ["1011", "1101", "1111"]):
          print("HALF WORD DATA TRANSFER")
          # if i == 1 and l == 1 and rn == 1111 -> literal offset
          p = int(ins[7]) # 0: post index, 1: pre index
          u = int(ins[8]) # 0: down bit, 1: up bit
          i = int(ins[9]) # 0: reg offset, 1: imm offset
          w = int(ins[10]) # 0: no write back, 1: write back
          l = int(ins[11]) # 0: str, 1: ldr
          rn = int(ins[12:16])
          rd = int(ins[16:20])
          offset1 = int(ins[20:24])
          sh = int(ins[25:27]) # 00: SWP, 01: H, 10: SB, 11: SH
          offset2 = int(ins[28:])
        # SINGLE DATA SWAP
        # 1110 00 0 10000 11110000000000000000
        elif re.match("10.00", ins[7:12]) and ins[20:28] == "00001001":
          print("SINGLE DATA SWAP")
          b = int(ins[9]) # 0: word, 1: byte
          rn = int(ins[12:16])
          rd = int(ins[16:20])
          rm = int(ins[28:])
      elif ins[6] == "1":
        # DATA PROCESSING: imm
        if not re.match("10..0", ins[7:12]):
          print("DATA PROCESSING: IMM")
          opcode = int(ins[7:11])
          s = int(ins[11]) # set condition code
          rn = int(ins[12:16])
          rd = int(ins[16:20])
          rotate = int(ins[20:24])
          imm = int(ins[24:])
        # PSR TRANSFER: msr imm
        elif re.match("10.10", ins[7:12]):
          print("PSR TRANSFER: msr imm")
          psr = int(ins[9]) # 0: cpsr, 1: spsr
          direction = int(ins[10]) # 0: mrs, 1: msr
          rotate = int(ins[20:24])
          imm = int(ins[24:])
    # SINGE DATA TRANSFER
    elif ins[4:6] == "01":
      print("SINGLE DATA TRANSFER")
      # if p == 0 and w == 1 -> T present
      # if i == 0 and rn = 1111 and T not present -> literal offset
      i = int(ins[6]) # 0: imm offset, 1: reg offset
      p = int(ins[7]) # 0: post index, 1: pre index
      u = int(ins[8]) # 0: down bit, 1: up bit
      b = int(ins[9]) # 0: word, 1: byte (b == 1 -> B present)
      w = int(ins[10]) # 0: no write back, 1: write back
      l = int(ins[11]) # 0: str, 1: ldr
      rn = int(ins[12:16])
      rd = int(ins[16:20])
      if i == 0:
        imm = int(ins[20:])
      else:
        shift = int(ins[20:28])
        rm = int(ins[28:])
    elif ins[4:6] == "10":
      # BLOCK DATA TRANSFER
      if ins[6] == "0":
        print("BLOCK DATA TRANSFER")
        p = int(ins[7]) # 0: post index, 1: pre index
        u = int(ins[8]) # 0: down bit, 1: up bit
        s = int(ins[9]) # 0: dont load psr, 1: load psr
        w = int(ins[10]) # 0: no write back, 1: write back
        l = int(ins[11]) # 0: str, 1: ldr
        rn = int(ins[12:16])
        reglist = int(ins[16:])
      # BRANCH
      elif ins[6] == "0":
        print("BRANCH")
        l = int(ins[7])
        offset = int(ins[8:])
    elif ins[4:6] == "11":
      # UNDEFINED
      if re.match("00000.", ins[6:12]):
        print("UNDEFINED")
      # SOFTWARE INTERRUPT
      elif re.match("110000", ins[6:12]):
        print("SWI")
      ## COPROCESSOR DATA TRANSFER
      #elif re.match("0....0", ins[6:12]) and not re.match("000.00", ins[6:12]):
        #print("stc")
      #elif re.match("0....1", ins[6:12]) and not re.match("000.01", ins[6:12]):
        #if ins[11:15] == "1111":
          #print("ldc (imm)")
        #else:
          #print("ldc (literal")
      ## COPROCESSOR DATA OPERATION
      #elif re.match("10....", ins[6:12]) and ins[27] == "0":
        #print("cdp")
      ## COPROCESSOR REGISTER TRANSFER
      #elif re.match("10...0", ins[6:12]) and ins[27] == "1":
        #print("mcr")
      #elif re.match("10...1", ins[6:12]) and ins[27] == "1":
        #print("mrc")

  # **** EXECUTE **** (alu)







  r.regs[PC] += 4



if __name__ == "__main__":
  load()
  memprint()
  # run
  while clk():
    advance()