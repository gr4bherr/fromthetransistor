`timescale 1ns/1ps

`define PC 15

// CONTROL SIGNALS (ctrl)
// memory
`define c_memwrite 0
// address register
`define c_addrwrite 1
`define c_addrin1 2
`define c_addrin2 3
`define c_addrout1 4
`define c_addrout2 5
// address incrementer 
`define c_incrementenable 6
// instruction decoder
`define c_instrin 7
// register bank
`define c_regwrite 8
`define c_regin1 9
`define c_regin2 10
`define c_regpcwrite 10

// ./assembler.py assin.s && iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out

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

  input wire [31:0] in1, // alu bus 
  input wire [31:0] in2, // incrementer bus

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

module instructionDecoder (
  input wire clk,

  input wire getinstr, 

  input wire [31:0] datain,
  output wire [31:0] instruction,
  output wire [31:0] control
);
  reg [31:0] ireg;
  reg [31:0] creg; //= 32'b1; // 32'b10000000_00000000_00000000_00000000;
  assign instruction = ireg;
  assign control = creg;

  integer step = 0; // todo temporary, no pipeline yet
  // CONTROL SIGNALS (ctrl)
  // memory
  parameter memwrite = 32'd2**`c_memwrite;
  // address register
  parameter addrwrite = 32'd2**`c_addrwrite;
  parameter addrin1 = 32'd2**`c_addrin1;
  parameter addrin2 = 32'd2**`c_addrin2;
  parameter addrout1 = 32'd2**`c_addrout1;
  parameter addrout2 = 32'd2**`c_addrout2;
  // address incrementer 
  parameter incrementenable = 32'd2**`c_incrementenable;
  // instruction decoder
  parameter instrin = 32'd2**`c_instrin;
  // register bank
  parameter regwrite = 32'd2**`c_regwrite;
  parameter regin1 = 32'd2**`c_regin1;
  parameter regin2 = 32'd2**`c_regin2;
  parameter regpcwrite = 32'd2**`c_regpcwrite;

  always @ (posedge clk) begin
    if (getinstr) ireg <= datain;
    // decode
    case (step)
      // fetch
      0: begin
        // todo start at zero (make this default value of creg, change to this value on last step)
        creg <= addrout1;
      end
      // decode
      1: begin
        creg <= instrin | // instruction into instruction decoder
                incrementenable | // address increment
                addrwrite | addrin2 | // write new address to address register
                regin2 | regpcwrite; // write new pc to pc register
      end
      // execute
      2: begin
        creg <= 32'b0;
      end
      3: begin
        creg <= 32'b0;
      end
      4: begin
        creg <= 32'b0;
      end
      5: begin
        creg <= 32'b0;
      end
      6: begin
        creg <= 32'b0;
      end
      7: begin
        creg <= 32'b0;
      end
    endcase


    // todo temp, each instr has 8 clk cycles to be done (i know 8 is way too much)
    if (step == 7) step = 0;
    else step += 1;
  end
endmodule

