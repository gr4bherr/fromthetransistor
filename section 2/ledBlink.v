module ledBlink (
  input clk,
  output led
);
  reg [15:0] counter = 0;
  reg state = 0;

  assign led = state;

  always @ (posedge clk) begin
    counter <= counter + 1;

    // blink once per second
    if (counter == 16'd25_000) begin 
      state <= ~state;
      counter <= 0;
    end
  end
endmodule