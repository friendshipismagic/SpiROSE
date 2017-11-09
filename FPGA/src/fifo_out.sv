module fifo_out #(parameter DATA_WIDTH = 27)
(
    input wire clk,
    input wire nrst,
    output logic[DATA_WIDTH-1:0] voxel_out
);

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    else
    begin
    end

endmodule