module registerBank (
  input wire clk, 
  input wire write,
  input wire in1on,
  input wire in2on,
  input wire pcwrite,

  input wire [31:0] in1, // alu bus
  input wire [31:0] in2, // incrementer bus
  input wire [3:0] addressA, // used for write 
  input wire [3:0] addressB,
  output wire [31:0] out1, // a bus
  output wire [31:0] out2 // b bus
);
  // 16 base registers + cpsr
  reg [31:0] regs [0:16];

  assign out1 = regs[addressA];
  assign out2 = regs[addressB];

  always @ (posedge clk) begin
    //$display(regs[`PC]);
    if (write) begin
      if (in1on) regs[addressA] <= in1;
      else if (in2on) regs[addressA] <= in2;
    end
    if (pcwrite) regs[`PC] <= in2;
  end
endmodule

module barrelShifter (
  input wire [1:0] type,
  input wire [31:0] amount, // todo: not sure about the size
  input wire [31:0] datain,
  input wire [31:0] dataout
);
  assign dataout = datain; // todo: out coerced to in
endmodule

module alu (
  input wire [3:0] opcode,
  input wire [31:0] dataina,
  input wire [31:0] datainb,
  output wire [31:0] dataout
);
  reg c = 0; // todo
  // (could be more elegant, this is the only thing i came up with)
  assign dataout = opcode[3] ?
                    (opcode[2] ?
                      (opcode[1] ? 
                        (opcode[0] ? 
                          (~datainb) : // mvn
                          (dataina & ~datainb)) : // bic
                        (opcode[0] ?
                          (datainb) : // mov
                          (dataina | datainb))) :  // orr
                      (opcode[1] ?
                        (opcode[0] ?
                          (dataina + datainb) : // cmn
                          (dataina - datainb)) : // cmp
                        (opcode[0] ?
                          (dataina ^ datainb) : // teq
                          (dataina & datainb)))) : // tst
                    (opcode[2] ?
                      (opcode[1] ?
                        (opcode[0] ?
                          (datainb - dataina + c) : // rsc
                          (dataina - datainb + c)) : // sbc
                        (opcode[0] ?
                          (dataina + datainb + c) : // adc
                          (dataina + datainb))) : // add
                      (opcode[1] ?
                        (opcode[0] ?
                          (datainb - dataina) : // rsb
                          (dataina - datainb)) : // sub 
                        (opcode[0] ?
                          (dataina ^ datainb) : // eor 
                          (dataina & datainb)))); // and
endmodule


// **** CPU ****
module cpu (input clk);
  // INPUT SIGNALS (instr)
  // register bank
  reg [3:0] i_addressa;
  reg [3:0] i_addressb;
  // barrel shifter
  reg [1:0] i_shifttype;
  reg [31:0] i_shiftamount;
  // alu
  reg [3:0] i_opcode;

  // RANDOM
  wire [31:0] memdataout;
  //wire [31:0] memdatain;


  // BUSES
  wire [31:0] memdatain; // todo look at it?
  wire [31:0] alubus;
  wire [31:0] incrementerbus;
  wire [31:0] addressbus;
  wire [31:0] incrinbus;

  wire [31:0] instr;
  //wire [31:0] fuck;
  wire [31:0] ctrl; //todo

  wire [31:0] abus;
  wire [31:0] bbus;

  wire [31:0] bbusext;


  // MODULES
  memory memoryModule (
    .clk (clk), 
    .write (ctrl[0]), 
    .address (addressbus), 
    .datain (memdatain), 
    .dataout (memdataout)
  );
  addressRegister addressRegisterModule (
    .clk (clk),
    .write (ctrl[`c_addrwrite]),
    .in1on (ctrl[`c_addrin1]),
    .in2on (ctrl[`c_addrin2]),
    .out1on (ctrl[`c_addrout1]),
    //.out2on (c_addrout2),
    .in1 (alubus),
    .in2 (incrementerbus),
    .out1 (addressbus),
    .out2 (incrinbus)
  );
  addressIncrementer addressIncrementerModule (
    .increment (ctrl[`c_incrementenable]),
    .datain (incrinbus),
    .dataout (incrementerbus)
  );
  wire [31:0] three;
  instructionDecoder instructionDecoderModule (
    .clk (clk),
    .getinstr (ctrl[`c_instrin]),
    .datain (memdataout),
    .instruction (instr),
    .control (ctrl)
  );
  registerBank registerBankModule (
    .clk (clk),
    .write (ctrl[`c_regwrite]),
    .in1on (ctrl[`c_regin1]),
    .in2on (ctrl[`c_regin2]),
    .pcwrite (ctrl[`c_regpcwrite]),
    .in1 (alubus),
    .in2 (incrementerbus),
    .addressA (i_addressa),
    .addressB (i_addressb),
    .out1 (abus),
    .out2 (bbus)
  );
  barrelShifter barrelShifterModule (
    .type (i_shifttype),
    .amount (i_shiftamount),
    .datain (bbus),
    .dataout (bbusext)
  );
  alu aluModule (
    .opcode (i_opcode),
    .dataina (abus),
    .datainb (bbusext),
    .dataout (alubus)
  );











  // FOR TEST
  reg [31:0] cycles = 0;
  always @ (posedge clk) begin
    
    case (cycles)
      0: begin
        $display("ha");
      end


      //// fetch
      //0: begin 
      //  ctrl[c_addrout1] <= 1; // address register out
      //end
      //// decode
      //1: begin 
      //  ctrl[c_addrout1] <= 0;
      //  // 1
      //  ctrl[c_instrin] <= 1; // instr decoder in

      //  ctrl[c_addrwrite] <= 1; // address register point to nextr instr
      //  ctrl[c_addrin2] <= 1;
      //  ctrl[c_incrementenable] <= 1;
      //end
      //// execute
      //2: begin
      //  ctrl[c_instrin] <= 0;
      //  ctrl[c_addrwrite] <= 0;
      //  ctrl[c_addrin2] <= 0;
      //  ctrl[c_incrementenable] <= 0;
      //  // 1
      //end

    endcase





    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end


endmodule