`default_nettype none

module DE1_SoC(
      ///////// CLOCK /////////
      input  logic       clock_50,
      ///////// GPIO /////////
      output logic[35:0] gpio_0,
      output logic[35:0] gpio_1,
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
      input  logic[3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// sw /////////
      input  logic[9:0]  sw
);

`include "drivers_conf.svh"

assign    hex0        =    conf[6:0];
assign    hex1        =    conf[13:7];
assign    hex2        =    conf[20:14];
assign    hex3        =    conf[27:21];
assign    hex4        =    conf[34:28];
assign    hex5        =    conf[41:35];

logic        nrst                   ;
logic [47:0] conf                   ;
logic        new_configuration_ready;
logic [15:0] rotation_data          ;
logic [29:0] framebuffer_data       ;
logic        position_sync          ;
logic        sout                   ;
logic        gclk                   ;
logic        sclk                   ;
logic        lat                    ;
logic [29:0] sin                    ;
logic [4:0]  sout_mux               ;
logic        driver_ready           ;
logic        column_ready           ;

assign position_sync = 1'b1;

// Don't send any data
assign framebuffer_data = 1'b0;
assign new_configuration_ready = ~key[3];

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
    .driver_ready(driver_ready),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .serialized_conf(conf),
    .new_configuration_ready(new_configuration_ready)
);

heartbeat #(.COUNTER(66_000_000)) hb_66 (
    .clk(clk),
    .nrst(nrst),
    .toggle(ledr[0])
);

// Project pins assignment
assign nrst = key[0] & lock;

assign gpio_1[6]   = gclk;
assign gpio_1[4]   = sclk;
assign gpio_1[2]   = lat;
assign gpio_1[0]   = sin[0];

assign gpio_0[10] = sw[9];
assign gpio_0[12] = sw[8];
assign gpio_0[14] = sw[7];
assign gpio_0[16] = sw[6];
assign gpio_0[18] = sw[5];
assign gpio_0[20] = sw[4];
assign gpio_0[22] = sw[3];
assign gpio_0[24] = sw[2];

assign gpio_0[0]  = key[2];

always_comb begin
    if(~key[1]) begin
        conf = ledr[1] ? serialized_conf : '0;
    end else begin
        conf = sw[1] ? serialized_conf : '0;
    end
end

endmodule
