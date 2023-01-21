
`include "modules/macros.v"

`include "modules/adder.v"
`include "modules/alu.v"
`include "modules/buffer.v"
`include "modules/control.v"
`include "modules/dataMemory.v"
`include "modules/instructionMemory.v"
`include "modules/multiplexer2to1.v"
`include "modules/multiplexer4to1.v"
`include "modules/pcRegister.v"
`include "modules/registerBank.v"

// **** MAIN MODULE ****
module cpu(input clk, input reset);

  // ** FETCH **
  wire [31:0] pc;
  pcRegister pcRegisterModule(
    .clk(clk),
    .in(pcmux),
    .out(pc)
  );
  wire [31:0] imem;
  instructionMemory instructionMemoryModule(
    .address(pc),
    .instruction(imem)
  );
  wire [31:0] incr;
  adder pcIncrementModule(
    .in1(4),
    .in2(dbuff),
    .out(incr)
  );
  wire [31:0] pcmux;
  multiplexer2to1 pcMultiplexerModule(
    .sel(zero),
    .in1(incr),
    .in2(alu),
    .out(pcmux)
  );
  
  // ** DECODE **
  wire [31:0] ir1;
  wire [31:0] dbuff; // pc
  buffer decodeBufferModule(
    .clk(clk),
    .in0(imem),
    .in1(pc),
    .out0(ir1),
    .out1(dbuff)
  );
  wire [4:0] c_rs1;
  wire [4:0] c_rs2;
  wire [31:0] c_imm;
  control ir1ControlModule(
    .ins(ir1),
    .rs1(c_rs1),
    .rs2(c_rs2),
    .imm(c_imm)
  );
  wire [31:0] rs1;
  wire [31:0] rs2;
  registerBank registerBankModule(
    .clk(clk),
    .regwrite(c_regwrite),
    .rdaddr(c_rd),
    .rddata(wbuff),
    .rs1addr(c_rs1),
    .rs2addr(c_rs2),
    .rs1(rs1),
    .rs2(rs2)
  );
 
  // ** EXECUTE **
  wire [31:0] ir2;
  wire [31:0] ebuff1; // pc
  wire [31:0] ebuff2; // rs1
  wire [31:0] ebuff3; // rs2 
  wire [31:0] ebuff4; // imm
  wire [31:0] ebuff5; // pc + 4
  buffer executeBufferModule(
    .clk(clk),
    .in0(ir1), 
    .in1(dbuff), 
    .in2(rs1), 
    .in3(rs2), 
    .in4(c_imm), 
    .in5(incr),
    .out0(ir2), 
    .out1(ebuff1), 
    .out2(ebuff2), 
    .out3(ebuff3), 
    .out4(ebuff4), 
    .out5(ebuff5)
  );
  wire [6:0] c_opcode;
  wire [2:0] c_funct3;
  wire [6:0] c_funct7;
  control ir2ControlModule(
    .ins(ir2),
    .opcode(c_opcode),
    .funct3(c_funct3),
    .funct7(c_funct7)
  );
  wire zero;
  wire [31:0] alu;
  alu aluModule(
    .opcode(c_opcode),
    .funct3(c_funct3),
    .funct7(c_funct7),
    .pc(ebuff1),
    .rs1(ebuff2),
    .rs2(ebuff3),
    .imm(ebuff4),
    .zero(zero),
    .out(alu)
  );
 
  // ** MEMORY ** 
  wire [31:0] ir3;
  wire [31:0] mbuff1; // alu
  wire [31:0] mbuff2; // rs2
  wire [31:0] mbuff3; // pc + 4
  buffer memoryBufferModule(
    .clk(clk),
    .in0(ir2),
    .in1(alu),
    .in2(ebuff3),
    .in3(ebuff5),
    .out0(ir3),
    .out1(mbuff1),
    .out2(mbuff2),
    .out3(mbuff3)
  );
  wire c_memwrite;
  wire [1:0] c_memarea;
  wire [1:0] c_memsel;
  control ir3ControlModule(
    .ins(ir3),
    .memwrite(c_memwrite),
    .memarea(c_memarea),
    .memsel(c_memsel)
  );
  wire [31:0] dmem;
  dataMemory dataMemoryModule(
    .clk(clk),
    .write(c_memwrite),
    .area(c_memarea),
    .address(mbuff1),
    .datain(mbuff2),
    .dataout(dmem)  
  );
  wire [31:0] memmux;
  multiplexer4to1 memMultiplexerModule(
    .sel(c_memsel),
    .in1(mbuff3),
    .in2(dmem),
    .in3(mbuff1),
    .out(memmux)
  );
  
  // ** WRITE BACK **
  wire [31:0] ir4;
  wire [31:0] wbuff;
  buffer writebackBufferModule(
    .clk(clk),
    .in0(ir3),
    .in1(memmux),
    .out0(ir4),
    .out1(wbuff)
  );
  wire c_regwrite;
  wire [4:0] c_rd;
  control ir4ControlModule(
    .ins(ir4),
    .regwrite(c_regwrite),
    .rd(c_rd)
  );
endmodule
