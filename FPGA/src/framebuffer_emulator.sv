module framebuffer_emulator #(
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=72
)(
    input clk_33,
    input nrst,

    // Data and sync signal for the driver main controller
    output reg [29:0] data,
    output reg        sync
);

logic [10:0] clk_counter;
logic [2:0] mul_counter;
assign sync = clk_counter >= 512 && mul_counter == 0;

always_ff @(posedge clk_33)
    if(~nrst) begin
        clk_counter <= '0;
        mul_counter <= '0;
    end else begin
        clk_counter <= clk_counter + 1'b1;
        if(clk_counter == 512) begin
            mul_counter <= mul_counter + 1'b1;
        end
    end

// Heartbeat LED 33MHz
logic[24:0] heartbeat_counter_33;
logic d;
always_ff @(posedge clk_33)
	if(~nrst) begin
      d <= '0;
		heartbeat_counter_33 <= '0;
	end else begin
		heartbeat_counter_33 <= heartbeat_counter_33 + 1'b1;
		if(heartbeat_counter_33 == 65535*512) begin
			d <= ~d;
			heartbeat_counter_33 <= '0;
		end
	end
	
always_ff @(posedge clk_33)
    if(~nrst) begin
        data <= '0;
    end else begin
        data <= d ? '1 : '0;
    end

endmodule
