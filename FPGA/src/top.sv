module top #(parameter DATA_WIDTH = 48) (
   input logic clk,
   input logic nrst,
   input logic bit_in,
   output logic bit_out,
   output logic lat
);

driver_controller #(.DATA_WIDTH(DATA_WIDTH)) driver_1 (
    .clk(clk),
    .nrst(nrst),
    .bit_in(bit_in),
    .bit_out(bit_out),
    .lat(lat)
);

endmodule
