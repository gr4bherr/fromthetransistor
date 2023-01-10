// iverilog -o ledBlink.out ledBlinkTB.v ledBlink.v && ./ledBlink.out
`timescale 1us/1ns

module ledBlinkTB ();
  reg clk = 0;
  always #10 clk <= ~clk; // frequency: 50 KHz

  ledBlink ledBlinkModule(.clk(clk));

  initial begin
    $dumpfile("ledBlink.vcd");
    $dumpvars(0);
    #10_000_000 // duration: 10s
    $finish;
  end
endmodule