`default_nettype none
module hall_sensor_emulator (
        input  logic clk,
        /* verilator lint_off UNUSED*/
        input logic  clk_enable,
        input  logic nrst,
        output logic SOF
);

// Slice lenght in cycle
localparam SLICE_CYCLE = 10000;

integer slice_cycle_cnt;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        SOF <= '0;
        slice_cycle_cnt <= '0;
    end else begin
        SOF <= '0;
        slice_cycle_cnt <= slice_cycle_cnt + 1'b1;
        if(slice_cycle_cnt == SLICE_CYCLE) begin
            slice_cycle_cnt <= '0;
            // Signals that the position has changed
            SOF <= 1'b1;
        end
    end

endmodule
