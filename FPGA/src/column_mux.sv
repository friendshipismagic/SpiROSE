// DRIVE_TIME is in µs
// CAUTION: the LEDs overdrive cannot exceed 10µs at full value
// Parameters to change
module column_mux
(
   input clk,
   input nrst,
   input column_ready,
   output reg [7:0] mux_out
);

/*
 * Convert the drive time into clock cycles. 15 ns ~ 66MHz
 * 660 cycles corresponds to 10 µs display time
 */
localparam DRIVE_CLOCK_CYCLES = 660;

/*
 * Current 'value', between 0 and 7 (included).
 * This is the column to turn on.
 */
integer disp_value;

/*
 * Mux possible states:
 * WAIT_COLUMN_READY is a state where the mux should wait for the framebuffer_sync
 * DISP is a state where one column is on
 */
enum logic {WAIT_COLUMN_READY, DISP} mux_state;
integer mux_state_counter;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        mux_state <= WAIT_COLUMN_READY;
        mux_state_counter <= '0;
        disp_value <= '0;
    end else begin
        case(mux_state)
            WAIT_COLUMN_READY: begin
                mux_state_counter <= '0;
                if(column_ready) begin
                    mux_state <= DISP;
                end
            end
            DISP: begin
                mux_state_counter <= mux_state_counter + 1'b1;
                // Remove one clock cycle per transition
                if(mux_state_counter == DRIVE_CLOCK_CYCLES - 1) begin
                    mux_state_counter <= '0;
                    mux_state <= WAIT_COLUMN_READY;
                    // Change column for next time
                    disp_value <= disp_value + 1'b1;
                    if(disp_value == 7) begin
                        disp_value <= '0;
                    end
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
        mux_out = 8'b0;
    end else begin
        mux_out = '0;
        if(mux_state == DISP) begin
            // Don't turn on if module not enabled, or in anti ghosting mode
            mux_out = 1'b1 << disp_value;
        end
    end

endmodule
