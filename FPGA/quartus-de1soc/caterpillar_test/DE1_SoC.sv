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

assign nrst = key[0];
assign new_configuration_ready = ~key[2];
assign position_sync = '1;
assign rgb_enable = '1;
assign stream_ready = '1;

logic prev_key;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        prev_key <= '0;
    end else begin
        prev_key <= key[3];
        if(~key[3] && prev_key) begin
            light_pixel_index <= light_pixel_index + 1'b1;
            if(light_pixel_index == 40*48) begin
                light_pixel_index <= '0;
            end
        end
    end

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
clk main_clk_66 (
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

// RAM emulator module, produces a caterpillar animation
integer light_pixel_index;
ram_emulator main_ram_emulator (
    .clk(clk),
    .r_addr(ram_raddr),
    .r_data(ram_rdata),
    .light_pixel_index(light_pixel_index)
);

frambuffer #(SLICES_IN_RAM(1)) main_fb (
    .clk(clk),
    .nrst(nrst),
    .data(framebuffer_data),
    .stream_ready(stream_ready),
    .driver_ready(driver_ready),
    .position_sync(position_sync),
    .ram_addr(ram_raddr),
    .ram_data(ram_rdata)
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

// Heartbeat LED 66MHz
integer heartbeat_counter_66;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        ledr[0] <= '0;
        heartbeat_counter_66 <= '0;
    end else begin
        heartbeat_counter_66 <= heartbeat_counter_66 + 1'b1;
        if(heartbeat_counter_66 == 66_000_000) begin
            ledr[0] <= ~ledr[0];
            heartbeat_counter_66 <= '0;
        end
    end

// Project pins assignment
// Drivers
assign gpio_1[6] = gclk;
assign gpio_1[4] = sclk;
assign gpio_1[2] = lat;
assign gpio_1[35] = sin[0];
assign gpio_1[34] = sin[0];
assign gpio_1[33] = sin[0];
assign gpio_1[32] = sin[0];
assign gpio_1[31] = sin[0];
assign gpio_1[30] = sin[0];
assign gpio_1[29] = sin[0];
assign gpio_1[28] = sin[0];
assign gpio_1[27] = sin[0];
assign gpio_1[26] = sin[0];
assign gpio_1[25] = sin[0];
assign gpio_1[24] = sin[0];
assign gpio_1[23] = sin[0];
assign gpio_1[22] = sin[0];
assign gpio_1[21] = sin[0];
assign gpio_1[20] = sin[0];

// Multiplexing
assign gpio_0[10] = mux_out[7];
assign gpio_0[12] = mux_out[6];
assign gpio_0[14] = mux_out[5];
assign gpio_0[16] = mux_out[4];
assign gpio_0[18] = mux_out[3];
assign gpio_0[20] = mux_out[2];
assign gpio_0[22] = mux_out[1];
assign gpio_0[24] = mux_out[0];


endmodule
