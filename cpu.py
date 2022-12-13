#!/usr/bin/env python3
import re
import time

infile = open("assout.txt", "r")
outfile = open("disassout.txt", "r")

# **** print functions **** 
# print memory content
def memprint():
  print("memory", "-" * 54)
  for key, val in mem.items():
    print(f"M{key:<2}: {val}", end="\t")
    if (key+4) % 16 == 0: print()
  regprint()
  print("**** START ****")
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
print("\n**** ARM7TDMI ****\n")
regs = {x:0 for x in range(17)}
memsize = 32 # in bytes
mem = {x:"0" * 8 for x in range(0, memsize, 4)}
PC = 15
CPSR = 16
# FIQ disable, IRQ disable, T clear, mode: supervisor
regs[CPSR] = 0b111010011 
# not a valid clock of course (waits on instructions to be done)
def clk():
  time.sleep(0.1) # 10 Hz
  return True
# load instructions into memory at the beginning
def load():
  for i, line in enumerate(infile):
    mem[i*4] = line.strip()
  
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
  elif opcode == 15: #MVN
    res = ~op2
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
      carry = bin(n)[-1]
      res = 0
    elif shiftam > 32:
      carry = 0
      res = 0
    else:
      tmp = bin(n << shiftam)
      carry = int(tmp[-33]) if len(tmp) - 2 > 32 else 0
      res = n << shiftam & 0xffffffff
  # LSR
  elif shift == 1:
    if shiftam == 32:
      carry = bin(n)[2]
      res = 0
    elif shiftam > 32:
      carry = 0
      res = 0
    else:
      carry = int(f"{n:032b}"[-shiftam])
      res = n >> shiftam
  # ASR
  elif shift == 2:
    if shiftam >= 32:
      carry = bin(n[2])
      res = n
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
        carry = bin(n[2])
        res = n
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

