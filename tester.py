#!/usr/bin/env python3

comp = open("compare.txt","r")
out = open("out.txt","r")
i = 0

for line1 in comp:
  i += 1
  line1 = line1.strip()
  for line2 in out:
    line2 = line2.strip()
    if line1 != line2 and line1[0] != "@":
      #print([line1,line2])
      print("error on line:",i)
      c = ""
      a = []
      b = []
      diffa = []
      diffb = []
      x = []
      for j in range(len(line1)):
        if line1[j] == line2[j]:
          c += "_"
        else:
          c += line2[j]
          a.append(line1[j])
          b.append(line2[j])
          x.append(j)
      print("  %s -> %s " % (c,line1),end="")
      print(x)
      for j in range(len(a)):
        diffa.append(bin(int(a[j],16))[2:].zfill(4))
        diffb.append(bin(int(b[j],16))[2:].zfill(4))
        y = []
        for k in range(4):
          if diffa[-1][k] != diffb[-1][k]:
            y.append(k)
        print("     ",diffb[-1],"->",diffa[-1],y)
    break

print("tests done\n")
