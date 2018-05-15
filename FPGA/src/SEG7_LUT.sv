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
module SEG7_LUT (
    oSEG,
    iDIG
);
input  [3:0] iDIG;
output [6:0] oSEG;
reg    [6:0] oSEG;

always @(iDIG)
begin
    case(iDIG)
        4'h1: oSEG = 7'b1111001;    // ---t----
        4'h2: oSEG = 7'b0100100;    // |	  |
        4'h3: oSEG = 7'b0110000;    // lt	 rt
        4'h4: oSEG = 7'b0011001;    // |	  |
        4'h5: oSEG = 7'b0010010;    // ---m----
        4'h6: oSEG = 7'b0000010;    // |	  |
        4'h7: oSEG = 7'b1111000;    // lb	 rb
        4'h8: oSEG = 7'b0000000;    // |	  |
        4'h9: oSEG = 7'b0011000;    // ---b----
        4'ha: oSEG = 7'b0001000;
        4'hb: oSEG = 7'b0000011;
        4'hc: oSEG = 7'b1000110;
        4'hd: oSEG = 7'b0100001;
        4'he: oSEG = 7'b0000110;
        4'hf: oSEG = 7'b0001110;
        4'h0: oSEG = 7'b1000000;
    endcase
end

endmodule
