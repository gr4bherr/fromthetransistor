module alu (
  input [3:0] opcode,
  input setflags,
  input [31:0] dataina,
  input [31:0] datainb,
  input [3:0] flagsin,
  output reg writeback,
  output reg [31:0] dataout,
  output reg [3:0] flagsout
);
  always @ (*) begin
    case (opcode)
      `AND: begin
        dataout = dataina & datainb;
        writeback = 1;
      end `EOR: begin
        dataout = dataina ^ datainb;
        writeback = 1;
      end `SUB: begin
        dataout = dataina - datainb;
        writeback = 1;
      end `RSB: begin 
        dataout = datainb - dataina;
        writeback = 1;
      end `ADD: begin 
        dataout = dataina + datainb;
        writeback = 1;
      end `ADC: begin
        dataout = dataina + datainb + flagsin[`C];
        writeback = 1;
      end `SBC: begin 
        dataout = dataina - datainb + flagsin[`C];
        writeback = 1;
      end `RSC: begin
        dataout = datainb - dataina + flagsin[`C];
        writeback = 1;
      end `TST: begin
        dataout = dataina & datainb;
        writeback = 0;
      end `TEQ: begin
        dataout = dataina ^ datainb;
        writeback = 0;
      end `CMP: begin
        dataout = dataina - datainb;
        writeback = 0;
      end `CMN: begin
        dataout = dataina + datainb;
        writeback = 0;
      end `ORR: begin
        dataout = dataina | datainb;
        writeback = 1;
      end `MOV: begin
        dataout = datainb;
        writeback = 1;
      end `BIC: begin
        dataout = dataina & ~datainb;
        writeback = 1;
      end `MVN: begin
        dataout = ~datainb;
        writeback = 1;
      end
    endcase

    // set flags
    if (setflags | opcode == `TST | opcode == `TEQ | opcode == `CMP | opcode == `CMN) begin
      // N
      if (dataout[31] == 1) flagsout = flagsin | 4'b1000;
      else flagsout = flagsin & 4'b0111;
      // Z
      if (dataout == 0) flagsout = flagsin | 4'b0100;
      else flagsout = flagsin & 4'b1011;
      // C
      // sub
      if (opcode == `SUB | opcode == `RSB | opcode == `SBC | opcode == `RSC | opcode == `CMP) begin
        if (dataina < datainb) flagsout = flagsin | 4'b0010;
        else flagsout = flagsin & 4'b1101;
      end
      // add 
      if (opcode == `ADD | opcode == `ADC | opcode == `CMN) begin
        if (dataina[31] == 1 & datainb[31] == 1) flagsout = flagsin | 4'b0010;
        else flagsout = flagsin & 4'b1101;
      end
      // V
      // sub or add
      if (opcode == `SUB | opcode == `RSB | opcode == `ADD | opcode == `ADC | opcode == `SBC | opcode == `RSC | opcode == `CMP) begin
        // signed overflow
        if (dataina[31] == 0 & datainb[31] == 0 & dataout[31] == 1) flagsout = flagsin | 4'b0001;
        else flagsout = flagsin & 4'b1110;
      end
    end
    //else 
    //flagsout =//
  end
endmodule