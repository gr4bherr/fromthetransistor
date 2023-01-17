module alu(
  input [2:0] funct3,
  input [6:0] opcode, // maybe needed jsut for mux
  input [6:0] funct7,
  input [31:0] in1,
  input [31:0] in2,
  output reg [31:0] out
);
  always @(*) begin
    case (funct3)
      `ADD_SUB: // add, sub
        out = funct7 == 7'b0 ? in1 + in2 : in1 - in2;
      `SLL: // shift left logical
        out = in1 << in2 & 32'hffffffff;
      `SLT: // set less than
        out = in1 < in2 ? 32'b1 : 32'b0; // todo maybe 32'hffffffff
      `SLTU: // set less than unsigned
        // todo what is unsigned here
        out = in1 < in2 ? 32'b1 : 32'b0; // todo maybe 32'hffffffff
      `XOR:
        out = in1 ^ in2;
      `SRL_SRA: // shift right logical, arithmetic
        out = funct7 == 7'b0 ? in1 >> in2 : in1 >>> in2;
      `OR:
        out = in1 | in2;
      `AND:
        out = in1 & in2;
    endcase
  end
endmodule