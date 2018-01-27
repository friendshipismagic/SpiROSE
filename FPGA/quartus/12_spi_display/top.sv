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
logic [63:0] cmd_read;
logic [3:0]  cmd_len_bytes;
logic [47:0] cmd_write;
logic        cmd_valid;

// spi_decoder I/O signals
logic [15:0] rotation_data;
logic [15:0] speed_data;
logic        rgb_enable;
logic [7:0]  mux_command;
logic [47:0] driver_data [29:0];

// driver_controller signals
logic clk_enable;
logic driver_sclk;
logic driver_gclk;
logic driver_lat;
logic [29:0] drivers_sin;
logic position_sync;
logic column_ready;
logic driver_ready;
logic [47:0] driver_conf;
logic new_configuration_ready;

// In this test, we assign predefined value to rotation data and
// check that SPI I/O is sending it back when asked
assign rotation_data = 'hBEEF;
assign speed_data = 'hDEAD;

// Column mux signals
logic [7:0] mux_statuses;

assign fpga_mul_a = mux_statuses & mux_command;
assign fpga_mul_b = mux_statuses & mux_command;
assign drv_gclk_a = driver_gclk;
assign drv_gclk_b = driver_gclk;
assign drv_sclk_a = driver_sclk;
assign drv_sclk_b = driver_sclk;
assign drv_lat_a = driver_lat;
assign drv_lat_b = driver_lat;


always_ff @(posedge clk)
    pt_6 <= ~pt_6;


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
    .position_sync(position_sync)
);

spi_iff spi_iff (
    .clk(clk),
    .nrst(nrst),
    // SPI I/O signals
    .spi_clk(som_sclk),
    .spi_ss(som_cs),
    .spi_mosi(som_mosi),
    .spi_miso(som_miso),
    // Data signals
    .cmd_read(cmd_read),
    .cmd_write(cmd_write),
    .cmd_len_bytes(cmd_len_bytes),
    .valid(cmd_valid)
);

spi_decoder spi_decoder (
    .clk(clk),
    .nrst(nrst),
    // SPI output signals
    .cmd_read(cmd_read),
    .cmd_write(cmd_write),
    .cmd_len_bytes(cmd_len_bytes),
    .valid(cmd_valid),
    // FPGA state signals
    .rotation_data(rotation_data),
    .configuration(driver_conf),
    .new_config_available(new_configuration_ready),
    .rgb_enable(rgb_enable),
    .mux(mux_command),
    .driver_data(driver_data)
);

logic [47:0] data_in [29:0];
assign data_in[0] = 48'b111_111_000_000_000_000_000_000_000_000_000_000_000_000_000_000;
driver_controller_spi_driven driver_controller (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable),
    .driver_sclk(driver_sclk),
    .driver_gclk(driver_gclk),
    .driver_lat(driver_lat),
    .drivers_sin(drivers_sin),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .driver_ready(driver_ready),
    .serialized_conf(driver_conf),
    .data_in(driver_data),
    .new_configuration_ready(new_configuration_ready)
);

logic [29:0] drv_sin_tolut;
driver_sin_lut main_drv_sin_lut (
    .drv_sin_tolut(drivers_sin),
    .drv_sin(drv_sin)
);


column_mux column_mux (
    .clk(clk),
    .nrst(nrst),
    .mux_out(mux_statuses),
    .column_ready(column_ready)
);

endmodule

