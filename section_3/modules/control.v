module control(
  input [31:0] ins,
  // control signals
  output reg pcsel, // 0: incr, 1: imm, ...
  output reg alu1sel, // 0: rs1, 1: pc
  output reg alu2sel, // 0: rs2, 1: imm
  output reg [1:0] memsel, // 0: mem, 1: alu
  output reg regwrite,
  output reg memwrite, 
  //output immSel,
  output reg [6:0] opcode,
  output reg [2:0] funct3, // todo check if no problem with u,i type ins
  output reg [6:0] funct7,
  output reg [4:0] rs1,
  output reg [4:0] rs2,
  output reg [4:0] rd,
  output reg [31:0] imm,
  output reg [4:0] shamt
);
  always @(*) begin
    opcode = ins[6:0];
    funct3 = ins[14:12];
    funct7 = ins[31:25];
    pcsel = 2'b0;
    alu1sel = 1'b0;
    alu2sel = 1'b0;
    regwrite = 1'b0;

    case (opcode)
      `op_r: begin
        rd = ins[11:7];
        rs1 = ins[19:15];
        rs2 = ins[24:20]; // todo shamt
      end
      `op_i_load, `op_i, `op_i_jalr: begin
        rd = ins[11:7];
        rs1 = ins[19:15];
        imm = ins[31:20];
        alu1sel = 1'b0;
        alu2sel = 1'b1;
        memsel = 2'b10;
        regwrite = 1'b1;
      end
      `op_s: begin
        rs1 = ins[19:15];
        rs2 = ins[24:20];
        imm = ins[31:25];
      end
      `op_b: begin
        rs1 = ins[19:15];
        rs2 = ins[24:20];
        imm = {ins[31], ins[7], ins[30:25], ins[11:8]};
      end
      `op_u, `op_u_pc: begin
        rd = ins[11:7];
        imm = ins[31:12];
        alu1sel = 1'b1;
        alu2sel = 1'b1;
        shamt = 5'd12;
      end
      `op_j: begin
        rd = ins[11:7];
        imm = {ins[31], ins[19:12], ins[20], ins[30:21]} * 2;
        pcsel = 1'b1;
        regwrite = 1'b1;
      end
      // `op_fence, `op_csr: begin
      //   $display("instruction not implemented");
      // end
    endcase
  end
endmodule