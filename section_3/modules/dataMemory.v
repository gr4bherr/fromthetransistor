module dataMemory(
  input clk,
  input memwrite,
  input [31:0] address,
  input [31:0] datain,
  output [31:0] dataout
);
  reg [31:0] dmem [0:1023]; // 1 KB
  reg [31:0] buffer;

  assign dataout = buffer;

  always @(posedge clk) begin
    buffer <= dmem[address];
    if (memwrite) begin
      dmem[address] <= datain;
    end
  end

endmodule