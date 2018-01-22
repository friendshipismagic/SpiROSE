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

assign position_sync = '1;
assign column_ready  = '1;
assign new_configuration_ready = ~key[3];
assign stream_ready = '1;

framebuffer #(.SLICES_IN_RAM(1)) main_framebuffer (
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
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);

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
		if(heartbeat_counter_66 == 33_000_000) begin
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
		if(heartbeat_counter_33 == 33_000_000) begin
			ledr[1] <= ~ledr[1];
			heartbeat_counter_33 <= '0;
		end
	end

// Project pins assignment
assign nrst = key[0] & lock;

// Drivers
assign gpio_1[6] = gclk;
assign gpio_1[4] = sclk;
assign gpio_1[2] = lat;
assign gpio_1[0] = sin[0];

assign gpio_0[10] = mux_out[7];
assign gpio_0[12] = mux_out[6];
assign gpio_0[14] = mux_out[5];
assign gpio_0[16] = mux_out[4];
assign gpio_0[18] = mux_out[3];
assign gpio_0[20] = mux_out[2];
assign gpio_0[22] = mux_out[1];
assign gpio_0[24] = mux_out[0];

logic [1:0] shift;
assign shift = {sw[1], sw[2]};

// Process to simulate the RAM, changing continuously between R, G and B
always_ff @(posedge clock_33 or negedge nrst)
    if (~nrst) begin
        ram_rdata <= '0;
    end else begin
        if (shift == 3) begin
            ram_rdata <= 16'b00100_000100_00100;
        end else begin
            if (ram_raddr%3 + shift == 0) begin
                ram_rdata <= 16'b10000_000000_00000;
            end else if (ram_raddr%3 + shift == 1) begin
                ram_rdata <= 16'b00000_110000_00000;
            end else begin
                ram_rdata <= 16'b00000_000000_10000;
            end
        end
    end

endmodule
