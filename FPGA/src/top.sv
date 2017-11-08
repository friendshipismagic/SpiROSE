module top #(parameter DATA_WIDTH = 27) (
   input logic clk,
   input logic nrst,
   input logic [DATA_WIDTH - 1:0] voxel_in,
   output logic [DATA_WIDTH - 1:0] voxel_out,
   output logic lat
);

driver #(.DATA_WIDTH(DATA_WIDTH)) driver_1 (.clk(clk),
                                            .nrst(nrst),
                                            .voxel_in(voxel_in),
                                            .voxel_out(voxel_out),
                                            .lat(lat));

endmodule
