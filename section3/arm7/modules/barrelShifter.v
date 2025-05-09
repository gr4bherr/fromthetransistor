module barrelShifter (
  input vimm,
  input bimm,
  input shift,
  input [1:0] type,
  input [7:0] valimm,
  input [31:0] valreg, // rm
  input [31:0] byimm,
  input [7:0] byreg, // bottom byte of rs
  input [31:0] datain,
  output reg [31:0] dataout,
  input [3:0] flagsin,
  output reg [3:0] flagsout
);
  //assign dataout = datain; // todo: out coerced to in
  parameter width = 32;
  reg [31:0] val;
  reg [7:0] by;
  reg [31:0] carry;

  always @ (*) begin
    if (vimm) val = valimm;
    else val = valreg;

    if (shift) begin
      if (bimm) by = byimm;
      else by = byreg;

      case (type)
        `LSL: begin 
          carry = val << by - 1;
          if (by == 0) flagsout = flagsin[1];
          else flagsout = {flagsin[3:2], carry[31] , flagsin[0]};
          dataout = val << by & 32'hffffffff;
        end `LSR: begin 
          carry = val >> by - 1;
          flagsout = {flagsin[3:2], carry[0] , flagsin[0]};
          dataout = val >> by;
        end `ASR: begin 
          carry = val >> by - 1;
          flagsout = {flagsin[3:2], carry[0] , flagsin[0]};
          if (val[31]) dataout = val >> by | 32'hffffffff << width - by;
          else dataout = val >> by;
        end `ROR: begin 
          if (by == 0 & ~vimm) begin // RRX [4] == 0
            $display("rrx");
            carry = val[0];
            flagsout = {flagsin[3:2], carry, flagsin[0]};
            dataout = val >> 1 | {flagsin[1], 31'b0};
          end else begin // ROR
            carry = val >> by - 1;
            flagsout = {flagsin[3:2], carry[0] , flagsin[0]};
            dataout = (val >> by) | (val << (width - by)) & 32'hffffffff;
          end
        end
      endcase
    end else
      dataout = val;
  end
endmodule