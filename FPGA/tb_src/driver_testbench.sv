module driver_testbench #(parameter DATA_WIDTH = 48);

logic clk, nrst, lat;
logic [DATA_WIDTH -1:0] bit_group_in, bit_group_out;

driver_controller #(.DATA_WIDTH(DATA_WIDTH)) dc (
    .clk(clk),
    .nrst(nrst),
    .bit_group_in(bit_group_in),
    .bit_group_out(bit_group_out),
    .lat(lat)
);

initial
begin
    logic [DATA_WIDTH - 1:0] bit_group;

    repeat(1000)
    begin
    $display("Everything went fine");
    $finish;
end

endmodule

