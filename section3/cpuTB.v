`timescale 1ns/1ps

module cpuTB();
  reg clk = 0;
  reg reset = 0; // todo more like start
  always #10 clk <= ~clk; // 50 MHz (1 cycle = 20ns)

  cpu riscv(.clk(clk), .reset(reset));

  initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0);
    #100_000 // 100 us
    $finish;
  end
endmodule

// iverilog -DTEST=0 -o cpu.out cpuTB.v cpu.v && ./cpu.out