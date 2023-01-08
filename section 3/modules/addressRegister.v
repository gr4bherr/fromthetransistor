module addressRegister (
  input wire clk,
  // control
  input wire write,
  input wire in1on,
  input wire in2on,
  input wire in3on,
  input wire out1on,
  //input wire out2on,

  input wire [31:0] in1, // alu bus 
  input wire [31:0] in2, // incrementer bus
  input wire [31:0] in3, // pc bus 
 
  output wire [31:0] out1, // out to memory 
  output wire [31:0] out2 // out to address incrementer
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