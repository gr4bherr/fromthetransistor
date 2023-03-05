// iverilog -o uart.out uartTB.v uart.v && ./uart.out
`timescale 1ns/1ps
`include "uartmacros.v"

module uartTB ();
  parameter bitlength = `timescaleunit / `baudrate; // 1/9600 * 10 ** 9 (in ns)


  reg rx1;
  wire tx1;
  reg transon1;
  // clk frequency: 153 600 Hz
  reg clk1 = 0;
  always #((`timescaleunit / `clockfrequency) / 2) clk1 <= ~clk1; // ≈ 3255
  uart uart1 (.clk(clk1), .rx(rx1), .transon(transon1), .tx(tx1));

  //reg rx2;
  //wire tx2;
  //reg transon2;
  //reg clk2 = 0;
  //initial begin
    //#2
    //forever begin
      //#10 clk2 = 1;
      //#10 clk2 = 0;
    //end
  //end
  //uart uart1 (.clk(clk2), .rx(rx2), .transon(transon2), .tx(tx2));

  reg [7:0] num1 = 8'haa;
  reg [7:0] num2 = 8'hf0;
  integer i;

  task recieveNum(input [7:0] val);
    begin
      #bitlength
      rx1 = 0;
      for (i = 7; i >= 0; i = i - 1) begin // from msb to lsb
        #bitlength
        rx1 = val[i];
      end
      #bitlength
      rx1 = 1;
    end
  endtask

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0);
    // reciever
    rx1 = 1;
    #100
    recieveNum(num1);
    #100_000
    // transmit
    transon1 = 1;
    #1000
    transon1 = 0;
    #1_000_000 // 1 s extra
    $finish;
  end
endmodule
