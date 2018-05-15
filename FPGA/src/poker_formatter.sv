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
module poker_formatter (
    input [383:0]  data_in,
    output [431:0] data_out
);

always_comb begin
   data_out = '0;
   for(int bit_idx=1; bit_idx<9; bit_idx++) begin
      for(int led=0; led<16; led++) begin
         data_out[48*bit_idx + 3*led + 0] = data_in[24*led + (bit_idx - 1) + 0];
         data_out[48*bit_idx + 3*led + 1] = data_in[24*led + (bit_idx - 1) + 8];
         data_out[48*bit_idx + 3*led + 2] = data_in[24*led + (bit_idx - 1) + 16];
      end
   end
end

endmodule
