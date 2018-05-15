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

module DE1_SoC(
      ///////// CLOCK /////////
      input  logic        clock_50,
      ///////// GPIO /////////
      inout  logic [35:0] gpio_0,
      inout  logic [35:0] gpio_1,
      ///////// hex0 /////////
      output logic[6:0]  hex0,
      ///////// hex1 /////////
      output logic[6:0]  hex1,
      ///////// hex2 /////////
      output logic[6:0]  hex2,
      ///////// hex3 /////////
      output logic[6:0]  hex3,
      ///////// hex4 /////////
      output logic[6:0]  hex4,
      ///////// hex5 /////////
      output logic[6:0]  hex5,
      ///////// key /////////
      input  logic [3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// sw /////////
      input  logic [9:0]  sw
);

logic hall_1;
logic hall_2;
logic nrst;
logic [7:0] slice_cnt;
logic position_sync;
logic [3:0] digit_0;
logic [3:0] digit_1;
logic [3:0] digit_2;

// 66 MHz clock generator
logic clk, lock;
clk_66 main_clk (
    .refclk(clock_50),
    .rst(sw[0]),
    .outclk_0(clk),
    .locked(lock)
);

assign nrst = key[0] & lock;
assign hall_1 = key[3];
assign hall_2 = key[2];
assign digit_0 = slice_cnt % 10;
assign digit_1 = ((slice_cnt % 100) - digit_0)/10;
assign digit_2 = (slice_cnt - digit_0 - digit_1)/100;

// Heartbeat LED 66MHz
heartbeat #(.COUNTER(66_000_000)) hb_66 (
    .clk(clk),
    .nrst(nrst),
    .toggle(ledr[0])
);

// Test for hall effect sensors
hall_sensor main_hall_sensor (
    .clk(clk),
    .nrst(nrst),
    .hall_1(hall_1),
    .hall_2(hall_2),
    .slice_cnt(slice_cnt),
    .position_sync(position_sync)
);

SEG7_LUT lut0 (
    .iDIG(digit_0),
    .oSEG(hex0)
);

SEG7_LUT lut1 (
    .iDIG(digit_1),
    .oSEG(hex1)
);

SEG7_LUT lut2 (
    .iDIG(digit_2),
    .oSEG(hex2)
);

always_ff @(posedge clk or negedge nrst) begin
    if (~nrst) begin
        ledr[8] <= '0;
    end else begin
        if (position_sync) begin
            ledr[8] <= ~ledr[8];
        end
    end
end


endmodule
