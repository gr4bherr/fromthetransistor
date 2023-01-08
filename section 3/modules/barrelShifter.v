module barrelShifter (
  input wire vimm,
  input wire bimm,
  input wire [1:0] type,
  input wire [31:0] valimm, // todo: not sure about the size
  input wire [31:0] valreg, // rm
  input wire [31:0] byimm,
  input wire [31:0] byreg, // rs
  input wire [31:0] datain,
  output reg [31:0] dataout
);
  //assign dataout = datain; // todo: out coerced to in
  parameter width = 32;
  reg [31:0] val;
  reg [31:0] by;

  always @ (*) begin
    if (vimm)
      val = valimm;
    else
      val = valreg;

    if (bimm)
      by = byimm;
    else 
      by = byreg;

    // todo: add carry
    case (type)
      `LSL: begin 
        dataout = val << by & 32'hffffffff;
      end `LSR: begin 
        dataout = val >> by;
      end `ASR: begin 
        if (val[31]) dataout = val >> by | 32'hffffffff << width - by;
        else dataout = val >> by;
      end `ROR: begin 
        dataout = (val >> by) | (val << (width - by)) & 32'hffffffff;
      end
    endcase
  end
endmodule