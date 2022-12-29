`timescale 1ns/1ps

`define PC 4'd15


module ram(input [31:0] address, output [31:0] outvalue);
  reg [31:0] mem [0:63];
  integer i;

  initial begin
    $display("**** RAM ****");
    // initial load into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) begin
      $display("M: %0h %h",i , mem[i]);
    end
  end

  assign outvalue = mem[address];
endmodule

module incrementer(input [31:0] in, output [31:0] out);
  initial begin
    $display("**** INCREMENTER ****");
  end

  assign out = in + 1;
endmodule




module cpu(input clk);
  reg [31:0] regs [15:0]; // 16 32-bit registers

  reg [31:0] memaddr;
  wire [31:0] memval;
  reg [31:0] incrin;
  wire [31:0] incrout;

  ram memory(.address (memaddr), .outvalue (memval));
  incrementer incrementermodule(.in (incrin), .out (incrout));



  initial begin
    $display("**** CPU ****");
    regs[`PC] = 0;
  end

  always @ (posedge clk) begin
    #100000
    $display("pc: ", "%0h", regs[`PC]);
    //memaddr <= 1;
    //$display("%h", memval);
    //memaddr <= 2;
    //$display("%h", memval);

    //$display("cond:","%b",mem[0][31:28]);

    //regs[`PC] <= regs[`PC] + 4;


    incrin = regs[`PC];
    regs[`PC] = incrout;






  end
endmodule