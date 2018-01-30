`default_nettype none
module vga_dumper #(
    parameter RAM_SIZE = 40*48*16
)(
    input vga_clk,
    input nrst,
    output [31:0] raddr,
    input  [15:0] rdata,
    input stream_ready,
    input vga_blank_n,
    output [7:0] vga_r,
    output [7:0] vga_g,
    output [7:0] vga_b
);

always_ff @(posedge vga_clk or negedge nrst)
    if (~nrst) begin
        raddr <= '0;
    end else if (vga_blank_n && stream_ready) begin
        raddr <= raddr + 1'b1;
        if (raddr == RAM_SIZE - 1) begin
            raddr <= '0;
        end
    end

always_comb begin
    vga_b[7:3] = rdata[15:11];
    vga_g[7:2] = rdata[10:5];
    vga_r[7:3] = rdata[4:0];
    vga_b[2:0] = '0;
    vga_g[1:0] = '0;
    vga_r[2:0] = '0;
end

endmodule
