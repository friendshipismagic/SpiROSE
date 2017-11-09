module top #(parameter DATA_WIDTH = 48) (
   input logic clk,
   input logic nrst,
   input logic [DATA_WIDTH - 1:0] bit_group_in,
   output logic [DATA_WIDTH - 1:0] bit_group_out,
   output logic lat
);

driver_controller #(.DATA_WIDTH(DATA_WIDTH)) driver_1 (
    .clk(clk),
    .nrst(nrst),
    .bit_group_in(bit_group_in),
    .bit_group_out(bit_group_out),
    .lat(lat)
);

endmodule
