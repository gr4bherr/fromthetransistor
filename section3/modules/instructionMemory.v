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
    case (`TEST)
    0:  $readmemh("mytests/add-res.txt", imem);
    1:  $readmemh("mytests/addi-res.txt", imem);
    2:  $readmemh("mytests/and-res.txt", imem);
    3:  $readmemh("mytests/andi-res.txt", imem);
    4:  $readmemh("mytests/auipc-res.txt", imem);
    5:  $readmemh("mytests/beq-res.txt", imem);
    6:  $readmemh("mytests/bge-res.txt", imem);
    7:  $readmemh("mytests/bgeu-res.txt", imem);
    8:  $readmemh("mytests/blt-res.txt", imem);
    9:  $readmemh("mytests/bltu-res.txt", imem);
    10: $readmemh("mytests/bne-res.txt", imem);
    11: $readmemh("mytests/fence_i-res.txt", imem); // not gonna pass
    12: $readmemh("mytests/jal-res.txt", imem);
    13: $readmemh("mytests/jalr-res.txt", imem);
    14: $readmemh("mytests/lb-res.txt", imem);
    15: $readmemh("mytests/lbu-res.txt", imem);
    16: $readmemh("mytests/lh-res.txt", imem);
    17: $readmemh("mytests/lhu-res.txt", imem);
    18: $readmemh("mytests/lui-res.txt", imem);
    19: $readmemh("mytests/lw-res.txt", imem);
    20: $readmemh("mytests/or-res.txt", imem);
    21: $readmemh("mytests/ori-res.txt", imem);
    22: $readmemh("mytests/sb-res.txt", imem);
    23: $readmemh("mytests/sh-res.txt", imem);
    24: $readmemh("mytests/simple-res.txt", imem);
    25: $readmemh("mytests/sll-res.txt", imem);
    26: $readmemh("mytests/slli-res.txt", imem);
    27: $readmemh("mytests/slt-res.txt", imem);
    28: $readmemh("mytests/slti-res.txt", imem);
    29: $readmemh("mytests/sltiu-res.txt", imem);
    30: $readmemh("mytests/sltu-res.txt", imem);
    31: $readmemh("mytests/sra-res.txt", imem);
    32: $readmemh("mytests/srai-res.txt", imem);
    33: $readmemh("mytests/srl-res.txt", imem);
    34: $readmemh("mytests/srli-res.txt", imem);
    35: $readmemh("mytests/sub-res.txt", imem);
    36: $readmemh("mytests/sw-res.txt", imem);
    37: $readmemh("mytests/xor-res.txt", imem);
    38: $readmemh("mytests/xori-res.txt", imem);
    endcase
    $display("**** TEST:%2d ****", `TEST);
    //$display("INSTRUCTION MEMORY:");
    for (i=0;i<(`imemsize-1)/4;i=i+3) begin
      //$display("%-03h : %-8h  %-8h  %-8h  %-8h", i*4, imem[i], imem[i+1], imem[i+2], imem[i+3]);
      i = i + 1;
    end
  end
endmodule