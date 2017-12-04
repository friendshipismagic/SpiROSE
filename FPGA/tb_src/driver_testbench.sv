module driver_testbench ();

logic clk_33;
logic nrst;
logic gclk, sclk;
logic lat;
logic [29:0] sin;
logic sout;
logic [4:0] sout_mux;
logic [29:0] framebuffer_data;
logic framebuffer_sync;

// 33 MHz clock generator
always #30ns clk_33 <= ~clk_33;

/*
 * Default configuration for drivers
 * To change the default configuration, please go to drivers_conf.sv
 */
`include "drivers_conf.sv"

// Framebuffer emulator, to test driver controller
framebuffer_emulator #(.POKER_MODE(9), .BLANKING_CYCLES(80)) main_fb_emulator (
	.clk_33(clk_33),
	.nrst(nrst),
	.data(framebuffer_data),
	.sync(framebuffer_sync)
);

// Device Under Test
driver_controller #(.BLANKING_TIME(80)) dut (
    .clk_hse(clk_33),
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

// Simulation process
initial
begin
	clk_33 = 0;
    nrst = 0;
    sout = 0;

	// Wait 1 clock cycle for reset
	@(posedge clk_33);

	// Start DUT
	nrst = 1;

	// Wait for configuration + start of first frame
	repeat(2000) @(posedge clk_33);

    $display("Everything went fine");
    $finish;
end

endmodule
