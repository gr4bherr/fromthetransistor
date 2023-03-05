module control(
  input [31:0] ins,
  // ir1 - decode
  output reg [4:0] rs1,
  output reg [4:0] rs2,
  output reg [31:0] imm,
  // ir2 - execute
  output reg [6:0] opcode,
  output reg [2:0] funct3,
  output reg [6:0] funct7,
  // ir3 - memory
  output reg memwrite, 
  output reg [1:0] memarea, // 0: byte, 1: half word, 2: word
  output reg [1:0] memsel, // 0: pc + 4, 1: mem, 2: alu
  // ir4 - write back
  output reg regwrite,
  output reg [4:0] rd
);
  always @(*) begin
    // execute
    opcode = ins[6:0];
    funct3 = (opcode != `op_u & opcode != `op_u_pc & opcode != `op_j) ? ins[14:12] : 32'bz;
    funct7 = ins[31:25];
    // decode
    rs1 = (opcode != `op_u & opcode != `op_u_pc & opcode != `op_j) ? ins[19:15] : 32'bz;
    rs2 = (opcode == `op_b | opcode == `op_s | opcode == `op_r) ? ins[24:20] : 32'bz;
    case (opcode)
    `op_u, `op_u_pc: imm = ins[31:12];
    `op_j: imm = {ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};
    `op_i_jalr, `op_i_load: imm = ins[31:20];
    `op_i: begin
      if (funct3 == `SLL | funct3 == `SRL_SRA) imm = ins[24:20];
      else imm = ins[31:20];
    end
    `op_b: imm = {ins[31], ins[7], ins[30:25], ins[11:8], 1'b0};
    `op_s: imm = {ins[31:25], ins[11:7]};
    `op_r: imm = 32'bz;
    endcase
    // memory
    memwrite = (opcode == `op_s) ? 1'b1 : 1'b0;
    if (opcode == `op_i_load | opcode == `op_s) begin
      case (funct3)
      3'b000, 3'b100: memarea = 2'b0;
      3'b001, 3'b101: memarea = 2'b1;
      3'b010: memarea = 2'b01;
      endcase
    end else memarea = 2'bz;
    if (opcode == `op_j | opcode == `op_i_jalr) memsel = 2'b0;
    else if (opcode == `op_i_load) memsel = 2'b1;
    else memsel = 2'b10;
    // write back
    regwrite = (opcode != `op_b & opcode != `op_s) ? 1'b1 : 1'b0;
    rd = (opcode != `op_b & opcode != `op_s) ? ins[11:7] : 32'bz;
  end
endmodule