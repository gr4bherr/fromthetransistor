`timescale 1ns/1ps

module memory(
  input wire clk,
  input wire write,
  input wire [31:0] address,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  reg [31:0] mem [0:63]; // 64 * 4 bytes
  integer i;
  reg [31:0] buffer; //
  // load
  assign dataout = buffer;

  initial begin
    $display("**** RAM ****");
    // initial store into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) $display("M: %0h %h",i , mem[i]);
  end

  always @ (posedge clk) begin
    if (write) mem[address] <= datain;
    buffer <= mem[address];
  end
endmodule

module addressRegister (
  input wire clk,
  // control
  input wire write,
  input wire in1on,
  input wire in2on,
  input wire out1on,
  //input wire out2on,

  input wire [31:0] in1, // in from alu
  input wire [31:0] in2, // in from address incrementer

  output wire [31:0] out1, // out to memory 
  output wire [31:0] out2 // out to address incrementer
);

  reg [31:0] areg;

  // out
  assign out1 = out1on ? areg : 32'bz;
  assign out2 = areg;

  always @ (posedge clk) begin
    // write
    if (in1on & write) areg <= in1;
    else if (in2on & write) areg <= in2;
  end

  initial begin
    areg <= 0;
  end

  endmodule

module addressIncrementer (
  // control
  input wire increment,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  assign dataout = increment ? datain + 4 : 32'bz;
endmodule

//module instructionDecoder (
  //input clk,
  //// control 
  //input wire getinstr,

  //input wire [31:0] datain,
  //output wire [31:0] instruction
//);
  //reg ireg [31:0];

  //assign instruction = ireg;

  //always @ (posedge clk) begin
    //if (getinstr) ireg <= datain;
  //end
//endmodule

module instructionDecoder (
  input wire clk,

  input wire getinstr, 

  input wire [31:0] datain,
  output wire [31:0] instruction
  //output wire [31:0] controlsignal
);
  reg [31:0] ireg;

  assign instruction = ireg;

  always @ (posedge clk) begin
    if (getinstr) ireg <= datain;
  end
endmodule



// **** CPU ****
module cpu (input clk);

  wire [31:0] memdataout;
  //wire [31:0] memdatain;



  // BUSES
  wire [31:0] alubus;
  wire [31:0] incrementerbus;
  wire [31:0] addressbus;
  wire [31:0] incrinbus;

  // CONTROL SIGNALS
  reg c_addrwrite;
  reg c_addrin1;
  reg c_addrin2;
  reg c_addrout1;
  reg c_addrout2;
  
  reg c_incrementEnable;

  reg c_instrin;

  // MODULES
  memory memoryModule (
    .clk (clk), 
    .write (memwrite), 
    .address (addressbus), 
    .datain (memdatain), 
    .dataout (memdataout)
  );
  addressRegister addressRegisterModule (
    .clk (clk),
    .write (c_addrwrite),
    .in1on (c_addrin1),
    .in2on (c_addrin2),
    .out1on (c_addrout1),
    //.out2on (c_addrout2),
    .in1 (alubus),
    .in2 (incrementerbus),
    .out1 (addressbus),
    .out2 (incrinbus)
  );
  addressIncrementer addressIncrementerModule (
    .increment (c_incrementEnable),
    .datain (incrinbus),
    .dataout (incrementerbus)
  );
  wire [31:0] three;
  instructionDecoder instructionDecoderModule (
    .clk (clk),
    .getinstr (c_instrin),
    .datain (memdataout),
    .instruction (three)
  );











  // FOR TEST
  reg [31:0] cycles = 0;
  always @ (posedge clk) begin
    
    case (cycles)
      // fetch
      0: begin 
        c_addrout1 <= 1; // address register out
      end
      // decode
      1: begin 
        c_addrout1 <= 0;
        // 1
        c_instrin <= 1; // instr decoder in

        c_addrwrite <= 1; // address register point to nextr instr
        c_addrin2 <= 1;
        c_incrementEnable <= 1;
      end
      // execute
      2: begin
        c_instrin <= 0;
        c_addrwrite <= 0;
        c_addrin2 <= 0;
        c_incrementEnable <= 0;
        // 1
      end
    endcase





    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end


endmodule