`default_nettype none

// define if using HPS
`undef ENABLE_HPS

module DE1_SoC(
      ///////// ADC /////////
      inout  logic        adc_cs_n,
      output logic       adc_din,
      input  logic        adc_dout,
      output logic       adc_sclk,
      ///////// AUD /////////
      input  logic        aud_adcdat,
      inout  logic        aud_adclrck,
      inout  logic        aud_bclk,
      output logic       aud_dacdat,
      inout  logic        aud_daclrck,
      output logic       aud_xck,
      ///////// CLOCK2 /////////
      input  logic        clock2_50,
      ///////// CLOCK3 /////////
      input  logic        clock3_50,
      ///////// CLOCK4 /////////
      input  logic        clock4_50,
      ///////// CLOCK /////////
      input  logic        clock_50,
      ///////// DRAM /////////
      output logic[12:0] dram_addr,
      output logic[1:0]  dram_ba,
      output logic       dram_cas_n,
      output logic       dram_cke,
      output logic       dram_clk,
      output logic       dram_cs_n,
      inout  logic [15:0] dram_dq,
      output logic       dram_ldqm,
      output logic       dram_ras_n,
      output logic       dram_udqm,
      output logic       dram_we_n,
      ///////// FAN /////////
      output logic       fan_ctrl,
      ///////// FPGA /////////
      output logic       fpga_i2c_sclk,
      inout  logic        fpga_i2c_sdat,
      ///////// GPIO /////////
      input  logic [35:0] gpio_0,
      input   logic [35:0] gpio_1,
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

`ifdef ENABLE_HPS
      ///////// HPS /////////
      inout  logic        hps_conv_usb_n,
      output logic[14:0] hps_ddr3_addr,
      output logic[2:0]  hps_ddr3_ba,
      output logic       hps_ddr3_cas_n,
      output logic       hps_ddr3_cke,
      output logic       hps_ddr3_ck_n,
      output logic       hps_ddr3_ck_p,
      output logic       hps_ddr3_cs_n,
      output logic[3:0]  hps_ddr3_dm,
      inout  logic [31:0] hps_ddr3_dq,
      inout  logic [3:0]  hps_ddr3_dqs_n,
      inout  logic [3:0]  hps_ddr3_dqs_p,
      output logic       hps_ddr3_odt,
      output logic       hps_ddr3_ras_n,
      output logic       hps_ddr3_reset_n,
      input  logic        hps_ddr3_rzq,
      output logic       hps_ddr3_we_n,
      output logic       hps_enet_gtx_clk,
      inout  logic        hps_enet_int_n,
      output logic       hps_enet_mdc,
      inout  logic        hps_enet_mdio,
      input  logic        hps_enet_rx_clk,
      input  logic [3:0]  hps_enet_rx_data,
      input  logic        hps_enet_rx_dv,
      output logic[3:0]  hps_enet_tx_data,
      output logic       hps_enet_tx_en,
      inout  logic [3:0]  hps_flash_data,
      output logic       hps_flash_dclk,
      output logic       hps_flash_ncso,
      inout  logic        hps_gsensor_int,
      inout  logic        hps_i2c1_sclk,
      inout  logic        hps_i2c1_sdat,
      inout  logic        hps_i2c2_sclk,
      inout  logic        hps_i2c2_sdat,
      inout  logic        hps_i2c_control,
      inout  logic        hps_key,
      inout  logic        hps_led,
      inout  logic        hps_ltc_gpio,
      output logic       hps_sd_clk,
      inout  logic        hps_sd_cmd,
      inout  logic [3:0]  hps_sd_data,
      output logic       hps_spim_clk,
      input  logic        hps_spim_miso,
      output logic       hps_spim_mosi,
      inout  logic        hps_spim_ss,
      input  logic        hps_uart_rx,
      output logic       hps_uart_tx,
      input  logic        hps_usb_clkout,
      inout  logic [7:0]  hps_usb_data,
      input  logic        hps_usb_dir,
      input  logic        hps_usb_nxt,
      output logic       hps_usb_stp,
`endif /*ENABLE_HPS*/
      ///////// IRDA /////////
      input  logic        irda_rxd,
      output logic       irda_txd,
      ///////// key /////////
      input  logic [3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// PS2 /////////
      inout  logic        ps2_clk,
      inout  logic        ps2_clk2,
      inout  logic        ps2_dat,
      inout  logic        ps2_dat2,
      ///////// sw /////////
      input  logic [9:0]  sw,
      ///////// TD /////////
      input  logic        td_clk27,
      input  logic[7:0]   td_data,
      input  logic        td_hs,
      output logic       td_reset_n,
      input  logic        td_vs,
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

logic nrst;
// Choose between RGB output direct to VGA or RAM dump to VGA
logic rgb_or_ram = key[1];
// RGB input
logic disp_clk;
logic disp_hsync;
logic disp_vsync;
logic [2:0] disp_r;
logic [2:0] disp_g;
logic [3:0] disp_b = rgb[23:20];
logic [23:0] rgb;
logic stream_ready;
logic rgb_enable;
// RAM VGA dumper
logic ram_vga_clk;
logic ram_vga_hs;
logic ram_vga_vs;
logic ram_vga_blank;
logic ram_vga_sync;
logic [7:0] ram_vga_r;
logic [7:0] ram_vga_g;
logic [7:0] ram_vga_b;
// RAM Signals
logic w_enable;
logic [31:0] w_addr;
logic [31:0] r_addr;
logic [15:0] w_data;
logic [15:0] r_data;

// Heartbeat LED 27MHz
logic[24:0] heartbeat_counter_27;
always_ff @(posedge disp_clk or negedge nrst)
    if(~nrst) begin
        ledr[0] <= '0;
        heartbeat_counter_27 <= '0;
    end else begin
        heartbeat_counter_27 <= heartbeat_counter_27 + 1'b1;
        if(heartbeat_counter_27 == 27_000_000) begin
            ledr[0] <= ~ledr[0];
            heartbeat_counter_27 <= '0;
        end
    end

always_comb begin
      vga_clk     = disp_clk;
      vga_hs      = disp_hsync;
      vga_vs      = disp_vsync;
      vga_sync_n  = '0;
      vga_blank_n = disp_vsync || disp_hsync;
   if (~rgb_or_ram) begin
      vga_r[7:5]  = disp_r;
      vga_g[7:5]  = disp_g;
      vga_b[7:4]  = disp_b;
   end else begin
      vga_r[7:5]  = ram_vga_r[7:5];
      vga_g[7:5]  = ram_vga_g[7:5];
      vga_b[7:4]  = ram_vga_b[7:4];
   end
end

vga_dumper vga (
    .vga_clk(disp_clk),
    .nrst(nrst),
    .vga_blank_n(vga_blank_n),
    .vga_r(ram_vga_r),
    .vga_g(ram_vga_g),
    .vga_b(ram_vga_b),
    .raddr(r_addr),
    .rdata(r_data),
    .stream_ready(stream_ready)
);

// RAM Module
ram main_ram (
    .clk(disp_clk),
    .w_enable(w_enable),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .w_data(w_data),
    .r_data(r_data)
);

// Device Under Test
rgb_logic #(.IMAGE_IN_RAM(16)) dut (
    .rgb_clk(disp_clk),
    .nrst(nrst),
    .rgb(rgb),
    .hsync(disp_hsync),
    .vsync(disp_vsync),
    .ram_addr(w_addr),
    .ram_data(w_data),
    .write_enable(w_enable),
    .rgb_enable(rgb_enable),
    .stream_ready(stream_ready)
);

// Project pins assignment
assign nrst = key[0];
assign rgb_enable = '1;

// RGB
assign rgb[23]    = gpio_0[7]   ;
assign rgb[22]    = gpio_0[5]   ;
assign rgb[21]    = gpio_0[3]   ;
assign rgb[20]    = gpio_0[1]   ;
assign rgb[19:0]  = 0           ;
assign disp_hsync = gpio_0[4]   ;
assign disp_vsync = gpio_0[2]   ;
assign disp_clk   = gpio_0[0]   ;

endmodule
