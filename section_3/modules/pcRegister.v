module pcRegister(
  input clk,
  input reset,
  input [31:0] in,
  output [31:0] out
);
  reg [31:0] pc = 0;
  assign out = pc;
  integer i = 0; // todo not pipelined
  always @(posedge clk) begin
    //$display("%h", pc);
    // if (reset) begin
    //   pc <= 0;
    // end
    // else begin
    i = i + 1;
    if (i % 5 == 0)
      pc <= in;
    // end
  end
endmodule