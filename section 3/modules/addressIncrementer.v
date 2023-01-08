module addressIncrementer (
  // control
  input increment,
  input [31:0] datain,
  output [31:0] dataout
);
  assign dataout = increment ? datain + 4 : 32'bz;
endmodule