module fifo_in #(parameter DATA_WIDTH = 9)
(
    input wire clk,
    input wire nrst,
    input logic[DATA_WIDTH-1:0] voxel_in
);

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    else
    begin
    end

endmodule
