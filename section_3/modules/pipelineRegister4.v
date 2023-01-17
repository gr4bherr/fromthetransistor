module pipelineRegister4(
  input clk,
  input [31:0] in1,
  output [31:0] out1);
  reg [31:0] reg1;
  assign out1 = reg1;
  always @(posedge clk) begin
    reg1 <= in1;
  end
endmodule
  