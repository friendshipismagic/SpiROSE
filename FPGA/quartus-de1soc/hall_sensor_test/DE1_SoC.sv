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

logic hall_1;
logic hall_2;
logic nrst;
logic [7:0] slice_cnt;
logic position_sync;
logic [3:0] digit_0;
logic [3:0] digit_1;
logic [3:0] digit_2;

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

assign nrst = key[0] & lock;
assign hall_1 = key[3];
assign hall_2 = key[2];
assign digit_0 = slice_cnt % 10;
assign digit_1 = ((slice_cnt % 100) - digit_0)/10;
assign digit_2 = (slice_cnt - digit_0 - digit_1)/100;

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

// Test for hall effect sensors
hall_sensor main_hall_sensor (
    .clk(clock_33),
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

always_ff @(posedge clock_33 or negedge nrst) begin
    if (~nrst) begin
        ledr[8] <= '0;
    end else begin
        if (position_sync) begin
            ledr[8] <= ~ledr[8];
        end
    end
end


endmodule
