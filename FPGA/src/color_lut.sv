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
module color_lut (
    input [431:0] data_in [14:0],
    output [431:0] data_out [14:0]
);

// UB*D0 and UB*D2
// Red-Green
/* verilator lint_off WIDTHCONCAT */
/* verilator lint_off LITENDIAN */
localparam integer DRIVER_LUT0_RG [0:15] = '{
   6 , 7 , 9 , 8 , 10, 11, 13, 12, 14, 15, 1 , 0 , 2 , 3 , 5 , 4
};

//Blue
localparam integer DRIVER_LUT0_B [0:15]= '{
   8 , 9 , 14, 15, 12, 13, 2 , 3 , 0 , 1 , 6 , 7 , 4 , 5 , 10, 11
};

// UB*D1
// Red-Green
localparam integer DRIVER_LUT1_RG [0:15] = '{
   2 , 3 , 5 , 4 , 6 , 7 , 9 , 8 , 10, 11, 13, 12, 14, 15, 1 , 0
};

//Blue
localparam integer DRIVER_LUT1_B [0:15] = '{
   0 , 1 , 6 , 7 , 4 , 5 , 9 , 11, 8 , 10, 14, 15, 12, 13, 2 , 3
};

// UB*D2
// Red-Green
localparam integer DRIVER_LUT2_RG [0:15] = '{
    2 ,3 ,4 ,5 ,6 ,7 ,8 ,9 ,10 ,11 ,12 ,13 ,14 ,15, 0, 1
};

// Blue
localparam integer DRIVER_LUT2_B [0:15] = '{
    1, 0, 6, 7, 5, 4, 8, 11, 9, 10, 14, 15, 13, 12, 2, 3
};

/* verilator lint_on LITENDIAN */
/* verilator lint_on WIDTHCONCAT */

always_comb
begin
    for(int i = 0; i < 5; i++) begin
        for(int bit_idx = 0; bit_idx < 9; bit_idx++) begin
            for(int led = 0; led < 16; led++) begin
                data_out[i][48*bit_idx + 3*led]   = data_in[i][48*bit_idx + 3*DRIVER_LUT0_RG[led]];
                data_out[i][48*bit_idx + 3*led+1] = data_in[i][48*bit_idx + 3*DRIVER_LUT0_RG[led]+1];
                data_out[i][48*bit_idx + 3*led+2] = data_in[i][48*bit_idx + 3*DRIVER_LUT0_B[led]+2];
            end
        end
    end
    for(int i = 5; i < 10; i++) begin
        for(int bit_idx = 0; bit_idx < 9; bit_idx++) begin
            for(int led = 0; led < 16; led++) begin
                data_out[i][48*bit_idx + 3*led]   = data_in[i][48*bit_idx + 3*DRIVER_LUT1_RG[led]];
                data_out[i][48*bit_idx + 3*led+1] = data_in[i][48*bit_idx + 3*DRIVER_LUT1_RG[led]+1];
                data_out[i][48*bit_idx + 3*led+2] = data_in[i][48*bit_idx + 3*DRIVER_LUT1_B[led]+2];
            end
        end
    end
    for(int i = 10; i < 15; i++) begin
        for(int bit_idx = 0; bit_idx < 9; bit_idx++) begin
            for(int led = 0; led < 16; led++) begin
                data_out[i][48*bit_idx + 3*led]   = data_in[i][48*bit_idx + 3*DRIVER_LUT2_RG[led]];
                data_out[i][48*bit_idx + 3*led+1] = data_in[i][48*bit_idx + 3*DRIVER_LUT2_RG[led]+1];
                data_out[i][48*bit_idx + 3*led+2] = data_in[i][48*bit_idx + 3*DRIVER_LUT2_B[led]+2];
            end
        end
    end
end

endmodule
