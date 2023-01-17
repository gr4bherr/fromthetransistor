module registerBank(
  input clk,
  input regwrite,
  input [4:0] rdaddr,
  input [31:0] rddata,
  input [4:0] rs1addr,
  input [4:0] rs2addr,
  output [31:0] rs1,
  output [31:0] rs2
);
  reg [31:0] regs [0:31];

  assign rs1 = regs[rs1addr];
  assign rs2 = regs[rs2addr];

  always @(posedge clk) begin
    if (regwrite) begin
      regs[rdaddr] <= rddata;
    end
  end

  initial regs[0] <= 32'b0;

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
  reg [31:0] reg17;
  reg [31:0] reg18;
  reg [31:0] reg19;
  reg [31:0] reg20;
  reg [31:0] reg21;
  reg [31:0] reg22;
  reg [31:0] reg23;
  reg [31:0] reg24;
  reg [31:0] reg25;
  reg [31:0] reg26;
  reg [31:0] reg27;
  reg [31:0] reg28;
  reg [31:0] reg29;
  reg [31:0] reg30;
  reg [31:0] reg31;
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
    reg17 = regs[17];
    reg18 = regs[18];
    reg19 = regs[19];
    reg20 = regs[20];
    reg21 = regs[21];
    reg22 = regs[22];
    reg23 = regs[23];
    reg24 = regs[24];
    reg25 = regs[25];
    reg26 = regs[26];
    reg27 = regs[27];
    reg28 = regs[28];
    reg29 = regs[29];
    reg30 = regs[30];
    reg31 = regs[31];
  end
endmodule