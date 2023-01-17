module multiplexer4to1(
  input [1:0] sel,
  input [31:0] in1,
  input [31:0] in2,
  input [31:0] in3,
  input [31:0] in4,
  output reg [31:0] out
);
  always @(*) begin
    case(sel)
      // default pc + 4
      2'b00, 2'bx: // todo: not sure if 2'bx is allowed
        out = in1;
      // pc + 4 - 4+ imm // todo: fuck incrementer
      2'b01: 
        out = in1 - 4 + in2;
      2'b10:
        out = in3;
      2'b11:
        out = in4;
    endcase
  end
endmodule