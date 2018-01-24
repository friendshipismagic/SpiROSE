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

module rgb_pll
(
    input       rgb_clk,
    output      pt_6,
    output      pt_26,
    output      pt_23
);

logic clk66;
logic locked;

assign pt_6 = clk66;
assign pt_23 = rgb_clk;
assign pt_26 = locked;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    // Main 33 MHz clock
    .c0(clk66),
    .locked(locked)
);

endmodule

