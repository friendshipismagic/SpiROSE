module driver #(parameter MULTIPLEXING = 8, parameter CHANNELS = 48, parameter DATA_WIDTH = 27)
(
    input wire clk,
    input wire nrst,
    input logic[DATA_WIDTH-1:0] voxel_in,
    output logic[DATA_WIDTH-1:0] voxel_out,
    output logic lat
);

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    begin
        lat <= 0;
        voxel_out <= 0;
    end
    else
    begin
        voxel_out <= voxel_in;
    end

endmodule
