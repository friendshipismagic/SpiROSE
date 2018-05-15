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
module ram_line_writer (
    input clk,
    input nrst,
    input SOL,
    input [7:0] offset,
    input [191:0] pixels,
    output [31:0] ram_waddr,
    output [31:0] ram_wdata,
    output ram_write_enable
);

logic [191:0] wdata;
integer pixel_counter;

assign ram_write_enable = pixel_counter > 0;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        pixel_counter <= '0;
    end else begin
        if(pixel_counter == 0) begin
            pixel_counter <= pixel_counter + 32'(SOL);
            wdata <= pixels;
            ram_waddr <= offset*8;
        end else if(pixel_counter > 0) begin
            ram_waddr <= ram_waddr + 1'b1;
            ram_wdata <= {8'b0, wdata[191:168]};
            wdata <= {wdata[167:0], 24'b0};
            pixel_counter <= pixel_counter + 1'b1;
            if(pixel_counter ==  8) begin
                pixel_counter <= '0;
            end
        end

    end

endmodule
