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
    input       pt_39,
    output      pt_6
);

logic clk66;
assign pt_6 = clk66;

logic locked;

clock_66 main_clock_66 (
    .inclk0(pt_39),
    // Main 33 MHz clock
    .c0(clk66),
    .locked(locked)
);

logic [32:0] counter;

// Counter process that outputs a 1 kHz clock
always_ff @(posedge clk66)
    if (counter >= 66000) begin
        counter <= 1;
    end else begin
        counter <= counter + 1;
    end

endmodule

