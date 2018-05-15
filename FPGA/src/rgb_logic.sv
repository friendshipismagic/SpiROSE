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
module rgb_logic #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter IMAGE_IN_RAM = 18
)(
    input rgb_clk,
    input nrst,
    // We won't use every bits of the rgb because of driver bandwidth issue
    /* verilator lint_off UNUSED */
    input [23:0] rgb,
    /* verilator lint_on UNUSED */
    input hsync,
    input vsync,

    output [RAM_ADDR_WIDTH-1:0] ram_addr,
    output [RAM_DATA_WIDTH-1:0] ram_data,
    output logic write_enable,

    // Signal send by SPI to tell the rgb logic to start writing slices in ram
    input  rgb_enable,
    // Indicates that enough slices have been writing in ram to begin display
    output stream_ready
);

localparam IMAGE_WIDTH = 40;
localparam IMAGE_HEIGHT = 48;
localparam IMAGE_SIZE = IMAGE_WIDTH*IMAGE_HEIGHT;
localparam SLICES_IN_RAM_BEFORE_STREAM = 1;

logic blanking;
// hsync and vsync drive low when we are on blanking area
assign blanking = (~hsync | ~vsync);

integer pixel_counter;

logic is_end_of_RAM;
assign is_end_of_RAM = ram_addr == (IMAGE_SIZE*IMAGE_IN_RAM-1);

logic is_valid_first_frame;
assign is_valid_first_frame = vsync | (pixel_counter >= IMAGE_SIZE - 1);

/*
 * We don't write anything in blanking area but it is controlled by
 * writeEnable signal. We store 5 bits for the red, 6 for the green,
 * and 5 for the blue. Only 5 bits of the green might be used.
 */
assign ram_data = {rgb[23:19], rgb[15:10], rgb[7:3]};

// Data is sampled at posedge after module, so we need negedge here
always_ff @(negedge rgb_clk or negedge nrst)
    if(~nrst) begin
        ram_addr <= '0;
    end else begin
        ram_addr <= '0;
        if(rgb_enable && !is_end_of_RAM && is_valid_first_frame) begin
            if(blanking)
                ram_addr <= ram_addr;
            else
                ram_addr <= ram_addr + 1;
        end
    end

assign write_enable = ~blanking && rgb_enable && nrst;

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        pixel_counter <= '0;
    end else begin
        pixel_counter <= '0;
        /*
         * when rgb_enable drives high we may be in the middle of a frame, thus
         * when vsync drives low we check pixel_cnt, if it is not IMAGE_SIZE
         * we reset it so we are ready for a real start. stream_ready would
         * not have been sent so we would not have display those unrelevant data
         * we just write.
         */
        if (rgb_enable && !is_end_of_RAM && is_valid_first_frame) begin
            if(~blanking)
                pixel_counter <= pixel_counter + 1;
            else
                pixel_counter <= pixel_counter;
        end
    end

always_ff @(posedge rgb_clk or negedge nrst)
    if(~nrst) begin
        stream_ready <= '0;
    end else begin
        stream_ready <= '0;
        // We don't do anything until the SPI tells us to start
        if(rgb_enable) begin
            // stream ready drives high when we have written enough slices in ram
            stream_ready <= stream_ready ? 1'b1 : pixel_counter >= SLICES_IN_RAM_BEFORE_STREAM*IMAGE_SIZE;
        end
    end

endmodule

