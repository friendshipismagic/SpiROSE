//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

module driver_testbench ();

logic clk_33;
logic clk_66;
logic nrst;
logic gclk, sclk;
logic lat;
logic [29:0] sin;
logic sout;
logic [4:0] sout_mux;
logic [29:0] framebuffer_data;
logic framebuffer_sync;
logic [7:0] mux_out;

// 66 MHz clock generator
always #15ns clk_66 <= ~clk_66;

/*
 * Default configuration for drivers
 * To change the default configuration, please go to drivers_conf.sv
 */
`include "drivers_conf.sv"

// Framebuffer emulator, to test driver controller
framebuffer_emulator #(.POKER_MODE(9), .BLANKING_CYCLES(72)) main_fb_emulator (
	.clk_33(clk_33),
	.nrst(nrst),
	.data(framebuffer_data),
	.sync(framebuffer_sync)
);

// Device Under Test
driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk_hse(clk_66),
    .clk_lse(clk_33),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_data),
    .framebuffer_sync(framebuffer_sync),
    .driver_sclk(sclk),
    .driver_gclk(gclk),
    .driver_lat(lat),
    .drivers_sin(sin),
    .driver_sout(sout),
    .driver_sout_mux(sout_mux),
    .serialized_conf(serialized_conf)
);

column_mux main_column_mux (
	.clk_33(clk_33),
	.nrst(nrst),
	.framebuffer_sync(framebuffer_sync),
	.enable(nrst),
	.mux_out(mux_out)
);

clock_lse #(.INVERSE_PHASE(1)) clk_lse_gen (
    .clk_hse(clk_66),
    .nrst(nrst),
    .clk_lse(clk_33)
);

// Simulation process
initial
begin
	clk_66 = 0;
    nrst = 0;
    sout = 0;

	// Wait 2 clock cycle for reset
	@(posedge clk_66);
	@(posedge clk_66);

	// Start DUT
	nrst = 1;

	// Wait for configuration + start of first frame
	repeat(3000) @(posedge clk_33);

    $display("Everything went fine");
    $finish;
end

endmodule
