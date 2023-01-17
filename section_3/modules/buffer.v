module buffer(
  input clk,
  input [31:0] in,
  output [31:0] out
); 
  reg [31:0] buffer;
  assign out = buffer;

  always @(posedge clk) buffer <= in;
endmodule