def advance():
  # todo: not sure if this is right
  if int(mem[regs[15]], 16) == 0:
    print("**** FINISHED ****")
    quit()

  # **** FETCH ****
  ins = f"{bin(int(mem[regs[15]], 16))[2:]:>032}"
  print(f"\n{ins}")

  # **** DECODE ****  (control unit)
  print(conditioncheck(int(ins[:4], 2)))
  if conditioncheck(int(ins[:4], 2)): # if condition valid
    if ins[4:6] == "00":
      if ins[6] == "0":
        # DATA PROCESSING: reg {shift} (1/2)
        if not re.match("10..0", ins[7:12]) and (re.match("...0", ins[24:28]) or re.match("0..1", ins[24:28])):
          insnum = 0x0
          i = int(ins[6], 2)
          opcode = int(ins[7:11], 2) 
          s = int(ins[11]) # set condition code
          rn = regs[int(ins[12:16], 2)]
          rd = int(ins[16:20], 2)
          shiftam = int(ins[20:25], 2) # if register, shift right
          shift = int(ins[25:27], 2)
          t = int(ins[27], 2) # 0: imm shift, 1: reg shift
          rm = regs[int(ins[28:], 2)]
        elif re.match("10..0", ins[7:12]) and re.match("0...", ins[24:28]):
          if re.match("0...", ins[24:28]):
            # PSR TRANSFER: mrs reg, msr reg (1/2)
            if ins[25:28] == "000":
              insnum = 0x1
              i = int(ins[6])
              psr = int(ins[9], 2) # 0: cpsr, 1: spsr
              direction = int(ins[10], 2) # 0: mrs, 1: msr
              rd = int(ins[16:20], 2)
              rm = regs[int(ins[28:], 2)]
            elif ins[25:28] == "001":
              # BRANCH AND EXCHANGE
              if ins[9:11] == "01":
                insnum = 0x5
                rn = regs[int(ins[28:], 2)]
        elif re.match("0....", ins[7:12]) and re.match("1001", ins[24:28]):
          if ins[24:28] == "1001":
            # MULTIPLY
            if re.match("00..", ins[8:12]):
              insnum = 0x2
              a = int(ins[10], 2) # 0: mul, 1: mla
              s = int(ins[11], 2) # set condition code
              rd = int(ins[12:16], 2)
              rn = regs[int(ins[16:20], 2)]
              rs = regs[int(ins[20:24], 2)]
              rm = regs[int(ins[28:], 2)]
            # MULTIPLY LONG
            elif re.match("1...", ins[8:12]):
              insnum = 0x3
              u = int(ins[9], 2) # 0: unsinged, 1: signed
              a = int(ins[10], 2) # 0: mull, 1: mlal
              s = int(ins[11], 2) # set condition code
              rdhi = int(ins[12:16], 2)
              rdlo = int(ins[16:20], 2)
              rs = regs[int(ins[20:24], 2)]
              rm = regs[int(ins[28:], 2)]
        # HALF WORD DATA TRANSFER
        elif (not re.match("0..1.", ins[7:12]) or re.match("0xx10", ins[7:12])) and (ins[24:28] in ["1011", "1101", "1111"]):
          # if i == 1 and l == 1 and rn == 1111 -> literal offset
          p = int(ins[7], 2) # 0: post index, 1: pre index
          u = int(ins[8], 2) # 0: down bit, 1: up bit
          i = int(ins[9], 2) # 0: reg offset, 1: imm offset
          w = int(ins[10], 2) # 0: no write back, 1: write back
          l = int(ins[11], 2) # 0: str, 1: ldr
          rn = regs[int(ins[12:16], 2)]
          rd = regs[int(ins[16:20], 2)]
          offset1 = int(ins[20:24], 2)
          sh = int(ins[25:27], 2) # 00: SWP, 01: H, 10: SB, 11: SH
          offset2 = int(ins[28:], 2) if i == 0 else regs[int(ins[28:], 2)]
          insnum = 0x6 if i == 0 else 0x7
        # SINGLE DATA SWAP
        # 1110 00 0 10000 11110000000000000000
        elif re.match("10.00", ins[7:12]) and ins[20:28] == "00001001":
          insnum = 0x4
          b = int(ins[9], 2) # 0: word, 1: byte
          rn = regs[int(ins[12:16], 2)]
          rd = regs[int(ins[16:20], 2)]
          rm = regs[int(ins[28:], 2)]
      elif ins[6] == "1":
        # DATA PROCESSING: imm (2/2)
        if not re.match("10..0", ins[7:12]):
          insnum = 0x0
          i = int(ins[6], 2)
          opcode = int(ins[7:11], 2)
          s = int(ins[11], 2) # set condition code
          rn = regs[int(ins[12:16], 2)]
          rd = int(ins[16:20], 2)
          rotate = int(ins[20:24], 2) * 2
          imm = int(ins[24:], 2)
        # PSR TRANSFER: msr imm (2/2)
        elif re.match("10.10", ins[7:12]):
          insnum = 0x1
          i = int(ins[6])
          psr = int(ins[9], 2) # 0: cpsr, 1: spsr
          direction = int(ins[10], 2) # 0: mrs, 1: msr
          rotate = int(ins[20:24], 2)
          imm = int(ins[24:], 2)
    # SINGE DATA TRANSFER
    elif ins[4:6] == "01":
      insnum = 0x8
      # if p == 0 and w == 1 -> T present
      # if i == 0 and rn = 1111 and T not present -> literal offset
      i = int(ins[6], 2) # 0: imm offset, 1: reg offset
      p = int(ins[7], 2) # 0: post index, 1: pre index
      u = int(ins[8], 2) # 0: down bit, 1: up bit
      b = int(ins[9], 2) # 0: word, 1: byte (b == 1 -> B present)
      w = int(ins[10], 2) # 0: no write back, 1: write back
      l = int(ins[11], 2) # 0: str, 1: ldr
      rn = regs[int(ins[12:16], 2)]
      rd = regs[int(ins[16:20], 2)]
      if i == 0: imm = int(ins[20:], 2)
      else:
        shiftam = int(ins[20:25], 2)
        shift = int(ins[25:27], 2)
        t = int(ins[27], 2)
        rm = regs[int(ins[28:], 2)]
    elif ins[4:6] == "10":
      # BLOCK DATA TRANSFER
      if ins[6] == "0":
        insnum = 0xa
        p = int(ins[7], 2) # 0: post index, 1: pre index
        u = int(ins[8], 2) # 0: down bit, 1: up bit
        s = int(ins[9], 2) # 0: dont load psr, 1: load psr
        w = int(ins[10], 2) # 0: no write back, 1: write back
        l = int(ins[11], 2) # 0: str, 1: ldr
        rn = regs[int(ins[12:16], 2)]
        reglist = int(ins[16:], 2)
      # BRANCH
      elif ins[6] == "0":
        insnum = 0xb
        l = int(ins[7], 2)
        offset = int(ins[8:], 2)
    elif ins[4:6] == "11":
      # UNDEFINED
      if re.match("00000.", ins[6:12]):
        insnum = 0x9
      # SOFTWARE INTERRUPT
      elif re.match("110000", ins[6:12]):
        insnum = 0xf
      # # COPROCESSOR DATA TRANSFER
      # elif re.match("0....0", ins[6:12]) and not re.match("000.00", ins[6:12]):
      #   print("stc")
      #   insnum = 0xc
      # elif re.match("0....1", ins[6:12]) and not re.match("000.01", ins[6:12]):
      #   insnum = 0xc
      #   if ins[11:15] == "1111":
      #     print("ldc (imm)")
      #   else:
      #     print("ldc (literal")
      # # COPROCESSOR DATA OPERATION
      # elif re.match("10....", ins[6:12]) and ins[27] == "0":
      #   print("cdp")
      #   insnum = 0xd
      # # COPROCESSOR REGISTER TRANSFER
      # elif re.match("10...0", ins[6:12]) and ins[27] == "1":
      #   print("mcr")
      #   insnum = 0xe
      # elif re.match("10...1", ins[6:12]) and ins[27] == "1":
      #   print("mrc")
      #   insnum = 0xe
  else: insnum = -1

  # **** EXECUTE ****
  # data processing
  if insnum == 0x0:
    print("instruction:", hex(insnum))
    # reg
    if i == 0: op2 = barrelshifter(rm, shiftam, shift, True)
    # imm
    else: 
      op2 = barrelshifter(imm, rotate, 3, True)
    alu(opcode, s, rd, rn, op2)
  # psr transfer
  elif insnum == 0x1:
    print("instruction:", hex(insnum))
    # SPSR not supported
    # mrs
    if direction == 0: regs[rd] = regs[CPSR]
    # msr
    else:
      if i == 0: regs[CPSR] = rm # reg
      else: regs[CPSR] = barrelshifter(imm, rotate, 3, True) # imm
  # multiply
  elif insnum == 0x2:
    print("instruction:", hex(insnum))
    # mul
    if a == 0: res = rm*rs
    # mla
    else: res = rm*rs+rn
    # set flags
    if s:
      # N
      if f"{res:032b}"[0] == "1": regs[CPSR] = regs[CPSR] | 0x80000000
      else: regs[CPSR] = regs[CPSR] & 0x7fffffff
      # Z
      if res == 0: regs[CPSR] = regs[CPSR] | 0x40000000
      else: regs[CPSR] = regs[CPSR] & 0xbfffffff
    regs[rd] = res
  # multiply long
  elif insnum == 0x3:
    print("instruction:", hex(insnum))
    # mull
    if a == 0: res = rm*rs
    # mlal
    else: 
      rn = int(f"{regs[rdhi]:032b}{regs[rdlo]:032b}", 2)
      res = rm*rs+rn
    # set flags
    if s:
      # N
      if f"{res:064b}"[0] == "1": regs[CPSR] = regs[CPSR] | 0x80000000
      else: regs[CPSR] = regs[CPSR] & 0x7fffffff
      # Z
      if res == 0: regs[CPSR] = regs[CPSR] | 0x40000000
      else: regs[CPSR] = regs[CPSR] & 0xbfffffff
    regs[rdhi] = int(f"{res:064b}"[:32], 2)
    regs[rdlo] = int(f"{res:064b}"[32:], 2)
  # single data swap
  elif insnum == 0x4:
    print("instruction:", hex(insnum))
  # branch and exchange
  elif insnum == 0x5:
    print("instruction:", hex(insnum))
  # half word data transfer (register offset)
  elif insnum == 0x6:
    print("instruction:", hex(insnum))
  # half word data transfer (immediate offset)
  elif insnum == 0x7:
    print("instruction:", hex(insnum))
  # single data transfer
  elif insnum == 0x8:
    print("instruction:", hex(insnum))
  # undefined
  elif insnum == 0x9:
    print("instruction:", hex(insnum))
  # block data transfer
  elif insnum == 0xa:
    print("instruction:", hex(insnum))
  # branch
  elif insnum == 0xb:
    print("instruction:", hex(insnum))
  # software interrupt
  elif insnum == 0xf:
    print("instruction:", hex(insnum))
  # # coprocessor data transfer
  # elif insnum == 0xc:
  #   print("instruction:", hex(insnum))
  # # coprocessor data operation
  # elif insnum == 0xd:
  #   print("instruction:", hex(insnum))
  # # coprocessor register transfer
  # elif insnum == 0xe:
  #   print("instruction:", hex(insnum))

  regs[PC] += 4
  regprint()




if __name__ == "__main__":
  load()
  memprint()
  # run
  while clk():
    advance()