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
module hall_sensor_emulator (
        input  logic clk,
        /* verilator lint_off UNUSED*/
        input logic  clk_enable,
        input  logic nrst,
        output logic SOF
);

// Slice lenght in cycle
localparam SLICE_CYCLE = 10000;

integer slice_cycle_cnt;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        SOF <= '0;
        slice_cycle_cnt <= '0;
    end else begin
        SOF <= '0;
        slice_cycle_cnt <= slice_cycle_cnt + 1'b1;
        if(slice_cycle_cnt == SLICE_CYCLE) begin
            slice_cycle_cnt <= '0;
            // Signals that the position has changed
            SOF <= 1'b1;
        end
    end

endmodule
