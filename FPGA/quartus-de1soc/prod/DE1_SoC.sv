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
      input  wire [9:0]  sw,
      ///////// VGA /////////
      output logic[7:0]  vga_b,
      output logic       vga_blank_n,
      output logic       vga_clk,
      output logic[7:0]  vga_g,
      output logic       vga_hs,
      output logic[7:0]  vga_r,
      output logic       vga_sync_n,
      output logic       vga_vs
);

assign    hex0        =   ~serialized_conf[6:0];
assign    hex1        =   ~serialized_conf[13:7];
assign    hex2        =   ~serialized_conf[20:14];
assign    hex3        =   ~serialized_conf[27:21];
assign    hex4        =   ~serialized_conf[34:28];
assign    hex5        =   ~serialized_conf[41:35];

/////////////////////////////////////////////////////////////////////
// Sorties video VGA     ////////////////////////////////////////////
assign  vga_clk       =  rgb_clk;          // Horloge du CNA (DAC)
assign  vga_hs        =  hsync;            // Synchro horizontale
assign  vga_vs        =  vsync;            // Synchro verticale
assign  vga_blank_n   =  hsync || vsync;   // Autoriser l'affichage
assign  vga_sync_n    =  '0;               // non utilisé, doit resté à zéro
assign  vga_r[7:5]    =  rgb[7:5];         // 10bits de Rouge
assign  vga_g[7:5]    =  rgb[15:13];       // 10bits de Vert
assign  vga_b[7:4]    =  rgb[23:20];       // 10bits de Bleu
//////////////////////////////////////////////////////////////////////

logic        nrst                   ;
logic        sout                   ;
logic        gclk                   ;
logic        sclk                   ;
logic        lat                    ;
logic [29:0] sin                    ;
logic [29:0] framebuffer_data       ;
logic        position_sync          ;
logic        column_ready           ;
logic        driver_ready           ;
logic        rgb_enable             ;
logic [47:0] serialized_conf        ;
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
logic        valid                  ;
logic [63:0] cmd_read               ;
logic [3:0]  cmd_len_bytes          ;
logic [47:0] cmd_write              ;


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

spi_iff main_spi_iff (
    .clk(clk),
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
    .clk(clk),
    .valid(valid),
    .cmd_read(cmd_read),
    .cmd_len_bytes(cmd_len_bytes),
    .cmd_write(cmd_write),
    .rotation_data(rotation_data),
    .configuration(serialized_conf),
    .new_config_available(new_configuration_ready),
    .rgb_enable(rgb_enable)
);

hall_sensor_emulator main_hall_sensor_emulator (
    .clk(clk),
    .nrst(nrst),
    .position_sync(position_sync)
);

rgb_logic main_rgb_logic (
    .rgb_clk(rgb_clk),
    .nrst(nrst),
    .rgb(rgb),
    .hsync(hsync),
    .vsync(vsync),
    .ram_addr(ram_waddr),
    .ram_data(ram_wdata),
    .write_enable(w_enable),
    .rgb_enable(rgb_enable),
    .stream_ready(stream_ready)
);

// RAM Module
ram main_ram (
    .clk(clk),
    .w_enable(w_enable),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .w_data(w_data),
    .r_data(r_data)
);

framebuffer #(.POKER_MODE(9)) main_fb (
    .clk_33(clock_33),
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
    .column_ready(column_ready),
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

assign ledr[9] = rgb_enable;
assign ledr[8] = stream_ready;
assign ledr[7] = driver_ready;

// Project pins assignment
assign nrst      = key[0] & lock;

// SPI
assign spi_clk   = gpio_1[22]   ;
assign spi_ss    = gpio_1[24]   ;
assign spi_mosi  = gpio_1[18]   ;
assign spi_miso  = gpio_1[20]   ;

// RGB
// blue
assign rgb[23]   = gpio_0[7]    ;
assign rgb[22]   = gpio_0[5]    ;
assign rgb[21]   = gpio_0[3]    ;
assign rgb[20]   = gpio_0[1]    ;
// green
assign rgb[15]   = gpio_1[0]    ;
assign rgb[14]   = gpio_1[2]    ;
assign rgb[13]   = gpio_1[4]    ;
// red
assign rgb[7]    = gpio_1[1]    ;
assign rgb[6]    = gpio_1[3]    ;
assign rgb[5]    = gpio_1[5]    ;
// control signals
assign hsync     = gpio_0[4]    ;
assign vsync     = gpio_0[2]    ;
assign rgb_clk   = gpio_0[0]    ;

// Drivers
assign gpio_1[35] = gclk;
assign gpio_1[33] = sclk;
assign gpio_1[31] = lat;
assign gpio_1[29] = sin[0];

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
