`timescale 1ns/1ps

// special registers
`define PC 15
`define CPSR 16
// flags
`define N 4'b1000
`define Z 4'b0100
`define C 4'b0010
`define V 4'b0001

// **** MODULES **** 
module memory(
  input wire clk,
  input wire write,
  input wire [31:0] address,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  reg [31:0] mem [0:63]; // 64 * 4 bytes
  integer i;
  // load
  assign dataout = mem[address / 4];

  initial begin
    $display("**** RAM ****");
    // initial store into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) $display("M: %0h %h",i , mem[i]);
  end

  always @(posedge clk) begin
    if (write) mem[address] <= datain;
  end
endmodule

module registerBank(
  input wire clk,
  input wire store, // if register is to be written
  input wire [4:0] select, // selects, which register is to be written (TAKES EFFECT ONLY WHEN regload = 1)
  input wire [31:0] datain, // data that is to be written
  output wire [31:0] dataout0, dataout1, dataout2, dataout3, dataout4, dataout5, dataout6, dataout7,
  dataout8, dataout9, dataout10, dataout11, dataout12, dataout13, dataout14, dataout15, dataout16 // should be 32
);
  // 16 base registers + cpsr
  reg [31:0] regs [0:16];
  assign dataout0 = regs[0]; assign dataout1 = regs[1]; assign dataout2 = regs[2]; assign dataout3 = regs[3];
  assign dataout4 = regs[4]; assign dataout5 = regs[5]; assign dataout6 = regs[6]; assign dataout7 = regs[7];
  assign dataout8 = regs[8]; assign dataout9 = regs[9]; assign dataout10 = regs[10]; assign dataout11 = regs[11];
  assign dataout12 = regs[12]; assign dataout13 = regs[13]; assign dataout14 = regs[14]; assign dataout15 = regs[15];
  assign dataout16 = regs[16]; // cpsr

  initial begin
    $display("**** REGISTER BANK ****");
    regs[`CPSR] <= 32'b111010011;
    regs[`PC] <= 0;
  end

  always @(posedge clk) begin
    if (store) regs[select] <= datain;

    // address incrementer (not sure if synthesizable)
    regs[`PC] <= regs[`PC] + 4;
  end 
endmodule



// **** FETCH ****
module addressRegister(
  // control signals
  input wire write,
  input wire addressbusout,

  //input clk, 
  input wire [31:0] pcbus,
  input wire [31:0] incrementbus,
  input wire [31:0] alubus,
  output wire [31:0] addressbus,
  output wire [31:0] addressincrementer
);
  reg [31:0] value;
endmodule

module addressIncrementer (
  input wire incrementEnable,

  input wire [31:0] datain,
  input wire [31:0] dataout
);
  assign dataout = datain + 4;
endmodule





// **** DECODE ****
module instructionDecoder(
  input wire clk,
  input wire [31:0] fetchedInstr,
  output reg [31:0] controlsignal
);
  reg [31:0] ins; // instruction to decode
  //reg [3:0] cond;

  always @(posedge clk) begin
    $display("fetched:  %h", fetchedInstr);
    ins <= fetchedInstr; 
    $display("decoding: %h", ins);

    if (ins[31:28] != 4'b1111) begin // if condition valid
      //todo case (ins[27:26])
      if (ins[27:26] == 2'b00) begin
          if (ins[25] == 1'b0) begin
            // DATA PROCESSING: reg {shift} (1/2)
            if (!(ins[24:23] == 2'b10 & ins[20] == 1'b0) & ((ins[4] == 1'b0) | (ins[7] == 1'b0 & ins[4] == 1'b1))) begin
              $display("\tinsnum: 0");
              controlsignal <= 'h0;
            end else if ((ins[24:23] == 2'b10 & ins[20] == 1'b0) & (ins[7] == 1'b0)) begin
              // PSR TRANSFER: mrs reg, msr reg (1/2)
              if (ins[6:4] == 3'b000) begin
                $display("\tinsnum: 1");
                controlsignal <= 'h1;
              // BRANCH AND EXCHANGE
              end else if (ins[6:4] == 3'b001 & ins[22:21] == 2'b01) begin
                $display("\tinsnum: 5");
                controlsignal <= 'h5;
              end 
            end else if (ins[24] == 1'b0 & ins[7:4] == 4'b1001) begin
              // MULTIPLY
              if (ins[23:22] == 2'b00) begin
                $display("\tinsnum: 2");
                controlsignal <= 'h2;
              // MULTIPLY LONG
              end else if (ins[23] == 1'b1) begin
                $display("\tinsnum: 3");
                controlsignal <= 'h3;
              end
            // HALF WORD DATA TRANSFER
            end else if (!(ins[24] == 1'b0 & ins[21] == 1'b1) | (ins[24] == 1'b0 & ins[21:20] == 2'b10) & (ins[7:4] == 4'b1011 | ins[7:4] == 4'b1101 | ins[7:4] == 4'b1111)) begin
              $display("\tinsnum: 6 or 7");
              controlsignal <= 'h67; // 6 or 7
            // SINGLE DATA SWAP
            end else if (((ins[24:23] == 2'b10 & ins[21:20] == 2'b00) & ins[10:4] == 8'b00001001)) begin
              $display("\tinsnum: 4");
              controlsignal <= 'h4;
            end
          end else if (ins[25] == 1'b1) begin
            // DATA PROCESSING: imm (2/2)
            if (!(ins[24:23] == 2'b10 & ins[20] == 1'b0)) begin 
              $display("\tinsnum: 0");
              controlsignal <= 0;
            // PSR TRANSFER: msr imm (2/2)
            end else if (ins[24:23] == 2'b10 & ins[21:20] == 2'b10) begin 
              $display("\tinsnum: 1");
              controlsignal <= 1;
            end
          end
      // SINGLE DATA TRANSFER 
      end else if (ins[27:26] == 2'b01) begin
        //todo
        $display("\tinsnum: 8");
        controlsignal <= 'h8;
      end else if (ins[27:26] == 2'b10) begin
          // BLOCK DATA TRANSFER
          if (ins[25] == 1'b0) begin
            $display("\tinsnum: a");
            controlsignal <= 'ha;
          // BRANCH
          end else if (ins[25] == 1'b1) begin
            $display("\tinsnum: b");
            controlsignal <= 'hb;
          end
      end else if (ins[27:26] == 2'b11) begin
        // UNDEFINED
        if (ins[25:21] == 5'b00000) begin
            $display("\tinsnum: 9");
            controlsignal <= 'h9;
        // SOFTWARE INTERRUPT
        end else if (ins[25:20] == 6'b110000) begin
            $display("\tinsnum: f");
            controlsignal <= 'hf;
        end 
        // COPROCESSOR...
      end else begin
          // not valid instruction
          $display("\tinvalid instruction");
      end
    end
    $display("\tcontrol signal: %0h", controlsignal);
  end
endmodule


// **** EXECUTE ****
module alu(
  input clk,
  input [31:0] datain1,
  input [31:0] datain2,
  input [3:0] op,
  //output zeroflag,
  output reg [31:0] dataout // todo remove reg
);
  always @(posedge clk) begin
    case (op)
      0: dataout = datain1 & datain2; // AND
      1: dataout = datain1 ^ datain2; // EOR
      2: dataout = datain1 - datain2; // SUB
      3: dataout = datain2 - datain1; // RSB
      4: dataout = datain1 + datain2; // ADD
      5: dataout = datain1 + datain2; //+ c; // ADC
      6: dataout = datain1 - datain2; //+ c; // SBC
      7: dataout = datain2 - datain1; //+ c; // RSC
      8: dataout = datain1 & datain2; // TST
      9: dataout = datain1 ^ datain2; // TEQ
      10: dataout = datain1 - datain2; // CMP
      11: dataout = datain1 + datain2; // CMN
      12: dataout = datain1 | datain2; // ORR
      13: dataout = datain2; // MOV
      14: dataout = datain1 & ~datain2; // datain2IC
      15: dataout = ~datain2; // MVN
    endcase
  end
endmodule

module multiplier(
  input clk,
  input [31:0] datain1,
  input [7:0] datain2,
  output reg [31:0] dataout
);
  always @(posedge clk) begin
    // assign?
    dataout <= datain1 * datain2;
  end
endmodule

module barrelShifter(
  input clk,
  input [31:0] datain,
  input [1:0] op,
  input [31:0] shiftamm,
  output reg [31:0] dataout
);
  always @(posedge clk) begin
    case (op)
     2'b00: $display("logical left");
     2'b01: $display("logaical right");
     2'b10: $display("arithmetic right");
     2'b11: $display("rotate right");
    endcase
  end
endmodule


// todo ram shouldnt be within cpu, should it now
// **** CPU ****
module cpu(input clk);
  // buses
  //wire [31:0] abus;
  //wire [31:0] bbus;
  //wire [31:0] alubus;
  //wire [31:0] incrementbus;
  //wire [31:0] pcbus;


  // memory
  //reg memload;
  //wire [31:0] memaddress;
  //reg [31:0] memdatain;
  //wire [31:0] memdataout;
  memory mem(
    .clk (clk), 
    .write (memwrite), 
    .address (memaddress), 
    .datain (memdatain), 
    .dataout (memdataout));

  // FETCH
  // address register
  wire [31:0] instruction; // todo: not sure about this one
  //wire [31:0] incrementerbus;

  addressRegister addressRegisterModule (
    .addressbusout (ARaddressbusout),
    .pcbus (ARpcbus), 
    .incrementbus (ARincrementerbus),
    .alubus (ARalubus),
    .addressbus (ARaddressbus),
    .addressincrementer (ARaddressincrementer)
  );

  addressIncrementer addressIncrementerModule (
    .incrementEnable (incrementEnable),
    .datain (ARaddressincrementer),
    .dataout (incrementerbus)
  );



  // DECODE
  // register bank
  //reg regload; // todo: change to wire
  //reg [4:0] regselect;
  //reg [31:0] regdatain;
  wire [31:0] regdataout [0:16]; // todo maybe leave, maybe remove
  registerBank registers (
    .clk (clk),
    .store (regstore),
    .select (regselect), 
    .datain (regdatain),
    .dataout0 (regdataout[0]), .dataout1 (regdataout[1]), .dataout2 (regdataout[2]), .dataout3 (regdataout[3]),
    .dataout4 (regdataout[4]), .dataout5 (regdataout[5]), .dataout6 (regdataout[6]), .dataout7 (regdataout[7]),
    .dataout8 (regdataout[8]), .dataout9 (regdataout[9]), .dataout10 (regdataout[10]), .dataout11 (regdataout[11]),
    .dataout12 (regdataout[12]), .dataout13 (regdataout[13]), .dataout14 (regdataout[14]), .dataout15 (regdataout[15]),
    .dataout16 (regdataout[16]));
  // instruction decoder
  //wire [31:0] control;
  instructionDecoder decode (
    .clk (clk),
    .fetchedInstr (instruction),
    .controlsignal (control)
  );


  // EXECUTE


  // ** FETCH **
  assign memaddress = regdataout[`PC];
  assign instruction = memdataout;
  // ** DECODE **
  // ** EXECUTE **

  // IGNORE
  reg [31:0] cycles = 0;
  always @(posedge clk) begin
    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end
endmodule