`timescale 1ns/1ps

module cpuTB();
  reg clk = 0;
  always #10 clk <= ~clk; // 50 MHz (1 cycle = 20ns)

  cpu arm7tdmi(.clk (clk));

  initial begin
    $display("**** TESTBENCH ****");
    $dumpfile("cpu.vcd");
    $dumpvars(0);
    //#1_000_000 // 1ms
    #200 // 200ns
    $finish;
  end
endmodule

// iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out