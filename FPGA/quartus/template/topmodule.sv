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

module project_name
(
    input       rgb_clk;
    input       rgb_hsync;
    input       rgb_vsync;
    input       fpga_gclk_a;
    input       drv_sout_data;
    input       fpga_sclk_a;
    input       fpga_lat_a;
    input       som_mosi;
    input       som_miso;
    input       som_sclk;
    input       som_cs;
    input       fpga_gclk_b;
    input       fpga_sclk_b;
    input       fpga_lat_b;
    input[0:23] rgb_d;
    input[0:29] drv_sin;
    input[0:7]  fpga_mul_b;
    input[0:7]  fpga_mul_a;
    input[0:1]  hall;
    input[0:3]  lvds_tx_p;
    input[0:3]  lvds_tx_n;
);

// Put your code here

endmodule

