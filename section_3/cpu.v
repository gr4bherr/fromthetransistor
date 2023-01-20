
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
`include "modules/signExtend.v"

// todo reuse module (pipes, mux)

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
    .in2(ebuff4),
    .out(pcmux)
  );
  
  // ** DECODE **
  wire [31:0] dbuff;
  buffer decodeBufferMoudle(
    .clk(clk),
    .in(pc),
    .out(dbuff)
  );
  wire [31:0] ir1;
  buffer ir1BufferModule(
    .clk(clk),
    .in(imem),
    .out(ir1)
  );
  wire c_alu1sel;
  wire c_alu2sel;
  wire [4:0] c_rs1;
  wire [4:0] c_rs2;
  wire [31:0] c_imm;
  control ir1ControlModule(
    .ins(ir1),
    .alu1sel(c_alu1sel),
    .alu2sel(c_alu2sel),
    .rs1(c_rs1),
    .rs2(c_rs2),
    .imm(c_imm)
  );
  wire [31:0] add;
  adder pcAdderModule(
    .in1(dbuff),
    .in2(c_imm),
    .out(add)
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
  wire [31:0] alu1mux;
  multiplexer2to1 alu1MultiplexerModule(
    .sel(c_alu1sel),
    .in1(rs1),
    .in2(dbuff),
    .out(alu1mux)
  );
  wire [31:0] alu2mux;
  multiplexer2to1 alu2MultiplexerModule(
    .sel(c_alu2sel),
    .in1(rs2),
    .in2(c_imm),
    .out(alu2mux)
  );
 
  // ** EXECUTE **
  wire [31:0] ebuff1;
  buffer executeBuffer1Module(
    .clk(clk),
    .in(alu1mux),
    .out(ebuff1)
  );
  wire [31:0] ebuff2;
  buffer executeBuffer2Module(
    .clk(clk),
    .in(alu2mux),
    .out(ebuff2)
  );
  wire [31:0] ebuff3;
  buffer executeBuffer3Module(
    .clk(clk),
    .in(rs2),
    .out(ebuff3)
  );
  wire [31:0] ebuff4;
  buffer executeBuffer4Module(
    .clk(clk),
    .in(add),
    .out(ebuff4)
  );
  wire [31:0] ebuff5;
  buffer executeBuffer5Module(
    .clk(clk),
    .in(incr),
    .out(ebuff5)
  );
  wire [31:0] ir2;
  buffer ir2BufferModule(
    .clk(clk),
    .in(ir1),
    .out(ir2)
  );
  wire [6:0] c_opcode;
  wire [2:0] c_funct3;
  wire [6:0] c_funct7;
  wire [4:0] c_shamt;
  control ir2ControlModule(
    .ins(ir2),
    .opcode(c_opcode),
    .funct3(c_funct3),
    .funct7(c_funct7),
    .shamt(c_shmat)
  );
  wire zero;
  wire [31:0] alu;
  alu aluModule(
    .opcode(c_opcode),
    .funct3(c_funct3),
    .funct7(c_funct7),
    .shamt(c_shamt),
    .in1(ebuff1),
    .in2(ebuff2),
    .zero(zero),
    .out(alu)
  );
 
  // ** MEMORY ** 
  wire [31:0] mbuff1;
  buffer memoryBuffer1Module(
    .clk(clk),
    .in(alu),
    .out(mbuff1)
  );
  wire [31:0] mbuff2;
  buffer memoryBuffer2Module(
    .clk(clk),
    .in(ebuff3),
    .out(mbuff2)
  );
  wire [31:0] mbuff3;
  buffer memoryBuffer3Module(
    .clk(clk),
    .in(ebuff5),
    .out(mbuff3)
  );
  wire [31:0] ir3;
  buffer ir3BufferModule(
    .clk(clk),
    .in(ir2),
    .out(ir3)
  );
  wire c_memwrite;
  wire [1:0] c_memsel;
  control ir3ControlModule(
    .ins(ir3),
    .memwrite(c_memwrite),
    .memsel(c_memsel)
  );
  wire [31:0] dmem;
  dataMemory dataMemoryModule(
    .clk(clk),
    .memwrite(c_memwrite),
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
  wire [31:0] wbuff;
  buffer writebackBuffer(
    .clk(clk),
    .in(memmux),
    .out(wbuff)
  );
  wire [31:0] ir4;
  buffer ir4BufferModule(
    .clk(clk),
    .in(ir3),
    .out(ir4)
  );
  wire c_regwrite;
  wire [4:0] c_rd;
  control ir4ControlModule(
    .ins(ir4),
    .regwrite(c_regwrite),
    .rd(c_rd)
  );
  
endmodule
