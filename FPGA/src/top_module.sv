module top_module (
	input clk_50, 
	input nrst,

	// RGB bus
	input [23:0] rgb,
	input hsync, vsync, rgb_clk, 
	
	// Driver output
	output sclk, 
	output lat,
	output [29:0] sin,
	
	//Columns multiplexers
	output [7:0] mux_out,
	
	// UART
	input rx,
	output tx,
	
	// Encoder
	input enc0, enc1
	);

	// Driver output
	always @(posedge clk_50)
		if(~nrst) begin
			sclk <= 1'b0;
			lat <= 1'b0;
			sin <= 30'b0;
		end else begin
			sclk <= 1'b0;
			lat <= 1'b0;
			sin <= 30'b0;
		end

	// UART
	always @(posedge clk_50)
		if(~nrst) begin
			tx <= 1'b0;
		end else begin
			tx <= rx;
		end
	
endmodule
