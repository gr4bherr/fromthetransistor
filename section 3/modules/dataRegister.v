module dataRegister (
  input clk,
  input wire inon,
  input wire outon,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  reg [31:0] datareg;
  assign dataout = outon ? datareg : 32'bz;
  always @ (posedge clk) begin
    if (inon) datareg <= datain;
  end
endmodule