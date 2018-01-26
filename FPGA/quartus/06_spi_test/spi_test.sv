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

module spi_test
(
    input       rgb_clk,
    input       pt_39,
    output      pt_6,

    /*
    *  SoM SPI I/O
    */
    output      som_miso,
    input       som_mosi,
    input       som_clk,
    input       som_cs
);


logic clk, nrst;

// spi_iff output signals
logic [63:0] cmd_read;
logic [3:0]  cmd_len_bytes;
logic [47:0] cmd_write;
logic        cmd_valid;

// spi_decoder I/O signals
logic [15:0] rotation_data;
logic [47:0] driver_conf;
logic        driver_new_conf_available;
logic        rgb_enable;

// In this test, we assign predefined value to rotation data and
// check that SPI I/O is sending it back when asked
assign rotation_data = 'hBEEF;

always_ff @(posedge clk)
    pt_6 <= ~pt_6;

spi_iff spi_iff (
    .clk(clk),
    .nrst(nrst),
    // SPI I/O signals
    .spi_clk(som_clk),
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
    .rgb_enable(rgb_enable)
);

endmodule

