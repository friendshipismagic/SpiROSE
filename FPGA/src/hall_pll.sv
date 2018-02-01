`default_nettype none
module hall_pll (
    input        clk,
    input        nrst,

    input [31:0] speed_data,
    input        start_of_turn,

    /*
     * Slice that is meant to be displayed (over a full 256-slice turn).
     * It is the slice counted after the Hall effect sensor 1 (arbitrarily)
     * is triggered.
     */
    output logic [6:0] slice_cnt,
    output logic position_sync
);

integer ticks_per_frame;
integer ticks_counter;
integer position_sync_guard;

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        position_sync_guard <= '0;
    end else begin
        if(start_of_turn) begin
            position_sync_guard <= 1;
        end else if(position_sync_guard > 0) begin
            position_sync_guard <= position_sync_guard + 1'b1;
            if(position_sync_guard == 32) begin
                position_sync_guard <= '0;
            end
        end
    end

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        ticks_per_frame <= 0;
        ticks_counter <= 0;
        slice_cnt <= '0;
        position_sync <= '0;
    end else begin
        if (start_of_turn) begin
            ticks_per_frame <= speed_data >> 7;
            ticks_counter <= 1;
            slice_cnt <= '0;
        end else if(position_sync_guard == 32) begin
            position_sync <= 1;
        end else if (ticks_counter == ticks_per_frame) begin
            ticks_counter <= 1;
            slice_cnt <= slice_cnt + 1;
            position_sync <= '1;
        end else begin
            ticks_counter <= ticks_counter + 1;
            position_sync <= '0;
        end
    end

endmodule
