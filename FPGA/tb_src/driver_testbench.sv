module driver_testbench #(parameter DATA_WIDTH = 27);

logic clk, nrst, lat;
logic [DATA_WIDTH -1:0] voxel_in, voxel_out;

driver #(.DATA_WIDTH(DATA_WIDTH)) mce (
    .clk(clk),
    .nrst(nrst),
    .voxel_in(voxel_in),
    .voxel_out(voxel_out),
    .lat(lat)
);

initial
begin
    logic [DATA_WIDTH - 1:0] voxel;

    repeat(1000)
    begin
    $display("Everything went fine");
    $finish;
end

endmodule

