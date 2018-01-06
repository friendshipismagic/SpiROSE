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
