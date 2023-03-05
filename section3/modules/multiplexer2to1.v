module multiplexer2to1(
  input sel,
  input [31:0] in1,
  input [31:0] in2,
  output reg [31:0] out
);
  always @(*) begin
    case (sel)
      1'b0: out = in1;
      1'b1: out = in2;
    endcase
  end
endmodule