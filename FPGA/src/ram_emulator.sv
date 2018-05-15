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

