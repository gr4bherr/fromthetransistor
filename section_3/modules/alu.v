module alu(
  input [2:0] funct3,
  input [6:0] opcode,
  input [6:0] funct7,
  input [4:0] shamt,
  input [31:0] in1,
  input [31:0] in2,
  output reg zero,
  output reg [31:0] out
);
  always @(*) begin
    zero = 0;
     // arithmetic & logical
    if (opcode == `op_r | opcode == `op_i) begin
      case (funct3)
        `ADD_SUB: // add, sub
          out = funct7 == 7'b0 ? in1 + in2 : in1 - in2;
        `SLL: // shift left logical
          out = in1 << in2 & 32'hffffffff;
        `SLT: // set less than
          out = in1 < in2 ? 32'b1 : 32'b0; 
        `SLTU: // set less than unsigned
          // todo what is unsigned here
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
    end else if (opcode == `op_j | opcode == `op_i_jalr) begin
      zero = 1;
    // branch
    end else if (opcode == `op_b) begin
      case (funct3) 
        `BEQ: begin
          if (in1 == in2) zero = 1;
          else zero = 0;
        end `BNE: begin
          if (in1 != in2) zero = 1;
          else zero = 0;
        end `BLT: begin
          if (in1 >= in2) zero = 1;
          else zero = 0;
        end `BGE: begin
          if (in1 >= in2) zero = 1;
          else zero = 0;
        end `BLTU: begin // todo add unsigned
          if (in1 < in2) zero = 1; 
          else zero = 0;
        end `BGEU: begin
          if (in1 < in2) zero = 1;
          else zero = 0;
        // jump (unconditional)
        end default: zero = 1;
      endcase
    // lui
    end else if (opcode == `op_u) begin
      out = in2 << shamt;
    // auipc
    end else if (opcode == `op_u_pc) begin
      out = (in1 + in2) << shamt;
    end
  end
endmodule