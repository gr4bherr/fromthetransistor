`timescale 1ns/1ps

`include "macros.v"

`include "modules/memory.v"
`include "modules/addressRegister.v"
`include "modules/addressIncrementer.v"
`include "modules/dataRegister.v"
`include "modules/instructionRegister.v"
`include "modules/instructionDecoder.v"
`include "modules/registerBank.v"
`include "modules/barrelShifter.v"
`include "modules/alu.v"

// ./assembler.py assin.s && iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out

module cpu (input clk);
  // BUSES
  wire [31:0] databus;
  wire [31:0] alubus;
  wire [31:0] incrementerbus;
  wire [31:0] addressbus;
  wire [31:0] abus;
  wire [31:0] bbus;
  wire [31:0] bbusext;
  wire [31:0] incrinbus;
  wire [31:0] decodebus;
  wire [31:0] pcbus;

  // MODULES
  addressIncrementer addressIncrementerModule (
    //.increment (ctrl[`c_incrementenable]),
    .increment (1'b1),
    .datain (incrinbus),
    .dataout (incrementerbus));

  addressRegister addressRegisterModule (
    .clk (clk),
    //.write (ctrl[`c_addrwrite]),
    .write (1'b1),
    .in1on (ctrl[`c_addrin1]),
    //.in2on (ctrl[`c_addrin2]),
    .in2on (1'b1),
    .in3on (ctrl[`c_pcchange]),
    //.out1on (ctrl[`c_addrout1]),
    .out1on (1'b1),
    //.out2on (c_addrout2),
    .in1 (alubus),
    .in2 (incrementerbus),
    .in3 (pcbus),
    .out1 (addressbus),
    .out2 (incrinbus));

  wire writebackalu;
  wire [3:0] aluflagsout;
  alu aluModule (
    .opcode (i_opcode),
    .setflags (ctrl[`c_setflags]),
    .dataina (abus),
    .datainb (bbusext),
    .flagsin (bsflagsout),
    .writeback (writebackalu),
    .dataout (alubus),
    .flagsout (aluflagsout));

  wire [3:0] bsflagsout;
  barrelShifter barrelShifterModule (
    .vimm (ctrl[`c_shiftvalimm]),
    .bimm (ctrl[`c_shiftbyimm]),
    .type (i_shifttype),
    .valimm (i_shiftval),
    .valreg (bbus),
    .byimm (i_shiftby),
    .byreg (shiftbyreg),
    .datain (bbus),
    .dataout (bbusext),
    .flagsin (cpsrflagsout),
    .flagsout (bsflagsout));


  dataRegister dataRegisterModule (
    .clk (clk),
    .inon (ctrl[`c_dataregin]),
    //.outon (ctrl[`c_dataregout]),
    .outon (1'b0),
    .datain (bbus),
    .dataout (databus));

  wire [31:0] ctrl;
  wire [31:0] i_shiftby;
  wire [1:0] i_shifttype;
  wire [3:0] i_opcode;
  wire [3:0] i_rm;
  wire [3:0] i_rn;
  wire [3:0] i_rs;
  wire [3:0] i_rd;
  wire [7:0] i_shiftval;
  instructionDecoder instructionDecoderModule (
    .ins (decodebus),
    //.instruction (instr),
    .control (ctrl),
    .flagsin (cpsrflagsout),
    .shiftby (i_shiftby),
    .shifttype (i_shifttype),
    .opcode (i_opcode),
    .rm (i_rm),
    .rn (i_rn),
    .rd (i_rd),
    .rs (i_rs),
    .shiftval (i_shiftval));

  instructionRegister instructionRegisterModule (
    .clk (clk),
    //.inon (ctrl[`c_instructionRegisterin]),
    .inon (1'b1),
    //.out1on (ctrl[`c_instructionRegisterout]),
    .out1on (1'b1),
    .datain (databus),
    .dataout1 (bbus),
    .dataout2 (decodebus));

  memory memoryModule (
    .clk (clk), 
    .write (ctrl[`c_memwrite]), 
    //.out (ctrl[`c_memout]),
    .out (1'b1),
    .address (addressbus),
    .data (databus));

  wire [7:0] shiftbyreg;
  wire [3:0] cpsrflagsout;
  registerBank registerBankModule (
    .clk (clk),
    .write (ctrl[`c_regwrite]),
    //.pcwrite (ctrl[`c_regpcwrite]),
    .pcchange (ctrl[`c_pcchange]),
    .cpsrwrite (ctrl[`c_setflags]),
    .writeback (writebackalu),
    .alubusin (alubus),
    .incrbusin (incrementerbus),
    .rm (i_rm),
    .rn (i_rn),
    .rs (i_rs),
    .rd (i_rd),
    .flagsin (aluflagsout),
    .flagsout (cpsrflagsout),
    .abusout (abus),
    .bbusout (bbus),
    .barrelshifterout (shiftbyreg),
    .pcbusout (pcbus));

  // FOR TEST // todo
  reg [31:0] cycles = 0;
  always @ (posedge clk) begin
    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end
endmodule