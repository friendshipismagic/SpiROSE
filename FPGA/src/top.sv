module top #(parameter DATA_WIDTH = 48) (
   input logic clk,
   input logic nrst,
   input logic bit_in,
   output logic sin,
   output logic lat,
   output logic gclk,
   output logic sclk
);

driver_controller #(.DATA_WIDTH(DATA_WIDTH)) driver_1 (
    .clk(clk),
    .nrst(nrst),
    .bit_in(bit_in),
    .sin(sin),
    .lat(lat),
    .gclk(gclk),
    .sclk(sclk)
);

endmodule
