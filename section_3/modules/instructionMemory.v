module instructionMemory(
  input [31:0] address,
  output [31:0] instruction
);
  reg [31:0] imem [0:`imemsize - 1]; 
  assign instruction = imem[address/4];

  always @(instruction) begin
    if (instruction == 32'hc0001073) // if it reaches unimp, it has worked
      $display("**** PASSED ****");
  end

  // not synthesizable
  integer i = 0;
  initial begin
    // load instructions into instruction memory
    $readmemh("mytests/beq-res.txt", imem);
    $display("INSTRUCTION MEMORY:");
    for (i=0;i<(`imemsize-1)/4;i=i+3) begin
      $display("%-03h : %-8h  %-8h  %-8h  %-8h", i*4, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      i = i + 1;
    end
  end
endmodule