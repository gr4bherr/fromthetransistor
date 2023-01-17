module instructionMemory(
  input [31:0] address,
  output [31:0] instruction
);
  reg [31:0] imem [0:`imemsize-1]; // 1 KB
  assign instruction = imem[address/4];

  // not synthesizable
  integer i = 0;
  initial begin
    // load instructions into instruction memory
    $readmemh("mytests/simple-res.txt", imem);
    $display("INSTRUCTION MEMORY:");
    for (i=0;i<(`imemsize-1)/4;i=i+3) begin
    //while (imem[i] != 32'hc0001073) begin
      $write("%-03h : %-8h  %-8h  %-8h  %-8h", i*4+(`imemsize/4)*0, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      $write("  %-03h : %-8h  %-8h  %-8h  %-8h", i*4+(`imemsize/4)*1, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      $write("  %-03h : %-8h  %-8h  %-8h  %-8h", i*4+(`imemsize/4)*2, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      $display("  %-03h : %-8h  %-8h  %-8h  %-8h", i*4+(`imemsize/4)*3, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      i = i + 1;
    end
  end
endmodule