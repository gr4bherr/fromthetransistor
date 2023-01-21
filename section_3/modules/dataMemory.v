module dataMemory(
  input clk,
  input write,
  input [1:0] area,
  input [31:0] address,
  input [31:0] datain,
  output [31:0] dataout
);
  reg [31:0] dmem [0:`dmemsize - 1]; // 1 KB

  assign dataout = dmem[address][2 ** (3 + area) - 1];

  always @(posedge clk) begin
    if (write) begin
      dmem[address] <= datain[2 ** (3 + area) - 1];
    end
  end

endmodule