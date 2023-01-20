// todo might implement this later differently
module branchCondition(
  input [31:0] addrout,
  input [31:0] rs1,
  input [31:0] rs2
  input [6:0] opcode,
  input [4:0] funct3,
  output reg sel,
  output reg [31:0] out
);
  // jar | jalr
  if (opcode == 7'b1101111 | opcode == 7'b1100111)
    out = addrout;
    sel = 1'b1;
  // branch
  else if (opcode = 7'1100011) begin
    out = addrout;
    case (funct3)
      `BEQ: begin
        if (rs1 == rs2) sel = 1'b1;
        else sel = 1'b0;
      end `BNE: begin
        if (rs1 != rs2) sel = 1'b1;
        else sel = 1'b0;
      end `BLT: begin
        if (rs1 >= rs2) sel = 1'b1;
        else sel = 1'b0;
      end `BGE: begin // todo unsigned
        if (rs1 >= rs2) sel = 1'b1;
        else sel = 1'b0;
      end `BLTU: begin 
        if (rs1 < rs2) sel = 1'b1;
        else sel = 1'b0;
      end `BGEU: begin // todo unsigned and shift
        if (rs1 < rs2) sel = 1'b1;
        else sel = 1'b0;
      end
    endcase
  end
  // other
  else sel = 0'b1
endmodule