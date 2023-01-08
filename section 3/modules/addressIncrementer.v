module addressIncrementer (
  // control
  input wire increment,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  assign dataout = increment ? datain + 4 : 32'bz;
endmodule