// Copyright (C) 1991-2013 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, Altera MegaCore Function License 
// Agreement, or other applicable license agreement, including, 
// without limitation, that your use is for the sole purpose of 
// programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the 
// applicable agreement for further details.

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
	output [7:0] mux,
	
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
			sin <= '0;
		end

	// Column multiplexers
	always @(posedge clk_50)
		if(~nrst) begin
			mux <= 8'b0;
		end else begin
			mux <= 8'b0;
		end

	// UART
	always @(posedge clk_50)
		if(~nrst) begin
			tx <= 1'b0;
		end else begin
			tx <= rx;
		end
	
endmodule
