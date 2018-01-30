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

logic clk, nrst;

// spi_iff output signals
logic [439:0] data_mosi;
logic [10:0]  data_len_bytes;
logic [47:0] data_miso;
logic        cmd_valid;

// spi_decoder I/O signals
logic [15:0] rotation_data;
logic [15:0] speed_data;
logic        rgb_enable;

// driver_controller signals
logic clk_enable;
logic driver_sclk;
logic driver_gclk;
logic driver_lat;
logic [29:0] drivers_sin;
logic SOF;
logic EOC;
logic [47:0] driver_conf;
logic start_config;
logic end_config;

// Spi debug signals
logic spi_manage;
logic [7:0] spi_mux_state;

// In this test, we assign predefined value to rotation data and
// check that SPI I/O is sending it back when asked
assign rotation_data = 'hBEEF;
assign speed_data = 'hDEAD;

// Column mux signals
logic [7:0] mux_out;

assign fpga_mul_a = spi_manage ? spi_mux_state : mux_out;
assign fpga_mul_b = spi_manage ? spi_mux_state : mux_out;
assign drv_gclk_a = driver_gclk;
assign drv_gclk_b = driver_gclk;
assign drv_sclk_a = driver_sclk;
assign drv_sclk_b = driver_sclk;
assign drv_lat_a = driver_lat;
assign drv_lat_b = driver_lat;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    .c0(clk),
    .locked(nrst)
);

clock_enable clock_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

hall_sensor_emulator main_hs_emulator (
    .clk(clk_enable),
    .nrst(nrst),
    .SOF(SOF)
);

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
logic         spi_debug_driver_override_lut;
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
    .debug_driver_override_lut(spi_debug_driver_override_lut),
    // Managing signals for debugging mux
    .manage(spi_manage),
    .mux(spi_mux_state)
);

logic [431:0] data_pokered;
framebuffer_poker_lut framebuffer_poker_lut (
    .data_in(spi_debug_driver),
    .data_out(data_pokered)
);

logic [431:0] driver_data [14:0];
always_comb begin
    for(int i=0; i<15; ++i) begin
        driver_data[i] = spi_debug_driver_override_lut ? spi_debug_driver : data_pokered;
    end
end

logic [431:0] data_reordered [14:0];
color_lut color_lut (
    .data_in(driver_data),
    .data_out(data_reordered)
);

driver_controller driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .driver_sclk(driver_sclk),
    .driver_gclk(driver_gclk),
    .driver_lat(driver_lat),
    .drivers_sin(drivers_sin),
    .mux_out(mux_out),
    .SOF(SOF),
    .EOC(EOC),
    .data(data_reordered),
    .config_data(driver_conf),
    .start_config(start_config),
    .end_config(end_config),
    .debug({pt_6, pt_23, pt_24, pt_26})
);

logic [29:0] drv_sin_tolut;
driver_sin_lut main_drv_sin_lut (
    .drv_sin_tolut(drivers_sin),
    .drv_sin(drv_sin)
);

endmodule

