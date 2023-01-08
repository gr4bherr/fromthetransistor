module instructionDecoder (
  input [31:0] ins,
  output reg [31:0] control,

  input [3:0] flagsin,

  output reg [31:0] shiftby,
  output reg [1:0] shifttype,
  output reg [3:0] opcode,
  output reg [3:0] rm,
  output reg [3:0] rn,
  output reg [3:0] rd,
  output reg [3:0] rs,
  output reg [7:0] shiftval
);
  initial begin
    control = 0;
  end

  always @ (ins) begin
    control = 32'b0; // todo make into or statements
    // condition check
    if ((ins[31:28] == `EQ & flagsin[`N]) | (ins[31:28] == `NE & ~flagsin[`Z]) | 
        (ins[31:28] == `CS & flagsin[`C]) | (ins[31:28] == `CC & ~flagsin[`C]) | 
        (ins[31:28] == `MI & flagsin[`N]) | (ins[31:28] == `PL & ~flagsin[`N]) | 
        (ins[31:28] == `VS & flagsin[`V]) | (ins[31:28] == `VC & ~flagsin[`V]) |
        (ins[31:28] == `HI & flagsin[`C] & ~flagsin[`Z]) | (ins[31:28] == `LS & ~flagsin[`C] & flagsin[`Z]) | 
        (ins[31:28] == `GE & flagsin[`Z] == flagsin[`V]) | (ins[31:28] == `LT & flagsin[`Z] != flagsin[`V]) | 
        (ins[31:28] == `GT & ~flagsin[`Z] & flagsin[`N] == flagsin[`V]) | (ins[31:28] == `LE & (flagsin[`Z] | flagsin[`N] != flagsin[`V])) | 
        (ins[31:28] == `AL)) begin
      if (ins[27:26] == 2'b00) begin
          if (ins[25] == 1'b0) begin
            // DATA PROCESSING: reg {shift} (1/2) (i = 0)
            if (!(ins[24:23] == 2'b10 & ins[20] == 1'b0) & ((ins[4] == 1'b0) | (ins[7] == 1'b0 & ins[4] == 1'b1))) begin
              // i, opcode, s, rn, rd, shiftam, shift, t, rm
              $display("\tinsnum: 0 (1/2)");
              // cycleone <= 'h0;
              opcode = ins[24:21];
              control[`c_setflags] = ins[20];
              rn = ins[19:16];
              rd = ins[15:12];
              rm = ins[3:0];
              shifttype = ins[6:5];
              // todo use c_shiftbyimm for if statement 
              control[`c_shiftvalimm] = 0;
              control[`c_shiftbyimm] = ~ins[4];
              if (ins[4] == 0)
                shiftby = ins[11:7];
              else
                rs = ins[11:8];
              if (ins[15:12] == `PC) 
                control[`c_pcchange] = 1;
            end else if ((ins[24:23] == 2'b10 & ins[20] == 1'b0) & (ins[7] == 1'b0)) begin
              // PSR TRANSFER: mrs reg, msr reg (1/2)
              if (ins[6:4] == 3'b000) begin
                // i, psr, direction, rd rm
                $display("\tinsnum: 1 (1/2)");
                // cycleone <= 'h1;
              // BRANCH AND EXCHANGE
              end else if (ins[6:4] == 3'b001 & ins[22:21] == 2'b01) begin
                // rn
                $display("\tinsnum: 5");
                // cycleone <= 'h5;
              end 
            end else if (ins[24] == 1'b0 & ins[7:4] == 4'b1001) begin
              // MULTIPLY
              if (ins[23:22] == 2'b00) begin
                // a, s, rd, rn, rs, rm
                $display("\tinsnum: 2");
                // cycleone <= 'h2;
              // MULTIPLY LONG
              end else if (ins[23] == 1'b1) begin
                //u, a, s, rdhi, rdlo, rs, rm
                $display("\tinsnum: 3");
                // cycleone <= 'h3;
              end
            // HALF WORD DATA TRANSFER
            end else if (!(ins[24] == 1'b0 & ins[21] == 1'b1) | (ins[24] == 1'b0 & ins[21:20] == 2'b10) & (ins[7:4] == 4'b1011 | ins[7:4] == 4'b1101 | ins[7:4] == 4'b1111)) begin
              // p, u, i, w, l ,rn, rd, off1, sh, off2,
              $display("\tinsnum: 6 or 7");
              // cycleone <= 'h67; // 6 or 7
            // SINGLE DATA SWAP
            end else if (((ins[24:23] == 2'b10 & ins[21:20] == 2'b00) & ins[10:4] == 8'b00001001)) begin
              // b, rn, rd, rm
              $display("\tinsnum: 4");
              // cycleone <= 'h4;
            end
          end else if (ins[25] == 1'b1) begin
            // DATA PROCESSING: imm (2/2) (i = 1)
            if (!(ins[24:23] == 2'b10 & ins[20] == 1'b0)) begin 
              // i, opcode, s, rn, rd, rotate, imm
              $display("\tinsnum: 0 (2/2)");
              // i, opcode, s, rn, rd, rotate, imm
              // cycleone <= 0;
              opcode = ins[24:21];
              control[`c_setflags] = ins[20];
              rn = ins[19:16];
              rd = ins[15:12];
              shiftby = ins[11:8] * 2; // rotate by
              shifttype = 2'b11;
              shiftval = ins[7:0];
              control[`c_shiftvalimm] = 1;
              control[`c_shiftbyimm] = 1;
              if (ins[15:12] == `PC) 
                control[`c_pcchange] = 1;
            // PSR TRANSFER: msr imm (2/2)
            end else if (ins[24:23] == 2'b10 & ins[21:20] == 2'b10) begin 
              // i, p, u, b, w, l, rn, rd
              $display("\tinsnum: 1 (2/2)");
              // cycleone <= 1;
            end
          end
      // SINGLE DATA TRANSFER 
      end else if (ins[27:26] == 2'b01) begin
        //todo
        // i, p, u, b, w, l, rn, rd, (imm / shiftam, shift, rm)
        $display("\tinsnum: 8");
        // cycleone <= 'h8;
      end else if (ins[27:26] == 2'b10) begin
          // BLOCK DATA TRANSFER
          if (ins[25] == 1'b0) begin
            // p, u, s, w, l, rn, reglist
            $display("\tinsnum: a");
            // cycleone <= 'ha;
          // BRANCH
          end else if (ins[25] == 1'b1) begin
            // l, offset
            $display("\tinsnum: b");
            // cycleone <= 'hb;
          end
      end else if (ins[27:26] == 2'b11) begin
        // UNDEFINED
        if (ins[25:21] == 5'b00000) begin
            $display("\tinsnum: 9");
            // cycleone <= 'h9;
        // SOFTWARE INTERRUPT
        end else if (ins[25:20] == 6'b110000) begin
            $display("\tinsnum: f");
            // cycleone <= 'hf;
        end 
        // COPROCESSOR...
      end else begin
          // not valid instruction
          $display("\tinvalid instruction");
      end
    end
    //$display("\tcontrol signal: %0h", cycleone);
  end
endmodule