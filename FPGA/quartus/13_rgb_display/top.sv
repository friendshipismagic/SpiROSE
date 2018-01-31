// Copyright (C) 1991-2014 Altera Corporation
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

`default_nettype none

module Top
(
 // RGB
 input logic         rgb_clk,
 input logic         rgb_clk2,
 input logic         rgb_hsync,
 input logic         rgb_vsync,
 input logic [23:0]  rgb_d,

 // LVDS
 input logic [3:0]   lvds_tx_p,
 input logic [3:0]   lvds_tx_n,
 input logic         lvds_clk_p,
 input logic         lvds_clk_n,

 // Drivers
 output logic        drv_gclk_a,
 output logic        drv_gclk_b,
 output logic        drv_sclk_a,
 output logic        drv_sclk_b,
 output logic        drv_lat_a,
 output logic        drv_lat_b,
 output logic [29:0] drv_sin,
 output logic [7:0]  fpga_mul_a,
 output logic [7:0]  fpga_mul_b,

 // SPI
 input logic         som_cs,
 input logic         som_sclk,
 input logic         som_mosi,
 output logic        som_miso,

 // Hall sensors
 input logic [1:0]   hall,

 // Encoder
 input logic         encoder_A,
 input logic         encoder_B,
 input logic         encoder_C,
 input logic         encoder_D,

 // Test points
 output logic        pt_6,
 input logic         pt_39,
 output logic        pt_23,
 output logic        pt_24,
 output logic        pt_26,
 output logic        pt_27
);

// In this test, we assign predefined value to rotation data and
// check that SPI I/O is sending it back when asked
assign rotation_data = 'hBEEF;
assign speed_data = 'hDEAD;

// Clock generation
logic clk, fast_clk, slow_clk, locked, clk_select;
pll pll (
    .inclk0(rgb_clk),
    .c0(fast_clk),
    .c1(slow_clk),
    .locked(locked)
);

// Reset generation
logic spi_nrst_reg;
logic spi_nrst_reg2;
logic nrst;
assign nrst = locked && spi_nrst_reg2;

always @(posedge(clk)) begin
  spi_nrst_reg <= spi_nrst;
  spi_nrst_reg2 <= spi_nrst_reg;
end

assign clk = fast_clk;

logic clk_enable;
clock_enable clock_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

// Hall sensors
logic SOF;
hall_sensor_emulator main_hs_emulator (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .SOF(SOF)
);

// SBC SOM Interface
logic [439:0] data_mosi;
logic [10:0]  data_len_bytes;
logic [439:0]  data_miso;
logic         cmd_valid;
spi_iff spi_iff (
    .clk(clk),
    .nrst(nrst),
    // SPI physical interface signals
    .spi_clk(som_sclk),
    .spi_ss(som_cs),
    .spi_mosi(som_mosi),
    .spi_miso(som_miso),
    // Data signals to SPI decoder
    .data_mosi(data_mosi),
    .data_miso(data_miso),
    .data_len_bytes(data_len_bytes),
    .valid(cmd_valid)
);

logic [431:0] spi_debug_driver;
logic         spi_debug_driver_poker_mode;
logic [15:0]  rotation_data;
logic [15:0]  speed_data;
logic         rgb_enable;
logic [47:0]  driver_conf;
logic         start_config;
logic         spi_manage_mux;
logic [7:0]   spi_mux_state;
logic [7:0]   spi_ram_driver;
logic [7:0]   spi_ram_offset;
logic [23:0]  spi_pixel_data;
logic         spi_SOL;
logic [23:0]  spi_ram_raddr;
logic [23:0]  spi_ram_rdata;
logic         spi_nrst;
spi_decoder spi_decoder (
    .clk(clk),
    .nrst(nrst),
    // Data signals from spi_iff
    .data_mosi(data_mosi),
    .data_miso(data_miso),
    .data_len_bytes(data_len_bytes),
    .valid(cmd_valid),
    // Hall sensor effect signal
    .rotation_data(rotation_data),
    .speed_data(speed_data),
    // Driver controller signal
    .configuration(driver_conf),
    .new_config_available(start_config),
    // Display control to rgb_logic
    .rgb_enable(rgb_enable),
    // 431bit signal with full column driver data
    .debug_driver(spi_debug_driver),
    .debug_driver_poker_mode(spi_debug_driver_poker_mode),
    // Managing signals for debugging mux
    .manage_mux(spi_manage_mux),
    .mux(spi_mux_state),
    // RAM write output
    .ram_driver(spi_ram_driver),
    .ram_offset(spi_ram_offset),
    .ram_raddr(spi_ram_raddr),
    .ram_rdata(spi_ram_rdata),
    .pixel(spi_pixel_data),
    .SOL(spi_SOL),
    .spi_nrst(spi_nrst)
);

// RGB logic
logic [23:0] rgb_pixel_data;
logic        rgb_pixel_valid;
logic  [3:0] rgb_pixel_col;
logic  [4:0] rgb_pixel_line;
logic  [2:0] rgb_block_col;
logic  [1:0] rgb_block_line;
rgb_logic rgb_logic(
	.rgb_clk(rgb_clk), .nrst(nrst),

	// RGB data
	.rgb(rgb_d), .hsync(rgb_hsync), .vsync(rgb_vsync),

	// Output
	.pixel_data(rgb_pixel_data),
	.pixel_valid(rgb_pixel_valid),
	.pixel_col(rgb_pixel_col), .pixel_line(rgb_pixel_line),
	.block_col(rgb_block_col), .block_line(rgb_block_line),

	// RGB enable
	.rgb_enable(rgb_enable_sync)
);

// Sync RGB logic to main clock
logic [23:0] rgb_pixel_data_sync;
logic        rgb_pixel_valid_sync;
logic  [3:0] rgb_pixel_col_sync;
logic  [4:0] rgb_pixel_line_sync;
logic  [2:0] rgb_block_col_sync;
logic  [1:0] rgb_block_line_sync;
logic        rgb_enable_sync;
sync_sig #(.SIZE(24)) sync_sig_rgb_pixel_data (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_pixel_data), .out_sig(rgb_pixel_data_sync)
);
sync_sig sync_sig_rgb_pixel_valid (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_pixel_valid), .out_sig(rgb_pixel_valid_sync)
);
sync_sig #(.SIZE(4)) sync_sig_rgb_pixel_col (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_pixel_col), .out_sig(rgb_pixel_col_sync)
);
sync_sig #(.SIZE(5)) sync_sig_rgb_pixel_line (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_pixel_line), .out_sig(rgb_pixel_line_sync)
);
sync_sig #(.SIZE(3)) sync_sig_rgb_block_col (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_block_col), .out_sig(rgb_block_col_sync)
);
sync_sig #(.SIZE(2)) sync_sig_rgb_block_line (
	.clk(clk), .nrst(nrst),
	.in_sig(rgb_block_line), .out_sig(rgb_block_line_sync)
);
sync_sig sync_sig_rgb_enable (
	.clk(rgb_clk), .nrst(nrst),
	.in_sig(rgb_enable), .out_sig(rgb_enable_sync)
);

// RAM, framebuffer and poker formatter for the 15 blocks
logic drivers_SOF;
logic [431:0] data_pokered [14:0];
ram_15 ram_15 (
   .clk(clk),
   .nrst(nrst),
   .clk_enable(clk_enable),
   // RAM input (TODO: from SPI, will be from RGB after)
   .block_number(spi_ram_driver),
   .pixel_number(spi_ram_offset),
   .ram_data(spi_pixel_data),
   .block_write_enable(spi_SOL),
   // Control inputs from driver_controller
   .EOC(EOC),
   .SOF(SOF),
   // Framebuffer outputs
   .data_pokered(data_pokered),
   .drivers_SOF(drivers_SOF)
);

// Bypass multiplexer
logic [431:0] driver_data [14:0];
always_comb begin
    for(int i=0; i<15; ++i) begin
        driver_data[i] = spi_debug_driver_poker_mode ? spi_debug_driver : data_pokered[i];
    end
end

logic [431:0] data_reordered [14:0];
color_lut color_lut (
    .data_in(driver_data),
    .data_out(data_reordered)
);


logic driver_sclk;
logic driver_gclk;
logic driver_lat;
logic [29:0] drivers_sin;
logic [7:0] mux_out;
logic EOC;
logic end_config;
driver_controller driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .driver_sclk(driver_sclk),
    .driver_gclk(driver_gclk),
    .driver_lat(driver_lat),
    .drivers_sin(drivers_sin),
    .mux_out(mux_out),
    .SOF(drivers_SOF),
    .EOC(EOC),
    .data(data_reordered),
    .config_data(driver_conf),
    .start_config(start_config),
    .end_config(end_config),
    .debug({pt_6, pt_23, pt_24, pt_26})
);

driver_sin_lut main_drv_sin_lut (
    .drv_sin_tolut(drivers_sin),
    .drv_sin(drv_sin)
);

assign fpga_mul_a = spi_manage_mux ? spi_mux_state : {mux_out[0],
                                                      mux_out[1],
                                                      mux_out[2],
                                                      mux_out[3],
                                                      mux_out[4],
                                                      mux_out[5],
                                                      mux_out[6],
                                                      mux_out[7]};
assign fpga_mul_b = spi_manage_mux ? spi_mux_state : mux_out;
assign drv_gclk_a = driver_gclk;
assign drv_gclk_b = driver_gclk;
assign drv_sclk_a = driver_sclk;
assign drv_sclk_b = driver_sclk;
assign drv_lat_a = driver_lat;
assign drv_lat_b = driver_lat;

endmodule
