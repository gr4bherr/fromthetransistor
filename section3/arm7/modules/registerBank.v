module registerBank (
  input clk, 
  input write,
  input in1on,
  input in2on,
  input pcchange,
  input writeback,
  input cpsrwrite,

  input [31:0] alubusin,
  input [31:0] incrbusin,
  input [3:0] rm,
  input [3:0] rn,
  input [3:0] rs,
  input [3:0] rd,
  input [3:0] flagsin,
  output [3:0] flagsout,
  output [31:0] abusout, // rn
  output [31:0] bbusout, // rm
  output [7:0] barrelshifterout, // (rs) shiftamountreg 
  output [31:0] pcbusout
);
  // using 16 base registers + cpsr
  reg [31:0] regs [0:31];

  assign flagsout = regs[`CPSR][31:28];
  assign abusout = regs[rn];
  assign bbusout = regs[rm];
  assign barrelshifterout = regs[rs][7:0];
  assign pcbusout = regs[`PC];

  // write on falling edge
  always @ (negedge clk) begin
    //$display(regs[`PC]);
    // todo
    //if (write) begin
      //if (in1on) regs[rm] <= in1;
      //else if (in2on) regs[rn] <= in2;
    //end

    if (writeback) regs[rd] <= alubusin;
    if (~pcchange) regs[`PC] <= incrbusin;
    if (cpsrwrite) regs[`CPSR] <= {flagsin, regs[`CPSR][27:0]};
  end

  // set modes, my cpu doesn't care about them (just for fun)
  initial begin
    // FIQ disable, IRQ disable, T clear, mode: supervisor
    regs[16] <= 32'b111010011; 
  end

  // just so i can see it gktwave
  reg [31:0] reg0;
  reg [31:0] reg1;
  reg [31:0] reg2;
  reg [31:0] reg3;
  reg [31:0] reg4;
  reg [31:0] reg5;
  reg [31:0] reg6;
  reg [31:0] reg7;
  reg [31:0] reg8;
  reg [31:0] reg9;
  reg [31:0] reg10;
  reg [31:0] reg11;
  reg [31:0] reg12;
  reg [31:0] reg13;
  reg [31:0] reg14;
  reg [31:0] reg15;
  reg [31:0] reg16;
  always @ (*) begin
    reg0 = regs[0];
    reg1 = regs[1];
    reg2 = regs[2];
    reg3 = regs[3];
    reg4 = regs[4];
    reg5 = regs[5];
    reg6 = regs[6];
    reg7 = regs[7];
    reg8 = regs[8];
    reg9 = regs[9];
    reg10 = regs[10];
    reg11 = regs[11];
    reg12 = regs[12];
    reg13 = regs[13];
    reg14 = regs[14];
    reg15 = regs[15];
    reg16 = regs[16];
  end
endmodule