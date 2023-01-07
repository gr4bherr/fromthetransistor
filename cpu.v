`timescale 1ns/1ps

// ./assembler.py assin.s && iverilog -o cpu.out cpuTB.v cpu.v && ./cpu.out

`define PC 15

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
`define c_ipipeout 13
`define c_ipipein 14
`define c_dataregin 15
`define c_dataregout 16
`define c_shiftbyimm 17
`define c_shiftvalimm 18


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

//instruction pipeline & read data register (& thumb instruction decoder)
module ipipe (
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

module writeDataRegister (
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



module instructionDecoder (
  input wire [31:0] ins,
  //output wire [31:0] instruction,
  output reg [31:0] control,

  output reg [31:0] shiftby,
  output reg [1:0] shifttype,
  output reg [3:0] opcode,
  output reg [3:0] rm,
  output reg [3:0] rn,
  output reg [3:0] rd,
  output reg [3:0] rs,
  output reg [31:0] shiftval
);
  always @ (ins) begin
    if (ins[31:28] != 4'b1111) begin // if condition valid
      if (ins[27:26] == 2'b00) begin
          if (ins[25] == 1'b0) begin
            // DATA PROCESSING: reg {shift} (1/2) (i = 0)
            if (!(ins[24:23] == 2'b10 & ins[20] == 1'b0) & ((ins[4] == 1'b0) | (ins[7] == 1'b0 & ins[4] == 1'b1))) begin
              // i, opcode, s, rn, rd, shiftam, shift, t, rm
              $display("\tinsnum: 0 (1/2)");
              // cycleone <= 'h0;
              opcode = ins[24:21];
              rn = ins[19:16];
              rd = ins[15:12];
              rm = ins[3:0];
              shifttype = ins[6:5];
              // todo use c_shiftbyimm for if statement 
              control[`c_shiftvalimm] = 0;
              control[`c_shiftbyimm] = ins[4];
              if (ins[4] == 0)
                shiftby = ins[11:7];
              else
                rs = ins[11:8];
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
              rn = ins[19:16];
              rd = ins[15:12];
              $display(rd);
              shiftby = ins[11:8] * 2; // rotate by
              shifttype = 2'b11;
              shiftval = ins[7:0];
              control[`c_shiftvalimm] = 1;
              control[`c_shiftbyimm] = 1;
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
  input wire pcwrite,
  input wire writeback,

  input wire [31:0] in1, // alu bus
  input wire [31:0] in2, // incrementer bus
  input wire [3:0] rm,
  input wire [3:0] rn,
  input wire [3:0] rs,
  input wire [3:0] rd,
  output wire [31:0] out1, // a bus (rm)
  output wire [31:0] out2, // b bus (rn)
  output wire [31:0] out3 // shiftamountreg (rs)
);
  // 16 base registers + cpsr
  reg [31:0] regs [0:16];

  assign out1 = regs[rm];
  assign out2 = regs[rn];
  assign out3 = regs[rs];

  always @ (posedge clk) begin
    //$display(regs[`PC]);
    // todo
    //if (write) begin
      //if (in1on) regs[rm] <= in1;
      //else if (in2on) regs[rn] <= in2;
    //end

    //if (pcwrite) regs[`PC] <= in2;
    if (writeback) regs[rd] <= in1;
    $display("mov check", regs[2], regs[4], regs[5], regs[7]);
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


    case (type)
      0: begin 
        dataout = 32'b00;
      end
      1: begin 
        dataout =  32'b01;
      end
      2: begin 
        dataout = 32'b10;
      end
      3: begin 
        dataout = (val >> by) | (val << (width - by));
      end
    endcase
  end
endmodule

module alu (
  input wire [3:0] opcode,
  input wire [31:0] dataina,
  input wire [31:0] datainb,
  output reg writeback,
  output reg [31:0] dataout
);
  reg c = 0; // todo (flags)

  always @ (*) begin
    case (opcode)
      0: begin
        dataout = dataina & datainb; // and
        writeback = 1;
      end
      1: begin
        dataout = dataina ^ datainb; // eor 
        writeback = 1;
      end
      2: begin
        dataout = dataina - datainb; // sub
        writeback = 1;
      end
      3: begin 
        dataout = datainb - dataina; // rsb
        writeback = 1;
      end
      4: begin 
        dataout = dataina + datainb; // add 
        writeback = 1;
      end
      5: begin
        dataout = dataina + datainb + c; // adc
        writeback = 1;
      end
      6: begin 
        dataout = dataina - datainb + c; // sbc
        writeback = 1;
      end
      7: begin
        dataout = datainb - dataina + c; // rsc
        writeback = 1;
      end
      8: begin
        dataout = dataina & datainb; // tst
        writeback = 0;
      end
      9: begin
        dataout = dataina ^ datainb; // teq
        writeback = 0;
      end
      10: begin
        dataout = dataina - datainb; // cmp
        writeback = 0;
      end
      11: begin
        dataout = dataina + datainb; // cmn
        writeback = 0;
      end
      12: begin
        dataout = dataina | datainb; // orr
        writeback = 1;
      end
      13: begin
        dataout = datainb; // mov
        writeback = 1;
      end
      14: begin
        dataout = dataina & ~datainb; // bic
        writeback = 1;
      end
      15: begin
        dataout = ~datainb; // mvn
        writeback = 1;
      end
    endcase
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
    //.out1on (ctrl[`c_addrout1]),
    .out1on (1'b1),
    //.out2on (c_addrout2),
    .in1 (alubus),
    .in2 (incrementerbus),
    .out1 (addressbus),
    .out2 (incrinbus)
  );
  addressIncrementer addressIncrementerModule (
    //.increment (ctrl[`c_incrementenable]),
    .increment (1'b1),
    .datain (incrinbus),
    .dataout (incrementerbus)
  );
  writeDataRegister writeDataRegisterModule (
    .clk (clk),
    .inon (ctrl[`c_dataregin]),
    //.outon (ctrl[`c_dataregout]),
    .outon (1'b0),
    .datain (bbus),
    .dataout (databus)
  );
  ipipe ipipeModule (
    .clk (clk),
    //.inon (ctrl[`c_ipipein]),
    .inon (1'b1),
    //.out1on (ctrl[`c_ipipeout]),
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
  registerBank registerBankModule (
    .clk (clk),
    .write (ctrl[`c_regwrite]),
    //.in1on (ctrl[`c_regin1]),
    .in1on (1'b1),
    //.in2on (ctrl[`c_regin2]),
    .in2on (1'b1),
    .pcwrite (ctrl[`c_regpcwrite]),
    .writeback (writebackalu),
    .in1 (alubus),
    .in2 (incrementerbus),
    .rm (i_rm),
    .rn (i_rn),
    .rs (i_rs),
    .rd (i_rd),
    .out1 (abus),
    .out2 (bbus),
    .out3 (shiftbyreg)
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
  alu aluModule (
    .opcode (i_opcode),
    .dataina (abus),
    .datainb (bbusext),
    .writeback (writebackalu),
    .dataout (alubus)
  );

  // FOR TEST
  reg [31:0] cycles = 0;
  always @ (posedge clk) begin
    
    case (cycles)
      0: begin
        $display("ha");
      end
    endcase

    #1
    $display("**** CYCLE: %0d ****\n", cycles);
    cycles <= cycles + 1;
  end


endmodule