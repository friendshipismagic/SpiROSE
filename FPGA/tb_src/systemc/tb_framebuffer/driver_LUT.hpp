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

#pragma once
#include <map>

int driver_LUT_D0_RG[16] = {
    // Red-Green
    6 ,
    7 ,
    9 ,
    8 ,
    10,
    11,
    13,
    12,
    14,
    15,
    1 ,
    0 ,
    2 ,
    3 ,
    5 ,
    4
};

int driver_LUT_D0_B[16] = {
    //Blue
    8 ,
    9 ,
    14,
    15,
    12,
    13,
    2 ,
    3 ,
    0 ,
    1 ,
    6 ,
    7 ,
    4 ,
    5 ,
    10,
    11
};

int driver_LUT_D12_RG[16] = {
    // Red-Green
    2 ,
    3 ,
    5 ,
    4 ,
    6 ,
    7 ,
    9 ,
    8 ,
    10,
    11,
    13,
    12,
    14,
    15,
    1 ,
    0 
};

int driver_LUT_D12_B[16] = {
    //Blue
    0 ,
    1 ,
    6 ,
    7 ,
    4 ,
    5 ,
    9 ,
    11,
    8 ,
    10,
    14,
    15,
    12,
    13,
    2 ,
    3 
};
