`default_nettype none
module ram_emulator #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16
)(
    input clk,
    /* verilator lint_off UNUSED */
    input logic [RAM_ADDR_WIDTH-1:0] r_addr,
    /* verilator lint_on UNUSED */
    output logic [RAM_DATA_WIDTH-1:0] r_data,
    input  logic [31:0] light_pixel_index
);

localparam SLICE_SIZE = 48*40;

// Only light the led given by light_pixel_index
always_ff@(posedge clk)
begin
    r_data <= '0;
    if(r_addr == light_pixel_index) begin
        r_data <= '1;
    end
end

endmodule

