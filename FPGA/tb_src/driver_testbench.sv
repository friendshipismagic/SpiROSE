module driver_testbench #(parameter DATA_WIDTH = 48);

logic clk, nrst, lat, gclk, sclk;
logic bit_in, sin;

driver_controller #(.DATA_WIDTH(DATA_WIDTH)) driver_1 (
    .clk(clk),
    .nrst(nrst),
    .bit_in(bit_in),
    .sin(sin),
    .lat(lat),
    .gclk(gclk),
    .sclk(sclk)
);

initial
begin
    logic [DATA_WIDTH - 1:0] bit_group;

    repeat(1000)
begin
    $display("Everything went fine");
    $finish;
end
end

endmodule

