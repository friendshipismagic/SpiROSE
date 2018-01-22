`default_nettype none

// define if using HPS
`undef ENABLE_HPS

module DE1_SoC(
	 input clock_50, 
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
	 input  wire[9:0]  sw
);

//    Turn off all display     //////////////////////////////////////
assign    hex0        =    'h7F;
assign    hex1        =    'h7F;
assign    hex2        =    'h7F;
assign    hex3        =    'h7F;
assign    hex4        =    'h7F;
assign    hex5        =    'h7F;

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
//logic [47:0] serialized_conf      ;
`include "drivers_conf.sv"
logic        new_configuration_ready;
logic [31:0] ram_waddr              ;
logic [15:0] ram_wdata              ;
logic [31:0] ram_raddr              ;
logic [15:0] ram_rdata              ;
logic        w_enable               ;
logic        stream_ready           ;
logic [23:0] rgb                    ;
logic        hsync                  ;
logic        vsync                  ;
logic [7:0]  mux_out                ;
logic        spi_clk                ;
logic        spi_ss                 ;
logic        spi_mosi               ;
logic        spi_miso               ;
logic [15:0] rotation_data          ;


assign position_sync = 1;

// 66 MHz clock generator
logic clock_66, lock;
clk_66 main_clk_66 (
	.refclk(clock_50),
	.rst(sw[0]),
	.outclk_0(clock_66),
	.locked(lock)
);

// 33 MHz clock generator
logic clock_33;
clock_lse #(.INVERSE_PHASE(0)) clk_lse_gen (
    .clk_hse(clock_66),
    .nrst(nrst),
    .clk_lse(clock_33)
);

framebuffer_emulator #(.POKER_MODE(9)) main_fb_emulator (
    .clk_33(clock_33),
    .nrst(nrst),
    .data(framebuffer_data),
    .driver_ready(driver_ready),
	 .button(~key[3])
);

driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk_hse(clock_66),
    .clk_lse(clock_33),
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
    .column_ready(column_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);
assign ledr[9] = driver_ready;
column_mux main_column_mux (
    .clk_33(clock_33),
    .nrst(nrst),
    .column_ready(column_ready),
    .mux_out(mux_out)
);

// Heartbeat LED 66MHz
logic[24:0] heartbeat_counter_66;
always_ff @(posedge clock_66 or negedge nrst)
    if(~nrst) begin
        ledr[0] <= '0;
        heartbeat_counter_66 <= '0;
    end else begin
        heartbeat_counter_66 <= heartbeat_counter_66 + 1'b1;
        if(heartbeat_counter_66 == 30_000_000) begin
            ledr[0] <= ~ledr[0];
            heartbeat_counter_66 <= '0;
        end
    end

// Heartbeat LED 33MHz
logic[24:0] heartbeat_counter_33;
always_ff @(posedge clock_33 or negedge nrst)
    if(~nrst) begin
        ledr[1] <= '0;
        heartbeat_counter_33 <= '0;
    end else begin
        heartbeat_counter_33 <= heartbeat_counter_33 + 1'b1;
        if(heartbeat_counter_33 == 30_000_000) begin
            ledr[1] <= ~ledr[1];
            heartbeat_counter_33 <= '0;
        end
    end

// Project pins assignment
assign nrst      = key[0] & lock;
assign sout      = gpio_1[0]    ;
assign sout_mux  = gpio_0[35:31];
assign gpio_1[35] = gclk;
assign gpio_1[33] = sclk;
assign gpio_1[31] = lat;
assign gpio_1[29] = sin[0];

assign gpio_0[10] = sw[9];
assign gpio_0[12] = sw[8];
assign gpio_0[14] = sw[7];
assign gpio_0[16] = sw[6];
assign gpio_0[18] = sw[5];
assign gpio_0[20] = sw[4];
assign gpio_0[22] = sw[3];
assign gpio_0[24] = sw[2];

endmodule
