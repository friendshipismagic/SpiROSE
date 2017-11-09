module driver_controller #(parameter MULTIPLEXING = 8,
                           parameter POKER_MODE = 9,
                           parameter DATA_WIDTH = 48)
(
    input wire clk,
    input wire nrst,
    input logic[DATA_WIDTH-1:0] bit_group_in,
    output logic[DATA_WIDTH-1:0] bit_group_out,
    output logic lat
);

logic[$clog2(POKER_MODE)-1:0] bit_group_count;

always_ff@(posedge clk or negedge nrst)
    if(!nrst)
    begin
        lat <= 0;
        bit_group_out <= 0;
        bit_group_count <= 0;
    end
    else
    begin
        lat <= 0;
        bit_group_out <= bit_group_in;
        bit_group_count <= bit_group_count + 1;
        if(bit_group_count == POKER_MODE-1)
        begin
            bit_group_count <= 0;
            lat <= 1;
        end
    end

endmodule
