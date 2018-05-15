//
// Copyright (C) 2017-2018 Alexis Bauvin, Vincent Charbonniéras, Clément Decoodt,
// Alexandre Janniaux, Adrien Marcenat
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

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
