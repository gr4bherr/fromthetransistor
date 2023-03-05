module dataRegister (
  input clk,
  input inon,
  input outon,
  input [31:0] datain,
  output [31:0] dataout
);
  reg [31:0] datareg;
  assign dataout = outon ? datareg : 32'bz;
  always @ (posedge clk) begin
    if (inon) datareg <= datain;
  end
endmodule