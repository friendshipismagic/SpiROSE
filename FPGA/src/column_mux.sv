// DRIVE_TIME is in µs
// CAUTION: the LEDs overdrive cannot exceed 10µs at full value
// Parameters to change
module column_mux #(
   parameter SYNC_TO_FIRST_COL_TIME=10,
   parameter COLUMN_DISP_TIME=10,
   parameter ANTIGHOSTING_TIME=10
) (
   input clk_33,
   input nrst,
   input framebuffer_sync,
   input enable,

   output reg [7:0] mux_out
);

// Convert the drive time into clock cycles. 30 ns ~ 33.33MHz
localparam DRIVE_CLOCK_CYCLES = 330;
localparam DRIVE_CLOCK_BITS = $clog2(DRIVE_CLOCK_CYCLES);

/*
 * Current 'value', between 0 and 7 (included).
 * This is the column to turn on.
 */
logic [2:0] disp_value;

/*
 * Mux possible states:
 * WAIT_FOR_SYNC is a state where the mux should wait for the framebuffer_sync
 * WAIT_BEFORE_START is a state to wait before displaying the first column
 * DISP is a state where one column is on
 * WAIT_BETWEEN_DISP is a state where the columns are off to remove ghosting
 */
enum logic[1:0] {WAIT_FOR_SYNC, WAIT_BEFORE_START, DISP, WAIT_BETWEEN_DISP} mux_state;
logic [7:0] mux_state_counter;
always_ff @(posedge clk_33 or negedge nrst)
   if(~nrst) begin
      mux_state <= WAIT_FOR_SYNC;
      mux_state_counter <= '0;
      disp_value <= '0;
   end else begin
      case(mux_state)
         WAIT_FOR_SYNC: begin
            if(framebuffer_sync) begin
               mux_state <= WAIT_BEFORE_START;
            end
         end
         WAIT_BEFORE_START: begin
            mux_state_counter <= mux_state_counter + 1'b1;
            // Remove one clock cycle per transition
            if(mux_state_counter == SYNC_TO_FIRST_COL_TIME - 1) begin
               mux_state <= DISP;
               mux_state_counter <= '0;
            end
         end
         DISP: begin
            mux_state_counter <= mux_state_counter + 1'b1;
            // Remove one clock cycle per transition
            if(mux_state_counter == COLUMN_DISP_TIME - 1) begin
               mux_state <= WAIT_BETWEEN_DISP;
               mux_state_counter <= '0;
               // Change column for next time
               disp_value <= disp_value + 1'b1;
               if(disp_value == 7) begin
                  disp_value <= '0;
               end
            end
         end
         WAIT_BETWEEN_DISP: begin
            mux_state_counter <= mux_state_counter + 1'b1;
            // Remove one clock cycle per transition
            if(mux_state_counter == ANTIGHOSTING_TIME - 1) begin
               mux_state <= DISP;
               mux_state_counter <= '0;
            end
         end
	 endcase
   end

/*
* Assign the output mux to the right value : disp_value is the column number,
* mux_out is the 8 columns output.
*/
always_comb
   if(~nrst) begin
      assign mux_out = 8'b0;
   end else begin
      if(disp_value == '0) begin
         assign mux_out = '0;
      end else if(enable || (mux_state == DISP)) begin
         // Don't turn on if module not enabled, or in anti ghosting mode
         assign mux_out = 1'b1 << (disp_value - 1);
      end
   end

endmodule
