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


def test():
  ins = "10110"
  m = "10..0"
  if re.match(m, ins) and not re.match(m, "11110"):
    print('2')

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
  #test()

  # if condition valid
  if cond != 0xf:
    # dp and miscellaneous
    if ins[4:6] == "00":
      print("db and miscellaneous")
      if ins[6] == "0":
        if not re.match("10..0", ins[7:12]):
          # dp reg
          if re.match("...0", ins[24:28]):
            print("DP reg")
            if re.match("1101.", ins[7:12]):
              if ins[25:27] == "00":
                if ins[20:25] == "00000":
                  print("mov")
                else:
                  print("lsl (imm)")
              elif ins[25:27] == "01":
                print("lsr (imm)")
              elif ins[25:27] == "10":
                print("asr (imm")
              elif ins[25:27] == "11":
                if ins[20:25] == "00000":
                  print("rrx")
                else:
                  print("ror (imm)")
            else:
              print("opcodex dp (reg)")
          # dp reg-shift reg
          elif re.match("0..1", ins[24:28]):
            print("DP reg-shift reg")
            if re.match("1101.", ins[7:12]):
              if ins[25:27] == "00":
                print("lsl (reg)")
              elif ins[25:27] == "01":
                print("lsr (reg)")
              elif ins[25:27] == "10":
                print("asr (reg)")
              elif ins[25:27] == "11":
                print("ror (reg)")
            else:
              print("opcodex dp (reg-shifted reg)")
        elif re.match("10..0", ins[7:12]):
          # miscellaneous
          if re.match("0...", ins[24:28]):
            print("miscellanious")
            if ins[25:28] == "000":
              if ins[9:11] == "00":
                print("mrs rd, cpsr")
              elif ins[9:11] == "10":
                print("mrs rd, spsr")
              elif ins[9:11] == "01":
                print("msr cpsr, rm")
              elif ins[9:11] == "11":
                print("msr spsr, rm")
            elif ins[25:28] == "001":
              if ins[9:11] == "01":
                print("bx")
        elif re.match("0....", ins[7:12]):
          # multiply (and accum)
          if ins[24:28] == "1001":
            print("multiply (multiply and accumulate")
            if re.match("000.", ins[8,12]):
              print("mul")
            elif re.match("001.", ins[8,12]):
              print("mla")
            elif re.match("100.", ins[8,12]):
              print("umull")
            elif re.match("101.", ins[8,12]):
              print("umlal")
            elif re.match("110.", ins[8,12]):
              print("smull")
            elif re.match("111.", ins[8,12]):
              print("smlal")
        # half word data transfer 1/2
        elif not re.match("0..1.", ins[7:12]):
          if ins[24:28] == "1011":
            if re.match("..0.0", ins[7:12]):
              print("strh (reg)")
            elif re.match("..0.1", ins[7:12]):
              print("ldrh (reg)")
            elif re.match("..1.0", ins[7:12]):
              print("strh (imm)")
            elif re.match("..1.1", ins[7:12]):
              if ins[11:15] != "1111":
                print("ldrh (imm)")
              else:
                print("ldrh (literal)")
          elif ins[24:28] == "1011":
            if re.match("..0.1", ins[7:12]):
              print("ldrsb (reg)")
            elif re.match("..1.1", ins[7:12]):
              if ins[12:16] != "1111":
                print("ldrsb (imm)")
              else:
                print("ldrsb (literal)")
          elif ins[24:28] == "1111":
            if re.match("..0.1", ins[7:12]):
              print("ldrsh (reg)")
            elif re.match("..1.1", ins[7:12]):
              if ins[11:15] != "1111":
                print("ldrsh (imm)")
              else:
                print("ldrsh (literal)")
        # half word data transfer 2/2
        elif re.match("0..10", ins[7:12]):
          if ins[24:28] == "1011":
            if re.match("..0.1", ins[7:12]):
              print("ldrsb (reg)")
            elif re.match("..1.1", ins[7:12]):
              if ins[11:15] != "1111":
                print("ldrsb (imm)")
              else:
                print("ldrsb (literal)")
          elif ins[24:28] == "1111":
            if re.match("..0.1", ins[7:12]):
              print("ldrsh (reg)")
            elif re.match("..1.1", ins[7:12]):
              if ins[11:15] != "1111":
                print("ldrsh (imm)")
              else:
                print("ldrsh (literal)")
      elif ins[6] == "1":
        if not re.match("10..0", ins[7:12]):
          print("dp (imm)")
        elif re.match("10.10", ins[7:12]):
          print("msr (imm)")
    # single data transfer
    elif ins[4:6] == "01":
      if ins[6] == "0":
        if re.match("..0.0", ins[7:12]) and not re.match("0.010", ins[7:12]):
          print("str (imm)")
        elif re.match("0.010", ins[7:12]):
          print("strt")
        elif re.match("..0.1", ins[7:12]) and not re.match("0.011", ins[7:12]):
          if ins[11:15] != "1111":
            print("ldr (imm)")
          else:
            print("ldr (literal)")
        elif re.match("0.011", ins[7:12]):
          print("ldrt")
        elif re.match("..1.0", ins[7:12]) and not re.match("0.110", ins[7:12]):
          print("strb (imm)")
        elif re.match("0.110", ins[7:12]):
          print("strbt")
        elif re.match("..1.1", ins[7:12]) and not re.match("0.111", ins[7:12]):
          if ins[11:15] != "1111":
            print("ldrb (imm)")
          else:
            print("ldrb (literal)")
        elif re.match("0.111", ins[7:12]):
          print("ldrbt")
      elif ins[6] == "1":
        if re.match("..0.0", ins[7:12]) and not re.match("0.010", ins[7:12]):
          print("str (reg)")
        elif re.match("0.010", ins[7:12]):
          print("strt")
        elif re.match("..0.1", ins[7:12]) and not re.match("0.011", ins[7:12]):
            print("ldr (reg)")
        elif re.match("0.011", ins[7:12]):
          print("ldrt")
        elif re.match("..1.0", ins[7:12]) and not re.match("0.110", ins[7:12]):
          print("strb (reg)")
        elif re.match("0.110", ins[7:12]):
          print("strbt")
        elif re.match("..1.1", ins[7:12]) and not re.match("0.111", ins[7:12]):
            print("ldrb (reg)")
        elif re.match("0.111", ins[7:12]):
          print("ldrbt")
    # branch (with link), block data transfer
    elif ins[4:6] == "10":
      if re.match("0000.0", ins[6:12]):
        print("stmda (stmed)")
      elif re.match("0000.1", ins[6:12]):
        print("ldmda/ldmfa")
      elif re.match("0010.0", ins[6:12]):
        print("stm (stmia,stmea)")
      elif re.match("0010.1", ins[6:12]):
        print("ldm/ldmia/ldmfd")
      elif re.match("0100.0", ins[6:12]):
        print("stmdb (stmfd)")
      elif re.match("0100.1", ins[6:12]):
        print("ldmdb/ldmea")
      elif re.match("0110.0", ins[6:12]):
        print("stmib (stmfa)")
      elif re.match("0110.1", ins[6:12]):
        print("ldmib/ldmed")
      elif re.match("0..1.0", ins[6:12]):
        print("stm")
      elif re.match("0..1.1", ins[6:12]):
        print("ldm")
      elif re.match("10....", ins[6:12]):
        print("b")
      elif re.match("11....", ins[6:12]):
        print("bl")
    # coprocessor, supervisor call
    elif ins[4:6] == "11":
      if re.match("00000.", ins[6:12]):
        print("undefined")
      elif re.match("110000", ins[6:12]):
        print("swi")
      elif re.match("0....0", ins[6:12]) and not re.match("000.00", ins[6:12]):
        print("stc")
      elif re.match("0....1", ins[6:12]) and not re.match("000.01", ins[6:12]):
        if ins[11:15] == "1111":
          print("ldc (imm")
        else:
          print("ldc (literal")
      elif re.match("10....", ins[6:12]) and ins[27] == "0":
        print("cdp")
      elif re.match("10...0", ins[6:12]) and ins[27] == "1":
        print("mcr")
      elif re.match("10...1", ins[6:12]) and ins[27] == "1":
        print("mrc")



      




  # **** EXECUTE **** (alu)







  r.regs[PC] += 4



if __name__ == "__main__":
  load()
  memprint()
  # run
  while clk():
    advance()