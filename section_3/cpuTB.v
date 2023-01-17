`timescale 1ns/1ps

module cpuTB();
  reg clk = 0;
  reg reset = 0; // todo more like start
  always #10 clk <= ~clk; // 50 MHz (1 cycle = 20ns)

  cpu arm7tdmi(.clk(clk), .reset(reset));

  initial begin
    $display("**** TESTBENCH ****");
    $dumpfile("cpu.vcd");
    $dumpvars(0);
    reset <= 1;
    #20
    reset <= 0;
    //#1_000_000 // 1ms
    //#500 // 200ns
    #5000
    $finish;
  end
endmodule

// iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out