`include "modules/macros.v"

`include "modules/adder.v"
`include "modules/alu.v"
`include "modules/buffer.v"
`include "modules/dataMemory.v"
`include "modules/instructionDecoder.v"
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
  wire [31:0] pcout;
  pcRegister pcRegisterModule(
    .clk(clk),
    .reset(reset),
    .in(pcmuxout),
    .out(pcout)
  );
  wire [31:0] imemout;
  instructionMemory instructionMemoryModule(
    .address(pcout),
    .instruction(imemout)
  );

  // ** DECODE **
  wire [31:0] ir1out;
  buffer ir1BufferModule(
    .clk(clk),
    .in(imemout),
    .out(ir1out)
  );
  wire c_alu1sel;
  wire c_alu2sel;
  wire c_pcsel;
  wire [4:0] c_rs1;
  wire [4:0] c_rs2;
  wire [31:0] c_imm;
  instructionDecoder instruction1DecoderModule(
    .ins(ir1out),
    .pcsel(c_pcsel),
    .alu1sel(c_alu1sel),
    .alu2sel(c_alu2sel),
    .rs1(c_rs1),
    .rs2(c_rs2),
    .imm(c_imm)
  );
  wire [31:0] incrout;
  adder pcIncrementerModule(
    .in1(32'd4),
    .in2(pcout),
    .out(incrout)
  );
  wire [31:0] addrout;
  adder pcAdderModule(
    .in1(pcout),
    .in2(c_imm),
    .out(addrout)
  );
  wire [31:0] pcmuxout;
  multiplexer2to1 pcMultiplexerModule(
    .sel(c_pcsel),
    .in1(incrout),
    .in2(executebuffer4),
    .out(pcmuxout)
  );
  wire [31:0] rs1;
  wire [31:0] rs2;
  registerBank registerBankModule(
    .clk(clk),
    .regwrite(c_regwrite),
    .rdaddr(c_rd),
    .rddata(writebackbuffer),
    .rs1addr(c_rs1),
    .rs2addr(c_rs2),
    .rs1(rs1),
    .rs2(rs2)
  );
  wire [31:0] alu1muxout;
  multiplexer2to1 alu1MultiplexerModule(
    .sel(c_alu1sel),
    .in1(rs1),
    .in2(pcout),
    .out(alu1muxout)
  );
  wire [31:0] alu2muxout;
  multiplexer2to1 alu2MultiplexerModule(
    .sel(c_alu2sel),
    .in1(rs2),
    .in2(c_imm),
    .out(alu2muxout)
  );

  // ** EXECUTE **
  wire [31:0] ir2out;
  buffer ir2BufferModule(
    .clk(clk),
    .in(ir1out),
    .out(ir2out)
  );
  wire [6:0] c_opcode;
  wire [2:0] c_funct3;
  wire [6:0] c_funct7;
  instructionDecoder instruction2DecoderModule(
    .ins(ir2out),
    .opcode(c_opcode),
    .funct3(c_funct3),
    .funct7(c_funct7)
  );
  wire [31:0] executebuffer1;
  buffer executeBuffer1Module(
    .clk(clk),
    .in(alu1muxout),
    .out(executebuffer1)
  );
  wire [31:0] executebuffer2;
  buffer executeBuffer2Module(
    .clk(clk),
    .in(alu2muxout),
    .out(executebuffer2)
  );
  wire [31:0] executebuffer3;
  buffer executeBuffer3Module(
    .clk(clk),
    .in(rs2),
    .out(executebuffer3)
  );
  wire [31:0] executebuffer4;
  buffer executeBuffer4Module(
    .clk(clk),
    .in(addrout),
    .out(executebuffer4)
  );
  wire [31:0] aluout;
  wire zero;
  alu aluModule(
    .funct3(c_funct3),
    .funct7(c_funct7),
    .opcode(c_opcode),
    .in1(executebuffer1),
    .in2(executebuffer2),
    .zero(zero),
    .out(aluout)
  );

  // ** MEMORY ** 
  wire [31:0] ir3out;
  buffer ir3BufferModule(
    .clk(clk),
    .in(ir2out),
    .out(ir3out)
  );
  wire [1:0] c_memsel;
  wire c_memwrite;
  instructionDecoder instruction3DecoderModule(
    .ins(ir3out),
    .memsel(c_memsel),
    .memwrite(c_memwrite)
  );
  wire [31:0] memorybuffer1;
  buffer memoryBuffer1Module(
    .clk(clk),
    .in(aluout),
    .out(memorybuffer1)
  );
  wire [31:0] memorybuffer2;
  buffer memoryBuffer2Module(
    .clk(clk),
    .in(executebuffer3),
    .out(memorybuffer2)
  );
  wire [31:0] memout;
  dataMemory datamemoryModule(
    .clk(clk),
    .memwrite(c_memwrite),
    .address(memorybuffer1),
    .datain(memorybuffer2),
    .dataout(memout)
  );
  wire [31:0] memmuxout;
  multiplexer4to1 memMultiplexerModule(
    .sel(c_memsel),
    .in1(memout),
    .in2(memorybuffer1),
    .in3(memorybuffer3),
    .out(memmuxout)
  );
  // ** WRITE BACK **
  wire [31:0] ir4out;
  buffer ir4BufferModule(
    .clk(clk),
    .in(ir3out),
    .out(ir4out)
  );
  wire c_regwrite;
  wire [4:0] c_rd;
  instructionDecoder instruction4DecoderModule(
    .ins(ir4out),
    .regwrite(c_regwrite),
    .rd(c_rd)
  );
  wire [31:0] writebackbuffer;
  buffer writebackBufferModule(
    .clk(clk),
    .in(memmuxout),
    .out(writebackbuffer)
  );
endmodule









