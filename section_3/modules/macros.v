`define imemsize 1024
// opcode
`define op_r      7'b0110011

`define op_i_load 7'b0000011
`define op_i      7'b0010011
`define op_i_jalr 7'b1100111

`define op_s      7'b0100011
`define op_b      7'b1100011
`define op_u_imm  7'b0110111
`define op_u      7'b0010111
`define op_j      7'b1101111

`define op_fence     7'b0001111
`define op_csr       7'b1110011 // and ecall, ebreak

// funct3
`define ADD_SUB 3'b000
`define SLL     3'b001
`define SLT     3'b010
`define SLTU    3'b011
`define XOR     3'b100
`define SRL_SRA 3'b101
`define OR      3'b110
`define AND     3'b111