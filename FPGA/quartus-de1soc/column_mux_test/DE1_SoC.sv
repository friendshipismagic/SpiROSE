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
      input  wire        clock_50,
      ///////// GPIO /////////
      inout  wire [35:0] gpio_0,
      inout  wire [35:0] gpio_1,
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
      input  wire [3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// sw /////////
      input  wire [9:0]  sw
);

//    Turn off all display     //////////////////////////////////////
assign    hex0        =   'h7f;
assign    hex1        =   'h7f;
assign    hex2        =   'h7f;
assign    hex3        =   'h7f;
assign    hex4        =   'h7f;
assign    hex5        =   'h7f;

logic        nrst                   ;
logic        sout                   ;
logic        gclk                   ;
logic        sclk                   ;
logic        lat                    ;
logic [29:0] sin                    ;
logic [4:0]  sout_mux               ;
logic [29:0] framebuffer_data       ;
logic        position_sync          ;
logic        column_ready           ;
logic        driver_ready           ;
logic        rgb_enable             ;
`include "drivers_conf.svh"
//logic [47:0] serialized_conf        ;
logic        new_configuration_ready;
logic [31:0] ram_waddr              ;
logic [15:0] ram_wdata              ;
logic [31:0] ram_raddr              ;
logic [15:0] ram_rdata              ;
logic        w_enable               ;
logic        stream_ready           ;
logic [23:0] rgb                    ;
logic        rgb_clk                ;
logic        hsync                  ;
logic        vsync                  ;
logic [7:0]  mux_out                ;
logic        spi_clk                ;
logic        spi_ss                 ;
logic        spi_mosi               ;
logic        spi_miso               ;
logic [15:0] rotation_data          ;

// 66 MHz clock generator
logic clk, lock;
clk_66 main_clk (
    .refclk(clock_50),
    .rst(sw[0]),
    .outclk_0(clk),
    .locked(lock)
);

// Divider use by driver_controller
logic clk_enable;
clock_enable main_clk_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

assign position_sync = '1;
assign column_ready  = '1;
assign framebuffer_data = '0;
assign new_configuration_ready = '0;

driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_data),
    .driver_sclk(sclk),
    .driver_gclk(gclk),
    .driver_lat(lat),
    .drivers_sin(sin),
    .driver_sout(sout),
    .driver_sout_mux(sout_mux),
    .position_sync(position_sync),
    .driver_ready(driver_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);

column_mux main_column_mux (
    .clk(clk),
    .nrst(nrst),
    .column_ready(column_ready),
    .mux_out(mux_out)
);

heartbeat #(.COUNTER(66_000_000)) hb_66 (
    .clk(clk),
    .nrst(nrst),
    .toggle(ledr[0])
);

// Project pins assignment
assign nrst = key[0] & lock;

logic driver_switch, mux_switch;
assign driver_switch = sw[9];
assign mux_switch    = sw[8];

// Drivers
always_comb begin
    if(driver_switch) begin
        gpio_1[6] = gclk;
        gpio_1[4] = sclk;
        gpio_1[2] = lat;
        gpio_1[0] = sin[0];
    end else begin
        gpio_1[6] = 0;
        gpio_1[4] = 0;
        gpio_1[2] = 0;
        gpio_1[0] = 0;
    end
end

// Multiplexing
always_comb begin
    if (mux_switch) begin
        gpio_0[10] = mux_out[7];
        gpio_0[12] = mux_out[6];
        gpio_0[14] = mux_out[5];
        gpio_0[16] = mux_out[4];
        gpio_0[18] = mux_out[3];
        gpio_0[20] = mux_out[2];
        gpio_0[22] = mux_out[1];
        gpio_0[24] = mux_out[0];
    end else begin
        gpio_0[10] = 0;
        gpio_0[12] = 0;
        gpio_0[14] = 0;
        gpio_0[16] = 0;
        gpio_0[18] = 0;
        gpio_0[20] = 0;
        gpio_0[22] = 0;
        gpio_0[24] = 0;
    end
end

endmodule
