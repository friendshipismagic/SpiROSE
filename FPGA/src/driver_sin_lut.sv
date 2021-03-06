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
module driver_sin_lut (
    input [29:0] drv_sin_tolut,
    output [29:0] drv_sin
);

always_comb begin
   drv_sin[0]  = drv_sin_tolut[8];
   drv_sin[27] = drv_sin_tolut[9];
   drv_sin[3]  = drv_sin_tolut[6];
   drv_sin[25] = drv_sin_tolut[7];
   drv_sin[8]  = drv_sin_tolut[4];
   drv_sin[24] = drv_sin_tolut[5];
   drv_sin[7]  = drv_sin_tolut[2];
   drv_sin[18] = drv_sin_tolut[3];
   drv_sin[11] = drv_sin_tolut[0];
   drv_sin[19] = drv_sin_tolut[1];

   drv_sin[4]  = drv_sin_tolut[18];
   drv_sin[28] = drv_sin_tolut[19];
   drv_sin[1]  = drv_sin_tolut[16];
   drv_sin[29] = drv_sin_tolut[17];
   drv_sin[13] = drv_sin_tolut[14];
   drv_sin[22] = drv_sin_tolut[15];
   drv_sin[9]  = drv_sin_tolut[12];
   drv_sin[16] = drv_sin_tolut[13];
   drv_sin[10] = drv_sin_tolut[10];
   drv_sin[15] = drv_sin_tolut[11];

   drv_sin[5]  = drv_sin_tolut[28];
   drv_sin[23] = drv_sin_tolut[29];
   drv_sin[2]  = drv_sin_tolut[26];
   drv_sin[21] = drv_sin_tolut[27];
   drv_sin[6]  = drv_sin_tolut[24];
   drv_sin[26] = drv_sin_tolut[25];
   drv_sin[12] = drv_sin_tolut[22];
   drv_sin[17] = drv_sin_tolut[23];
   drv_sin[14] = drv_sin_tolut[20];
   drv_sin[20] = drv_sin_tolut[21];
end

endmodule
