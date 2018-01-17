module ram #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_SIZE=11776
)(
    input clk,
    input logic w_enable,
    /* verilator lint_off UNUSED */
    input logic [RAM_ADDR_WIDTH-1:0] w_addr,
    input logic [RAM_ADDR_WIDTH-1:0] r_addr,
    /* verilator lint_on UNUSED */
    input logic [RAM_DATA_WIDTH-1:0] w_data,
    output logic [RAM_DATA_WIDTH-1:0] r_data
);

logic [RAM_DATA_WIDTH-1:0] memory [RAM_SIZE-1:0];

always_ff@(posedge clk)
begin
    if(w_enable)
        memory[w_addr] <= w_data;
    r_data <= memory[r_addr];
end

endmodule

