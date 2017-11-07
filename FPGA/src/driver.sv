module driver #(parameter MULTIPLEXING = 8, parameter CHANNELS = 48, parameter DATA_WIDTH = 9)
(
    input wire clk,
    input wire nrst,
    input logic[DATA_WIDTH-1:0] voxel_in,
    output logic[DATA_WIDTH-1:0] voxel_out,
    output logic lat
);

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
        lat <= 0;
    else
    begin
    end

endmodule
