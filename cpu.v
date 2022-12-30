`timescale 1ns/1ps

// special registers
`define PC 4'd15
`define CPSR 4'd16
// flags
`define N 4'b1000
`define Z 4'b0100
`define C 4'b0010
`define V 4'b0001

module ram(
  input clk, 
  input [31:0] address, 
  input act,
  input ldr,
  input str,
  input [31:0] valin, 
  output reg [31:0] valout
  );

  reg [31:0] mem [0:63];
  integer i;

  initial begin
    $display("**** RAM ****");
    // initial store into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) begin
      $display("M: %0h %h",i , mem[i]);
    end

  end

  always @(posedge clk) begin
    if (act == 1) begin
      // load 
      if (ldr == 1) valout <= mem[address];
      // store
      if (str == 1) mem[address] <= valin;
    end
  end
endmodule

module addressincrementer(input clk, input [31:0] in, output reg [31:0] out);
  initial begin
    $display("**** INCREMENTER ****");
  end

  always @(posedge clk) begin
    out <= in + 4;
  end
endmodule

module alu(
  input clk,
  input [3:0] sel,
  input [31:0] a, b,
  //input [31:0] b,
  output reg [31:0] out
);
  always @(posedge clk) begin
    case (sel)
      1: out = a & b; // AND
      1: out = a & b; // EOR
      2: out = a - b; // SUB
      3: out = b - a; // RSB
      4: out = a + b; // ADD
      5: out = a + b; //+ c; // ADC
      6: out = a - b; //+ c; // SBC
      7: out = b - a; //+ c; // RSC
      8: out = a & b; // TST
      9: out = a ^ b; // TEQ
      10: out = a - b; // CMP
      11: out = a + b; // CMN
      12: out = a | b; // ORR
      13: out = b; // MOV
      14: out = a & ~b; // BIC
      15: out = ~b; // MVN
    endcase
  end
endmodule

module registerbank(
  input clk,
  input regwrite, // if register is to be written
  input [4:0] regselect, // selects, which register is to be written (TAKES EFFECT ONLY WHEN REGWRITE = 1)
  input [31:0] datain, // data that is to be written
  output [31:0] dataout0, output [31:0] dataout1, output [31:0] dataout2, output [31:0] dataout3,
  output [31:0] dataout4, output [31:0] dataout5, output [31:0] dataout6, output [31:0] dataout7,
  output [31:0] dataout8, output [31:0] dataout9, output [31:0] dataout10, output [31:0] dataout11,
  output [31:0] dataout12, output [31:0] dataout13, output [31:0] dataout14, output [31:0] dataout15,
  output [31:0] dataout16 // cpsr
);
  // 16 base registers + cpsr
  reg [31:0] regs [0:16];

  assign dataout0 = regs[0]; assign dataout1 = regs[1]; assign dataout2 = regs[2]; assign dataout3 = regs[3];
  assign dataout4 = regs[4]; assign dataout5 = regs[5]; assign dataout6 = regs[6]; assign dataout7 = regs[7];
  assign dataout8 = regs[8]; assign dataout9 = regs[9]; assign dataout10 = regs[10]; assign dataout11 = regs[11];
  assign dataout12 = regs[12]; assign dataout13 = regs[13]; assign dataout14 = regs[14]; assign dataout15 = regs[15];
  assign dataout16 = regs[16];

  always @(posedge clk) begin
    if (regwrite) begin
      regs[regselect] <= datain;
    end
  end 

endmodule


module instructiondecoder(
  input [31:0] instr
);
  function [7:0] sum (input [7:0] a, b);
    begin
      sum = a + b;
    end
  endfunction

  reg [7:0] a, b, result;

  initial begin
    a = 4;
    b = 4;
    result = sum(a,b);
    #100
    $display(result);
  end
endmodule



module cpu(input clk);
  //reg [31:0] regs [15:0]; // 16 32-bit registers
  // todo remove
  reg [7:0] clkcycle = 0;

  // **** MODULES ****
  // ram
  wire [31:0] memaddr;
  wire [31:0] memvalin;
  wire [31:0] memvalout;
  wire memact = 0;
  wire memldr = 0;
  wire memstr = 0;
  reg [31:0] memout;
  // address incrementer
  reg [31:0] incrin;
  wire [31:0] incrout;
  // register bank
  reg rregwrite;
  reg [4:0] rregselect;
  reg [31:0] rdatain;
  wire [31:0] rdataout [0:16];

  initial begin
    $display("**** CPU ****");
    //regs[`PC] = 0;

    //regsaddr <= `PC;
    //regsvalin <= 2;
  end

  // moudle init
  ram memory(
    .clk (clk), 
    .address (memaddr), 
    .act (memact), 
    .ldr (memldr),
    .str (memstr),
    .valin (memvalin), 
    .valout (memvalout));
  addressincrementer adrincr(
    .clk (clk), 
    .in (incrin), 
    .out (incrout));
  registerbank registers(
    .clk (clk),
    .regwrite (rregwrite),
    .regselect (rregselect), 
    .datain (rdatain),
    .dataout0 (rdataout[0]), .dataout1 (rdataout[1]), .dataout2 (rdataout[2]), .dataout3 (rdataout[3]),
    .dataout4 (rdataout[4]), .dataout5 (rdataout[5]), .dataout6 (rdataout[6]), .dataout7 (rdataout[7]),
    .dataout8 (rdataout[8]), .dataout9 (rdataout[9]), .dataout10 (rdataout[10]), .dataout11 (rdataout[11]),
    .dataout12 (rdataout[12]), .dataout13 (rdataout[13]), .dataout14 (rdataout[14]), .dataout15 (rdataout[15]),
    .dataout16 (rdataout[16]));

  // **** BEGIN **** 
  always @ (posedge clk) begin
    #100_000
    $display("clock ", clkcycle);
    //$display("pc: ", "%0h", regs[`PC]);
    //memaddr <= 1;
    //$display("%h", memval);
    //memaddr <= 2;
    //$display("%h", memval);

    //$display("cond:","%b",mem[0][31:28]);

    //regs[`PC] <= regs[`PC] + 4;


    //incrin = regs[`PC];
    //regs[`PC] = incrout;

    if (clkcycle == 1) begin
      rregwrite <= 1;
      rregselect <= 3;
      rdatain <= 69;
    end
    if (clkcycle == 2) begin
      $display("this", rdataout[3]);
    end
      






    clkcycle <= clkcycle + 1;
  end
endmodule