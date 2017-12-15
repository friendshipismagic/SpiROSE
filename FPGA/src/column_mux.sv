// DRIVE_TIME is in µs
// CAUTION: the LEDs overdrive cannot exceed 10µs at full value
module column_mux #(parameter DRIVE_TIME = 'd10)
(
   input clk_33,
   input nrst,

   output reg [7:0] mux_out
);

// Convert the drive time into clock cycles. 30 ns ~ 33.33MHz
localparam DRIVE_CLOCK_CYCLES = 330;
localparam DRIVE_CLOCK_BITS = $clog2(DRIVE_CLOCK_CYCLES);

/*
 * Counter for switching. 33 MHz (30ns) clock is used, the multiplexing can go
 * up to DRIVE_CLOCK_CYCLES.
 */
logic [DRIVE_CLOCK_BITS - 1:0] switch_counter;

always_ff @(posedge clk_33)
   if(~nrst) begin
      switch_counter <= '0;
   end else begin
      switch_counter <= switch_counter + 1'b1;
      if(switch_counter == DRIVE_CLOCK_BITS'(DRIVE_CLOCK_CYCLES)) begin
         switch_counter <= '0;
      end
   end

always_ff @(posedge clk_33)
   if(~nrst) begin
      mux_out <= 8'b0;
   end else begin
      if(switch_counter == '0) begin
         case(mux_out)
            8'b00000000: mux_out <= 8'b00000001;
            8'b00000001: mux_out <= 8'b00000010;
            8'b00000010: mux_out <= 8'b00000100;
            8'b00000100: mux_out <= 8'b00001000;
            8'b00001000: mux_out <= 8'b00010000;
            8'b00010000: mux_out <= 8'b00100000;
            8'b00100000: mux_out <= 8'b01000000;
            8'b01000000: mux_out <= 8'b10000000;
            8'b10000000: mux_out <= 8'b00000001;
            default:mux_out <= 8'b0;
         endcase
      end
   end

endmodule
