`timescale 1ns/1ps

// special registers
`define PC 4'd15
`define CPSR 4'd16
// flags
`define N 4'b1000
`define Z 4'b0100
`define C 4'b0010
`define V 4'b0001

// **** MODULES **** 
module registerBank(
  input clk,
  input load, // if register is to be written
  input [4:0] select, // selects, which register is to be written (TAKES EFFECT ONLY WHEN regload = 1)
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
  
  initial begin
    regs[`CPSR] <= 32'b111010011;
  end

  always @(posedge clk) begin
    if (load) begin
      regs[select] <= datain;
    end
  end 
endmodule

module memory(
  input clk,
  input load, 
  input [31:0] address,
  input [31:0] datain,
  output [31:0] dataout
);
  reg [31:0] mem [0:63]; // 64 * 4 bytes
  integer i;
  // load
  assign dataout = mem[address];

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
    if (load) begin 
      mem[address] <= datain;
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
  // register bank
  reg regload;
  reg [4:0] regselect;
  reg [31:0] regdatain;
  wire [31:0] regdataout [0:16];
  // memory
  reg memload;
  reg [31:0] memaddress;
  reg [31:0] memdatain;
  wire [31:0] memdataout;
  // address incrementer
  reg [31:0] incrin;
  wire [31:0] incrout;

  initial begin
    $display("**** CPU ****");
    //regs[`PC] = 0;

    //regsaddr <= `PC;
    //regsvalin <= 2;
  end

  // module init
  registerBank registers(
    .clk (clk),
    .load (regload),
    .select (regselect), 
    .datain (regdatain),
    .dataout0 (regdataout[0]), .dataout1 (regdataout[1]), .dataout2 (regdataout[2]), .dataout3 (regdataout[3]),
    .dataout4 (regdataout[4]), .dataout5 (regdataout[5]), .dataout6 (regdataout[6]), .dataout7 (regdataout[7]),
    .dataout8 (regdataout[8]), .dataout9 (regdataout[9]), .dataout10 (regdataout[10]), .dataout11 (regdataout[11]),
    .dataout12 (regdataout[12]), .dataout13 (regdataout[13]), .dataout14 (regdataout[14]), .dataout15 (regdataout[15]),
    .dataout16 (regdataout[16]));
  memory mem(
    .clk (clk), 
    .load (memload), 
    .address (memaddress), 
    .datain (memdatain), 
    .dataout (memdataout));
  addressincrementer adrincr(
    .clk (clk), 
    .in (incrin), 
    .out (incrout));

  // **** BEGIN **** 
  always @ (posedge clk) begin
    #100_000
    $display("clock ", clkcycle);
    //$display("cond:","%b",mem[0][31:28]);

    //incrin = regs[`PC];
    //regs[`PC] = incrout;

    if (clkcycle == 1) begin
      regselect <= 3;
      regdatain <= 69;
      regload <= 1;
    end
    if (clkcycle == 2) begin
      $display("reg", regdataout[3]);
    end
      
    if (clkcycle == 3) begin
      memaddress <= 4;
    end
    if (clkcycle == 4) begin
      $display("%h", memdataout);
      memdatain <= 44;
      memaddress <= 4;
      memload <= 1;
    end
    if (clkcycle == 5) begin
      $display("mem", memdataout);
    end






    clkcycle <= clkcycle + 1;
  end
endmodule