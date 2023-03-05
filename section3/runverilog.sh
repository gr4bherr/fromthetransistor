#!/bin/bash
for i in {0..38} 
do 
  iverilog -DTEST=$i -o cpu.out cpuTB.v cpu.v && ./cpu.out
done