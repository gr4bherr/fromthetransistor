module pcRegister(
  input clk,
  input [31:0] in,
  output [31:0] out
);
  reg [31:0] pc = 0;
  assign out = pc;
  always @(posedge clk) begin
    pc <= in;
  end
endmodule