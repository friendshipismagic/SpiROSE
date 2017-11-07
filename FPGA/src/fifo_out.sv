module fifo_out #(parameter DATA_WIDTH = 9)
(
    input wire clk,
    input wire nrst,
    output logic[DATA_WIDTH-1:0] voxel_out
);

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
        lat <= 0;
    else
    begin
    end

endmodule
