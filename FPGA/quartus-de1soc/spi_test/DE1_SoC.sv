`default_nettype none

// define if using HPS
`undef ENABLE_HPS

module DE1_SoC(
      ///////// ADC /////////
      inout  wire        adc_cs_n,
      output logic       adc_din,
      input  wire        adc_dout,
      output logic       adc_sclk,
      ///////// AUD /////////
      input  wire        aud_adcdat,
      inout  wire        aud_adclrck,
      inout  wire        aud_bclk,
      output logic       aud_dacdat,
      inout  wire        aud_daclrck,
      output logic       aud_xck,
      ///////// CLOCK2 /////////
      input  wire        clock2_50,
      ///////// CLOCK3 /////////
      input  wire        clock3_50,
      ///////// CLOCK4 /////////
      input  wire        clock4_50,
      ///////// CLOCK /////////
      input  wire        clock_50,
      ///////// DRAM /////////
      output logic[12:0] dram_addr,
      output logic[1:0]  dram_ba,
      output logic       dram_cas_n,
      output logic       dram_cke,
      output logic       dram_clk,
      output logic       dram_cs_n,
      inout  wire [15:0] dram_dq,
      output logic       dram_ldqm,
      output logic       dram_ras_n,
      output logic       dram_udqm,
      output logic       dram_we_n,
      ///////// FAN /////////
      output logic       fan_ctrl,
      ///////// FPGA /////////
      output logic       fpga_i2c_sclk,
      inout  wire        fpga_i2c_sdat,
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

`ifdef ENABLE_HPS
      ///////// HPS /////////
      inout  wire        hps_conv_usb_n,
      output logic[14:0] hps_ddr3_addr,
      output logic[2:0]  hps_ddr3_ba,
      output logic       hps_ddr3_cas_n,
      output logic       hps_ddr3_cke,
      output logic       hps_ddr3_ck_n,
      output logic       hps_ddr3_ck_p,
      output logic       hps_ddr3_cs_n,
      output logic[3:0]  hps_ddr3_dm,
      inout  wire [31:0] hps_ddr3_dq,
      inout  wire [3:0]  hps_ddr3_dqs_n,
      inout  wire [3:0]  hps_ddr3_dqs_p,
      output logic       hps_ddr3_odt,
      output logic       hps_ddr3_ras_n,
      output logic       hps_ddr3_reset_n,
      input  wire        hps_ddr3_rzq,
      output logic       hps_ddr3_we_n,
      output logic       hps_enet_gtx_clk,
      inout  wire        hps_enet_int_n,
      output logic       hps_enet_mdc,
      inout  wire        hps_enet_mdio,
      input  wire        hps_enet_rx_clk,
      input  wire [3:0]  hps_enet_rx_data,
      input  wire        hps_enet_rx_dv,
      output logic[3:0]  hps_enet_tx_data,
      output logic       hps_enet_tx_en,
      inout  wire [3:0]  hps_flash_data,
      output logic       hps_flash_dclk,
      output logic       hps_flash_ncso,
      inout  wire        hps_gsensor_int,
      inout  wire        hps_i2c1_sclk,
      inout  wire        hps_i2c1_sdat,
      inout  wire        hps_i2c2_sclk,
      inout  wire        hps_i2c2_sdat,
      inout  wire        hps_i2c_control,
      inout  wire        hps_key,
      inout  wire        hps_led,
      inout  wire        hps_ltc_gpio,
      output logic       hps_sd_clk,
      inout  wire        hps_sd_cmd,
      inout  wire [3:0]  hps_sd_data,
      output logic       hps_spim_clk,
      input  wire        hps_spim_miso,
      output logic       hps_spim_mosi,
      inout  wire        hps_spim_ss,
      input  wire        hps_uart_rx,
      output logic       hps_uart_tx,
      input  wire        hps_usb_clkout,
      inout  wire [7:0]  hps_usb_data,
      input  wire        hps_usb_dir,
      input  wire        hps_usb_nxt,
      output logic       hps_usb_stp,
`endif /*ENABLE_HPS*/
      ///////// IRDA /////////
      input  wire        irda_rxd,
      output logic       irda_txd,
      ///////// key /////////
      input  wire [3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// PS2 /////////
      inout  wire        ps2_clk,
      inout  wire        ps2_clk2,
      inout  wire        ps2_dat,
      inout  wire        ps2_dat2,
      ///////// sw /////////
      input  wire [9:0]  sw,
      ///////// TD /////////
      input  wire        td_clk27,
      input  wire[7:0]   td_data,
      input  wire        td_hs,
      output logic       td_reset_n,
      input  wire        td_vs,
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

//    Turn off all display     //////////////////////////////////////
assign    hex0        =    serialized_conf[6:0];
assign    hex1        =    serialized_conf[13:7];
assign    hex2        =    serialized_conf[20:14];
assign    hex3        =    serialized_conf[27:21];
assign    hex4        =    serialized_conf[34:28];
assign    hex5        =    serialized_conf[41:35];

/////////////////////////////////////////////////////////////////////
// Sorties video VGA     ////////////////////////////////////////////
assign  vga_clk       =  '0;       // Horloge du CNA (DAC)
assign  vga_hs        =  '0;       // Synchro horizontale
assign  vga_vs        =  '0;       // Synchro verticale
assign  vga_blank_n   =  '0;       // Autoriser l'affichage
assign  vga_sync_n    =  '0;       // non utilisé, doit resté à zéro
assign  vga_r         =  '1;       // 10bits de Rouge
assign  vga_g         =  '1;       // 10bits de Vert
assign  vga_b         =  '1;       // 10bits de Bleu
//////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
//    Tous les ports en entrees/sorties mis au 3e etat       /////////
//////////////////////////////////////////////////////////////////////
//assign gpio_0        = 'z;
//assign gpio_1        = 'z;
assign adc_cs_n      = 'z;
assign dram_dq       = 'z;
assign fpga_i2c_sdat = 'z;
assign ps2_clk       = 'z;
assign ps2_clk2      = 'z;
assign ps2_dat       = 'z;
assign ps2_dat2      = 'z;
//   Les sorties non utilisées seront mise à zéro

logic        nrst                   ;
logic [47:0] serialized_conf        ;
logic        new_configuration_ready;
logic        spi_clk                ;
logic        spi_ss                 ;
logic        spi_mosi               ;
logic        spi_miso               ;
logic [15:0] rotation_data          ;

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

spi_slave main_spi(
    .nrst(nrst),
    .spi_clk(spi_clk),
    .spi_ss(spi_ss),
    .spi_mosi(spi_mosi),
    .spi_miso(spi_miso),
    .rotation_data(rotation_data),
    .config_out(serialized_conf),
    .new_config_available(new_configuration_ready)
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

assign ledr[2] = sw[2];
	
// Project pins assignment
assign nrst      = key[0] & lock;
assign spi_mosi  = gpio_0[18]   ;
assign spi_miso  = gpio_0[20]   ;
assign spi_clk   = gpio_0[22]   ;
assign spi_ss    = gpio_0[24]   ;

endmodule
