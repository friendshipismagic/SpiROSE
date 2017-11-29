module framebuffer_emulator #(
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=80
)(
    input clk_33,
    input nrst,

    // Data and sync signal for the driver main controller
    output reg [29:0] data,
    output reg        sync
);

logic [8:0] clk_counter;
logic [2:0] mul_counter;
wire blanking;
assign blanking = clk_counter < BLANKING_CYCLES;
assign sync = clk_counter == 511 && mul_counter == 0;

always_ff @(posedge clk_33)
    if(~nrst) begin
        clk_counter <= '0;
        mul_counter <= '0;
    end else begin
        clk_counter <= clk_counter + 1'b1;
        if(clk_counter == 511) begin
            mul_counter <= mul_counter + 1'b1;
        end
    end

    always_ff @(posedge clk_33)
        if(~nrst) begin
            data <= '0;
        end else begin
            if(clk_counter >= BLANKING_CYCLES-1) begin
                data <= '1;
            end
        end

endmodule
