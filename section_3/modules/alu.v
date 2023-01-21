module alu(
  input [2:0] funct3,
  input [6:0] opcode,
  input [6:0] funct7,
  input [31:0] in1,
  input [31:0] in2,
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
    `op_r, `op_i: begin
      case (funct3)
      `ADD_SUB: // add, sub
        out = funct7 == 7'b0 ? in1 + in2 : in1 - in2;
      `SLL: // shift left logical
        out = in1 << in2 & 32'hffffffff;
      `SLT: // set less than
        out = $signed(in1) < $signed(in2) ? 32'b1 : 32'b0; 
      `SLTU: // set less than unsigned
        out = in1 < in2 ? 32'b1 : 32'b0; 
      `XOR:
        out = in1 ^ in2;
      `SRL_SRA: // shift right logical, arithmetic
        out = funct7 == 7'b0 ? in1 >> in2 : in1 >>> in2;
      `OR:
        out = in1 | in2;
      `AND:
        out = in1 & in2;
      endcase
    // jal, jalr
    end `op_j: begin
      zero = 1;
      out = in1 + in2;
    end
    `op_i_jalr: begin
      zero = 1;
      out = in1 + in2;
    end
    // branch
    `op_b: begin
      case (funct3) 
      `BEQ: begin
        if (in1 == in2) zero = 1;
        else zero = 0;
      end `BNE: begin
        if (in1 != in2) zero = 1;
        else zero = 0;
      end `BLT: begin
        if ($signed(in1) < $signed(in2)) zero = 1;
        else zero = 0;
      end `BGE: begin
        if ($signed(in1) >= $signed(in2)) zero = 1;
        else zero = 0;
      end `BLTU: begin
        if (in1 < in2) zero = 1; 
        else zero = 0;
      end `BGEU: begin
        if (in1 >= in2) zero = 1;
        else zero = 0;
      end
      endcase
    end
    // lui
    `op_u:
      out = in2 << 12;
    // auipc
    `op_u_pc:
      out = in1 + (in2 << 12);
    // memory
    `op_i_load, `op_s:
      out = in1 + in2;
    endcase
  end
endmodule