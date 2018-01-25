module hall_sensor_emulator (
        input clk,
        input nrst,
        output position_sync
);

// Slice lenght in cycle
localparam SLICE_CYCLE = 5000;

integer slice_cycle_cnt;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        position_sync <= '0;
        slice_cycle_cnt <= '0;
    end else begin
        position_sync <= '0;
        slice_cycle_cnt <= slice_cycle_cnt + 1'b1;
        if(slice_cycle_cnt == SLICE_CYCLE) begin
            slice_cycle_cnt <= '0;
            // Signals that the position has changed
            position_sync <= 1'b1;
        end
    end

endmodule
