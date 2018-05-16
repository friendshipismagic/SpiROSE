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
module sync_sig #(
    parameter RESET_VALUE='0,
    parameter SIZE='1
)(
    input nrst,
    input clk,

    input logic  [SIZE - 1:0] in_sig,
    output logic [SIZE - 1:0] out_sig
);

logic [SIZE - 1:0] reg0;
logic [SIZE - 1:0] reg1;
logic [SIZE - 1:0] reg2;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        reg0 <= RESET_VALUE;
        reg1 <= RESET_VALUE;
        reg2 <= RESET_VALUE;
    end else begin
        reg0 <= in_sig;
        reg1 <= reg0;
        reg2 <= reg1;
    end

// In case of signal integrity, uncomment this
// assign out_sig = (reg0 & reg1) | (reg1 & reg2) | (reg0 & reg2);
assign out_sig = reg2;

endmodule
