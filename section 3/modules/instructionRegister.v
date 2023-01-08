//instruction pipeline & read data register (& thumb instruction decoder)
module instructionRegister (
  input clk,
  input inon,
  input out1on,
  input [31:0] datain,
  output [31:0] dataout1, // b bus
  output [31:0] dataout2 // instruction decoder
);

  assign dataou1 = out1on ? ireg : 32'bz;
  assign dataout2 = ireg;

  reg [31:0] ireg;
  always @ (posedge clk) begin
    if (inon) ireg <= datain;
  end
endmodule