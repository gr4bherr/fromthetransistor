module alu(
  input [2:0] funct3,
  input [6:0] opcode,
  input [6:0] funct7,
  input [31:0] pc,
  input [31:0] rs1,
  input [31:0] rs2,
  input [31:0] imm,
  output reg zero,
  output reg [31:0] out
);
  always @(*) begin
    //zero = (opcode == `op_b | opcode == `op_j | opcode == `op_i_jalr) ? 1'b1 : 1'b0;

    // zeroextend: sltu, sltiu, lbu, lhu, bgeu, bltu
    // (op_i | op_r) & `SLTU; op_i_load & (100 | 101); op_b & (110 | 111)
    // signextend: sra, srai, 
    // (op_i | op_r) & srl_sra & 0100000

    zero = 0;
     // arithmetic & logical
    case (opcode)
    `op_r: begin
      case (funct3) // todo add imm
      `ADD_SUB: out = funct7 == 7'b0 ? rs1 + rs2 : rs1 - rs2;
      `SLL: out = rs1 << rs2 & 32'hffffffff;
      `SLT: out = $signed(rs1) < $signed(rs2) ? 32'b1 : 32'b0; 
      `SLTU: out = rs1 < rs2 ? 32'b1 : 32'b0; 
      `XOR: out = rs1 ^ rs2;
      `SRL_SRA: out = funct7 == 7'b0 ? rs1 >> rs2 : rs1 >>> rs2;
      `OR: out = rs1 | rs2;
      `AND: out = rs1 & rs2;
      endcase
    end `op_i: begin
      case (funct3) // todo add imm
      `ADD_SUB: out = funct7 == 7'b0 ? rs1 + imm : rs1 - imm;
      `SLL: out = rs1 << imm & 32'hffffffff;
      `SLT: out = $signed(rs1) < $signed(imm) ? 32'b1 : 32'b0; 
      `SLTU: out = rs1 < imm ? 32'b1 : 32'b0; 
      `XOR: out = rs1 ^ imm;
      `SRL_SRA: out = funct7 == 7'b0 ? rs1 >> imm : rs1 >>> imm;
      `OR: out = rs1 | imm;
      `AND: out = rs1 & imm;
      endcase
    // jal, jalr
    end `op_j: begin
      zero = 1;
      out = pc + imm;
    end
    `op_i_jalr: begin
      zero = 1;
      out = rs1 + imm;
    end
    // branch
    `op_b: begin
      out = pc + imm;
      case (funct3) 
      `BEQ: begin
        if (rs1 == rs2) zero = 1;
        else zero = 0;
      end `BNE: begin
        if (rs1 != rs2) zero = 1;
        else zero = 0;
      end `BLT: begin
        if ($signed(rs1) < $signed(rs2)) zero = 1;
        else zero = 0;
      end `BGE: begin
        if ($signed(rs1) >= $signed(rs2)) zero = 1;
        else zero = 0;
      end `BLTU: begin
        if (rs1 < rs2) zero = 1; 
        else zero = 0;
      end `BGEU: begin
        if (rs1 >= rs2) zero = 1;
        else zero = 0;
      end
      endcase
    end
    // lui
    `op_u:
      out = imm << 12;
    // auipc
    `op_u_pc:
      out = pc + (imm << 12);
    // memory
    `op_i_load, `op_s:
      out = rs1 + imm;
    endcase
  end
endmodule