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
module ram_15 (
   input clk,
   input nrst,
   input clk_enable,

   // RAM input
   input [3:0] block_number,
   input [6:0] pixel_number,
   input [23:0] ram_data,
   input block_write_enable,

   // Control inputs
   input EOC,
   input SOF,

   // Framebuffer outputs
   output [431:0] data_pokered [14:0],
   output drivers_SOF
);

/* verilator lint_off UNUSED */
logic [14:0] drivers_SOF_array;
/* verilator lint_on UNUSED */
assign drivers_SOF = drivers_SOF_array[0];

// Exported for SPI debug
wire [23:0] ram_read_data [14:0];
wire [6:0] ram_read_addr [14:0];

generate
   genvar ram_number;
   for(ram_number = 0; ram_number < 15; ram_number++) begin: for_ram
         wire write_enable = (ram_number == block_number) && block_write_enable;
         ram ram(
            .clock(clk),
            .data(ram_data),
            .rdaddress(ram_read_addr[ram_number]),
            .wraddress(pixel_number),
            .wren(write_enable),
            .q(ram_read_data[ram_number])
         );

         wire [383:0] framebuffer_data;
         /* verilator lint_off UNUSED */
         wire EOR;
         /* verilator lint_on UNUSED */
         framebuffer framebuffer(
            .clk(clk),
            .clk_enable(clk_enable),
            .nrst(nrst),
            .data_out(framebuffer_data),
            .EOC(EOC),
            .SOF(SOF),
            .driver_SOF(drivers_SOF_array[ram_number]),
            .ram_addr(ram_read_addr[ram_number]),
            .ram_data(ram_read_data[ram_number]),
            .EOR(EOR)
         );

         poker_formatter poker_formatter (
            .data_in(framebuffer_data),
            .data_out(data_pokered[ram_number])
         );
   end
endgenerate

endmodule
