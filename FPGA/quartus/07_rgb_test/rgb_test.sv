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
 input logic [7:0]   fpga_mul_a,
 input logic [7:0]   fpga_mul_b,

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
logic [55:0] cmd_read;
logic [2:0]  cmd_len_bytes;
logic [47:0] cmd_write;
logic        cmd_valid;

// spi_decoder I/O signals
logic [15:0] rotation_data;
logic [47:0] driver_conf;
logic        driver_new_conf_available;
logic        rgb_enable;
logic [31:0] debug_data;

// Clock domains crossings
logic        hsync, vsync;
logic [23:0] data;
sync_sig sync_hsync (.nrst(nrst), .clk(clk), .in_sig(rgb_hsync), .out_sig(hsync));
sync_sig sync_vsync (.nrst(nrst), .clk(clk), .in_sig(rgb_vsync), .out_sig(vsync));
sync_sig #(.SIZE(32)) sync_data (
    .nrst(nrst),
    .clk(clk),
    .in_sig(rgb_d),
    .out_sig(data)
);

// In this test, we read the first pixel of the image and send it in the debug
// buffer.
logic last_hsync, last_vsync;
always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        last_hsync <= 0;
        last_vsync <= 0;
        debug_data <= 32'h0;
    end else begin
        // Update hsync and vsync
        last_hsync <= hsync;
        last_vsync <= vsync;

        if (~last_hsync && hsync && ~last_vsync && vsync) begin
            debug_data[23:0] <= data;
        end
    end

always_ff @(posedge clk)
    pt_6 <= ~pt_6;


clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    .c0(clk),
    .locked(nrst)
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
    .new_config_available(driver_new_conf_available),
    .rgb_enable(rgb_enable),
    .debug_data(debug_data)
);

endmodule
