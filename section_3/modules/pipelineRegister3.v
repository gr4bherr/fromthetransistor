module pipelineRegister3(
  input clk,
  input [31:0] in1,
  input [31:0] in2,
  output [31:0] out1,
  output [31:0] out2
);
  reg [31:0] reg1;
  reg [31:0] reg2;
  assign out1 = reg1;
  assign out2 = reg2;
  always @(posedge clk) begin
    reg1 <= in1;
    reg2 <= in2;
  end
endmodule
  