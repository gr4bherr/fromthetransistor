module buffer(
  input clk,
  input [31:0] in0, // ir
  input [31:0] in1,
  input [31:0] in2,
  input [31:0] in3,
  input [31:0] in4,
  input [31:0] in5,
  output [31:0] out0,
  output [31:0] out1,
  output [31:0] out2,
  output [31:0] out3,
  output [31:0] out4,
  output [31:0] out5
); 
  reg [31:0] buffer0;
  reg [31:0] buffer1;
  reg [31:0] buffer2;
  reg [31:0] buffer3;
  reg [31:0] buffer4;
  reg [31:0] buffer5;

  assign out0 = buffer0;
  assign out1 = buffer1;
  assign out2 = buffer2;
  assign out3 = buffer3;
  assign out4 = buffer4;
  assign out5 = buffer5;

  always @(posedge clk) begin
    buffer0 <= in0;
    buffer1 <= in1;
    buffer2 <= in2;
    buffer3 <= in3;
    buffer4 <= in4;
    buffer5 <= in5;
  end
endmodule