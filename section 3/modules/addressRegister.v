module addressRegister (
  input clk,
  // control
  input write,
  input in1on,
  input in2on,
  input in3on,
  input out1on,
  //input wire out2on,

  input [31:0] in1, // alu bus 
  input [31:0] in2, // incrementer bus
  input [31:0] in3, // pc bus 
 
  output [31:0] out1, // out to memory 
  output [31:0] out2 // out to address incrementer
);
  reg [31:0] areg;

  // out
  assign out1 = out1on ? areg : 32'bz;
  assign out2 = areg;

  always @ (posedge clk) begin
  // write
    if (in3on) areg <= in3;
    else areg <= in2;
  end

  initial begin
    areg <= 0; // todo add to reset
  end
  endmodule