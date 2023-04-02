#!/usr/bin/env python3
import glob
import os 

for name in sorted(glob.glob("mytests/*.s")):
  print(f"{name}: ", end = "")

  # gcc
  with open(name, "r") as g:
    correct = g.read().strip().split("\n")
  lcorrect = len(correct)

  # mine
  assert os.path.exists(name[:-1] + "txt"), "file does not exist"

  with open(name[:-1] + "txt", "r") as f:
    mine = f.read().strip().split("\n")
  lmine = len(mine)

  # compare files
  dot = 0
  for i in range(lcorrect):
    if correct[i].strip()[0] == ".":
      dot += 1
      continue
    assert mine[i-dot] == correct[i], f"lines do not match {[mine[i-dot]]} -> {[correct[i]]}"
  
  # file are the same
  print("success")