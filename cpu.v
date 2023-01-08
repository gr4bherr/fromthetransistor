`timescale 1ns/1ps

// ./assembler.py assin.s && iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out

`define PC 15
`define CPSR 16

`define N 31
`define Z 30
`define C 29
`define V 28

`define LSL 0 // (ASL)
`define LSR 1 
`define ASR 2
`define ROR 3 // (RRX)


`define EQ 0
`define NE 1
`define CS 2
`define CC 3
`define MI 4
`define PL 5
`define VS 6
`define VC 7
`define HI 8
`define LS 9
`define GE 10
`define LT 11
`define GT 12
`define LE 13
`define AL 14

`define AND 0
`define EOR 1
`define SUB 2
`define RSB 3
`define ADD 4
`define ADC 5
`define SBC 6
`define RSC 7
`define TST 8
`define TEQ 9
`define CMP 10
`define CMN 11
`define ORR 12
`define MOV 13
`define BIC 14
`define MVN 15

// CONTROL SIGNALS (ctrl)
// todo reorder and clean up
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
// register bank
`define c_regwrite 8
`define c_regin1 9
`define c_regin2 10
`define c_regpcwrite 11
`define c_memout 12
`define c_instructionRegisterout 13
`define c_instructionRegisterin 14
`define c_dataregin 15
`define c_dataregout 16
`define c_shiftbyimm 17
`define c_shiftvalimm 18
`define c_setflags 19
`define c_pcchange 20


module memory(
  input wire clk,
  input wire write,
  input wire out,
  input wire [31:0] address,
  inout wire [31:0] data
);
  reg [31:0] mem [0:63]; // 64 * 4 bytes
  integer i;
  reg [31:0] buffer; //
  // load
  assign data = out ? buffer : 32'bz;

  initial begin
    // initial store into memory
    $readmemh("assout.txt",mem);
    // memmory display
    for (i=0;i<10;i=i+1) $display("M: %0h %h",i , mem[i]);
  end

  always @ (posedge clk) begin
    //$display(buffer);
    if (write) mem[address / 4] <= data;
    buffer <= mem[address / 4];
  end
endmodule

module addressRegister (
  input wire clk,
  // control
  input wire write,
  input wire in1on,
  input wire in2on,
  input wire in3on,
  input wire out1on,
  //input wire out2on,

  input wire [31:0] in1, // alu bus 
  input wire [31:0] in2, // incrementer bus
  input wire [31:0] in3, // pc bus 
 
  output wire [31:0] out1, // out to memory 
  output wire [31:0] out2 // out to address incrementer
);
  reg [31:0] areg;

  // out
  assign out1 = out1on ? areg : 32'bz;
  assign out2 = areg;

  always @ (posedge clk) begin
  // write
    if (in3on) areg <= in3;
    else areg <= in2;
  end

  initial begin
    areg <= 0; // todo add to reset
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

module dataRegister (
  input clk,
  input wire inon,
  input wire outon,
  input wire [31:0] datain,
  output wire [31:0] dataout
);
  reg [31:0] datareg;
  assign dataout = outon ? datareg : 32'bz;
  always @ (posedge clk) begin
    if (inon) datareg <= datain;
  end
endmodule

//instruction pipeline & read data register (& thumb instruction decoder)
module instructionRegister (
  input clk,
  input wire inon,
  input wire out1on,
  input wire [31:0] datain,
  output wire [31:0] dataout1, // b bus
  output wire [31:0] dataout2 // instruction decoder
);

  assign dataou1 = out1on ? ireg : 32'bz;
  assign dataout2 = ireg;

  reg [31:0] ireg;
  always @ (posedge clk) begin
    if (inon) ireg <= datain;
  end
endmodule


module instructionDecoder (
  input wire [31:0] ins,
  output reg [31:0] control,

  input wire [3:0] flags,

  output reg [31:0] shiftby,
  output reg [1:0] shifttype,
  output reg [3:0] opcode,
  output reg [3:0] rm,
  output reg [3:0] rn,
  output reg [3:0] rd,
  output reg [3:0] rs,
  output reg [31:0] shiftval
);
  initial begin
    control = 0;
  end

  always @ (ins) begin
    control = 32'b0; // todo make into or statements
    // condition check
    if ((ins[31:28] == `EQ & flags[`N]) | (ins[31:28] == `NE & ~flags[`Z]) | 
        (ins[31:28] == `CS & flags[`C]) | (ins[31:28] == `CC & ~flags[`C]) | 
        (ins[31:28] == `MI & flags[`N]) | (ins[31:28] == `PL & ~flags[`N]) | 
        (ins[31:28] == `VS & flags[`V]) | (ins[31:28] == `VC & ~flags[`V]) |
        (ins[31:28] == `HI & flags[`C] & ~flags[`Z]) | (ins[31:28] == `LS & ~flags[`C] & flags[`Z]) | 
        (ins[31:28] == `GE & flags[`Z] == flags[`V]) | (ins[31:28] == `LT & flags[`Z] != flags[`V]) | 
        (ins[31:28] == `GT & ~flags[`Z] & flags[`N] == flags[`V]) | (ins[31:28] == `LE & (flags[`Z] | flags[`N] != flags[`V])) | 
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

module registerBank (
  input wire clk, 
  input wire write,
  input wire in1on,
  input wire in2on,
  input wire pcchange,
  input wire writeback,
  input wire cpsrwrite,

  input wire [31:0] alubusin,
  input wire [31:0] incrbusin,
  input wire [3:0] rm,
  input wire [3:0] rn,
  input wire [3:0] rs,
  input wire [3:0] rd,
  input wire [3:0] updatedflags,
  output wire [3:0] flags,
  output wire [31:0] abusout, // rn
  output wire [31:0] bbusout, // rm
  output wire [31:0] barrelshifterout, // (rs) shiftamountreg 
  output wire [31:0] pcbusout
);
  // 16 base registers + cpsr
  reg [31:0] regs [0:16];

  assign flags = regs[`CPSR][31:28];
  assign abusout = regs[rn];
  assign bbusout = regs[rm];
  assign barrelshifterout = regs[rs];
  assign pcbusout = regs[`PC];

  // write on falling edge
  always @ (negedge clk) begin
    //$display(regs[`PC]);
    // todo
    //if (write) begin
      //if (in1on) regs[rm] <= in1;
      //else if (in2on) regs[rn] <= in2;
    //end

    if (writeback) regs[rd] <= alubusin;
    if (~pcchange) regs[`PC] <= incrbusin;
    if (cpsrwrite) regs[`CPSR] <= {updatedflags, regs[`CPSR][27:0]};
  end

  // set modes, my cpu doesn't care about them (just for fun)
  initial begin
    // FIQ disable, IRQ disable, T clear, mode: supervisor
    regs[16] <= 32'b111010011; 
  end

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
  end
endmodule

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

module alu (
  input wire [3:0] opcode,
  input wire setflags,
  input wire [31:0] dataina,
  input wire [31:0] datainb,
  input wire [3:0] cpsrin,
  output reg writeback,
  output reg [31:0] dataout,
  output reg [3:0] cpsrout
);
  reg c = 0; // todo (flags)

  always @ (*) begin
    case (opcode)
      `AND: begin
        dataout = dataina & datainb;
        writeback = 1;
      end `EOR: begin
        dataout = dataina ^ datainb;
        writeback = 1;
      end `SUB: begin
        $display("sub", dataina, datainb,":", dataina-datainb);
        dataout = dataina - datainb;
        writeback = 1;
      end `RSB: begin 
        dataout = datainb - dataina;
        writeback = 1;
      end `ADD: begin 
        dataout = dataina + datainb;
        writeback = 1;
      end `ADC: begin
        dataout = dataina + datainb + c;
        writeback = 1;
      end `SBC: begin 
        dataout = dataina - datainb + c;
        writeback = 1;
      end `RSC: begin
        dataout = datainb - dataina + c;
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
      if (dataout[31] == 1) cpsrout = cpsrin | 4'b1000;
      else cpsrout = cpsrin & 4'b0111;
      // Z
      if (dataout == 0) cpsrout = cpsrin | 4'b0100;
      else cpsrout = cpsrin & 4'b1011;
      // C
      // sub
      if (opcode == `SUB | opcode == `RSB | opcode == `SBC | opcode == `RSC | opcode == `CMP) begin
        if (dataina < datainb) cpsrout = cpsrin | 4'b0010;
        else cpsrout = cpsrin & 4'b1101;
      end
      // add 
      if (opcode == `ADD | opcode == `ADC | opcode == `CMN) begin
        if (dataina[31] == 1 & datainb[31] == 1) cpsrout = cpsrin | 4'b0010;
        else cpsrout = cpsrin & 4'b1101;
      end
      // V
      // sub or add
      if (opcode == `SUB | opcode == `RSB | opcode == `ADD | opcode == `ADC | opcode == `SBC | opcode == `RSC | opcode == `CMP) begin
        // signed overflow
        if (dataina[31] == 0 & datainb[31] == 0 & dataout[31] == 1) cpsrout = cpsrin | 4'b0001;
        else cpsrout = cpsrin & 4'b1110;
      end
    end
  end
endmodule


// **** CPU ****
module cpu (input clk);
  // INPUT SIGNALS (instr)
  // BUSES
  wire [31:0] databus;
  wire [31:0] alubus;
  wire [31:0] incrementerbus;
  wire [31:0] addressbus;
  wire [31:0] abus;
  wire [31:0] bbus;
  wire [31:0] bbusext;
  wire [31:0] incrinbus;
  wire [31:0] decodebus;
  wire [31:0] pcbus;


  // MODULES
  memory memoryModule (
    .clk (clk), 
    .write (ctrl[`c_memwrite]), 
    //.out (ctrl[`c_memout]),
    .out (1'b1),
    .address (addressbus),
    .data (databus)
  );
  addressRegister addressRegisterModule (
    .clk (clk),
    //.write (ctrl[`c_addrwrite]),
    .write (1'b1),
    .in1on (ctrl[`c_addrin1]),
    //.in2on (ctrl[`c_addrin2]),
    .in2on (1'b1),
    .in3on (ctrl[`c_pcchange]),
    //.out1on (ctrl[`c_addrout1]),
    .out1on (1'b1),
    //.out2on (c_addrout2),
    .in1 (alubus),
    .in2 (incrementerbus),
    .in3 (pcbus),
    .out1 (addressbus),
    .out2 (incrinbus)
  );
  addressIncrementer addressIncrementerModule (
    //.increment (ctrl[`c_incrementenable]),
    .increment (1'b1),
    .datain (incrinbus),
    .dataout (incrementerbus)
  );
  dataRegister dataRegisterModule (
    .clk (clk),
    .inon (ctrl[`c_dataregin]),
    //.outon (ctrl[`c_dataregout]),
    .outon (1'b0),
    .datain (bbus),
    .dataout (databus)
  );
  instructionRegister instructionRegisterModule (
    .clk (clk),
    //.inon (ctrl[`c_instructionRegisterin]),
    .inon (1'b1),
    //.out1on (ctrl[`c_instructionRegisterout]),
    .out1on (1'b1),
    .datain (databus),
    .dataout1 (bbus),
    .dataout2 (decodebus)
  );
  wire [31:0] ctrl;
  wire [31:0] i_shiftby;
  wire [1:0] i_shifttype;
  wire [3:0] i_opcode;
  wire [3:0] i_rm;
  wire [3:0] i_rn;
  wire [3:0] i_rs;
  wire [3:0] i_rd;
  wire [31:0] i_shiftval;
  instructionDecoder instructionDecoderModule (
    .ins (decodebus),
    //.instruction (instr),
    .control (ctrl),
    .flags (cpsr),
    .shiftby (i_shiftby),
    .shifttype (i_shifttype),
    .opcode (i_opcode),
    .rm (i_rm),
    .rn (i_rn),
    .rd (i_rd),
    .rs (i_rs),
    .shiftval (i_shiftval)
  );
  wire [31:0] shiftbyreg;
  wire [3:0] cpsr;
  registerBank registerBankModule (
    .clk (clk),
    .write (ctrl[`c_regwrite]),
    //.pcwrite (ctrl[`c_regpcwrite]),
    .pcchange (ctrl[`c_pcchange]),
    .cpsrwrite (ctrl[`c_setflags]),
    .writeback (writebackalu),
    .alubusin (alubus),
    .incrbusin (incrementerbus),
    .rm (i_rm),
    .rn (i_rn),
    .rs (i_rs),
    .rd (i_rd),
    .updatedflags (newcpsr),
    .flags (cpsr),
    .abusout (abus),
    .bbusout (bbus),
    .barrelshifterout (shiftbyreg),
    .pcbusout (pcbus)
  );
  barrelShifter barrelShifterModule (
    .vimm (ctrl[`c_shiftvalimm]),
    .bimm (ctrl[`c_shiftbyimm]),
    .type (i_shifttype),
    .valimm (i_shiftval),
    .valreg (bbus),
    .byimm (i_shiftby),
    .byreg (shiftbyreg),
    .datain (bbus),
    .dataout (bbusext)
  );
  wire writebackalu;
  wire [3:0] newcpsr;
  alu aluModule (
    .opcode (i_opcode),
    .setflags (ctrl[`c_setflags]),
    .dataina (abus),
    .datainb (bbusext),
    .cpsrin (cpsr),
    .writeback (writebackalu),
    .dataout (alubus),
    .cpsrout (newcpsr)
  );

  // FOR TEST // todo
  reg [31:0] cycles = 0;
  always @ (posedge clk) begin
    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end
endmodule