// DRIVE_TIME is in µs
// CAUTION: the LEDs overdrive cannot exceed 10µs at full value
module mux #(parameter DRIVE_TIME = 10)
(
   input clk_50,
   input nrst,

   output [7:0] mux_out
)

// Convert the drive time into clock cycles
localparam DRIVE_CLOCK_CYCLES = DRIVE_TIME / 0.02;

/*
 * Counter for switching. 50 MHz (20ns) clock is used, the multiplexing can go
 * up to DRIVE_CLOCK_CYCLES.
 */
logic [$clog2(DRIVE_CLOCK_CYCLES)-1:0] switch_counter;

always_ff @(posedge clk_50 or negedge nrst)
   if(~nrst) begin
      err <= 1'b0;
      switch_counter <= '0;
   end else begin
      switch_counter <= switch_counter + 1'b1;
      if(switch_counter == DRIVE_CLOCK_CYCLES) begin
         switch_counter <= '0;
      end

   end

always_ff @(posedge clk_50 or negedge nrst)
   if(~nrst) begin
      mux <= 8'b0;
   end else begin
      if(switch_counter == '0) begin
         case(mux)
            8'b00000000: mux <= 8'b00000001;
            8'b00000001: mux <= 8'b00000010;
            8'b00000010: mux <= 8'b00000100;
            8'b00000100: mux <= 8'b00001000;
            8'b00001000: mux <= 8'b00010000;
            8'b00010000: mux <= 8'b00100000;
            8'b00100000: mux <= 8'b01000000;
            8'b01000000: mux <= 8'b10000000;
            8'b10000000: mux <= 8'b00000001;
         endcase
      end
   end

endmodule
