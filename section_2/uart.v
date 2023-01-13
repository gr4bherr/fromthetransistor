`include "uartmacros.v"

module reciever (
  input clk, 
  input rx
);
  parameter datasize = `datasize;
  parameter samplerate = `samplerate;

  reg [7:0] rreg;
  reg [7:0] cnt;
  reg recieve = 0;

  always @ (posedge clk) begin
    // new byte
    if (rx == 0 & recieve == 0) begin
      recieve <= 1;
      cnt <= 0;
    end
    // store byte
    if (recieve) begin
      if (cnt == samplerate * (datasize + 1)) recieve <= 0;
      else cnt <= cnt + 1;
      // shift register
      if (cnt % samplerate == samplerate / 2) rreg <= rreg << 1 | rx;
    end
  end
endmodule

module transmitter (
  input clk,
  input transmit,
  output tx
);
  parameter datasize = `datasize;
  parameter samplerate = `samplerate;

  reg [7:0] cnt = 0;
  reg [7:0] txreg;
  reg transon;

  reg [7:0] num = 8'haa; // custom number

  assign tx = txreg;

  always @ (posedge clk) begin
    if (transmit) transon <= 1;
    if (transon) begin
      cnt <= cnt + 1;
      if (cnt % samplerate == 0) begin
        case (cnt / samplerate)
          0: txreg <= 0;
          1: txreg <= num[7];
          2: txreg <= num[6];
          3: txreg <= num[5];
          4: txreg <= num[4];
          5: txreg <= num[3];
          6: txreg <= num[2];
          7: txreg <= num[1];
          8: txreg <= num[0];
          9: begin
            txreg <= 1;
            cnt <= 0;
            transon <= 0;
          end
        endcase
      end
    end
  end
endmodule

module uart (
  input transon,
  input clk,
  input rx,
  output tx
);
  reciever recieverModule (.clk(clk), .rx(rx));
  transmitter transmitterModule (.clk(clk), .transmit(transon), .tx(tx));
endmodule