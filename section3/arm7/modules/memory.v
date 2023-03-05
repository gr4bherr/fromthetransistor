module memory(
  input clk,
  input write,
  input out,
  input [31:0] address,
  inout [31:0] data
);
  reg [31:0] mem [0:63]; // 64 * 4 bytes
  integer i;
  reg [31:0] buffer; //
  // load
  assign data = out ? buffer : 32'bz;

  initial begin
    // initial store into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) $display("M: %0h %h",i , mem[i]);
  end

  always @ (posedge clk) begin
    //$display(buffer);
    if (write) mem[address / 4] <= data;
    buffer <= mem[address / 4];
  end
endmodule