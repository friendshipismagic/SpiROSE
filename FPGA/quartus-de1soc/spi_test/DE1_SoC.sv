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
assign    hex0        =    ~cmd_read[54:48];
assign    hex1        =    ~cmd_read[55];
assign    hex2        =    'h7f;
assign    hex3        =    'h7f;
assign    hex4        =    'h7f;
assign    hex5        =    'h7f;

logic        nrst                   ;
logic [47:0] conf                   ;
logic        new_configuration_ready;
logic        spi_clk                ;
logic        spi_ss                 ;
logic        spi_mosi               ;
logic        spi_miso               ;
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
logic        rgb_enable             ;
logic        valid                  ;
logic [55:0] cmd_read               ;
logic [2:0]  cmd_len_bytes          ;
logic [47:0] cmd_write              ;

assign position_sync = 1'b1;

// 66 MHz clock generator
logic clock_66, lock;
clk main_clk_66 (
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

spi_iff main_spi_iff (
    .clk(clock_33),
    .nrst(nrst),
    .spi_clk(spi_clk),
    .spi_ss(spi_ss),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .valid(valid),
    .cmd_read(cmd_read),
    .cmd_len_bytes(cmd_len_bytes),
    .cmd_write(cmd_write)
);

spi_decoder main_spi_decoder (
    .nrst(nrst),
    .clk(clock_33),
    .valid(valid),
    .cmd_read(cmd_read),
    .cmd_len_bytes(cmd_len_bytes),
    .cmd_write(cmd_write),
    .rotation_data(rotation_data),
    .configuration(conf),
    .new_config_available(new_configuration_ready),
    .rgb_enable(rgb_enable)
);

framebuffer_emulator #(.POKER_MODE(9), .BLANKING_CYCLES(72)) main_fb_emulator (
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
    .driver_ready(driver_ready),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .serialized_conf(conf),
    .new_configuration_ready(new_configuration_ready)
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

// SPI
assign spi_clk   = gpio_1[22]   ;
assign spi_ss    = gpio_1[24]   ;
assign spi_mosi  = gpio_1[18]   ;
assign spi_miso  = gpio_1[20]   ;

// Drivers
assign gpio_1[35] = gclk;
assign gpio_1[33] = sclk;
assign gpio_1[31] = lat;
assign gpio_1[29] = sin[0];

// Multiplexing
assign gpio_0[10] = sw[9];
assign gpio_0[12] = sw[8];
assign gpio_0[14] = sw[7];
assign gpio_0[16] = sw[6];
assign gpio_0[18] = sw[5];
assign gpio_0[20] = sw[4];
assign gpio_0[22] = sw[3];
assign gpio_0[24] = sw[2];

endmodule
