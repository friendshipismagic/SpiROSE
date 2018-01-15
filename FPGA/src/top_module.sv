module top_module (
    // 66MHz clock should be generated by PLL
    input clock_66,
    input nrst,

    // RGB bus
    input [23:0] rgb,
    input hsync, vsync, rgb_clk,
    input rgb_enable,

    // Driver output
    output sclk,
    output gclk,
    output lat,
    output [29:0] sin,

    // Driver input
    input sout,
    output [4:0] sout_mux,

    //Columns multiplexers
    output [7:0] mux_out,

    // SPI
    // input sck
    // input ss
    // input mosi,
    // output miso,

    /* verilator lint_off UNUSED */
    // Hall sensor
    input hall0, hall1
    /* verilator lint_on UNUSED */
);

/*
 * Interconnect signals
 */

// RAM
logic [31:0] ram_write_addr;
logic [31:0] ram_read_addr;
logic [15:0] ram_write_data;
/* verilator lint_off UNUSED */
logic [15:0] ram_read_data;
/* verilator lint_on UNUSED */
logic        write_enable;

// FRAMEBUFFER
logic [29:0] framebuffer_dat;
logic        framebuffer_sync;

// RGB
/* verilator lint_off UNUSED */
logic stream_ready;
/* verilator lint_on UNUSED */

/*
 * Temporary zone where signals are driven while unused
 */
assign mux_out = 8'h00;
assign framebuffer_dat ='0;
assign framebuffer_sync = '0;
assign ram_read_addr = '0;

// 33 MHz clock generator
logic clock_33;
clock_lse #(.INVERSE_PHASE(0)) clk_lse_gen (
    .clk_hse(clock_66),
    .nrst(nrst),
    .clk_lse(clock_33)
);

rgb_logic main_rgb_logic (
    .rgb_clk(rgb_clk),
    .nrst(nrst),
    .rgb(rgb),
    .hsync(hsync),
    .vsync(vsync),
    .ram_addr(ram_write_addr),
    .ram_data(ram_write_data),
    .write_enable(write_enable),
    .rgb_enable(rgb_enable),
    .stream_ready(stream_ready)
);

ram main_ram (
    .clk(clock_33),
    .w_enable(write_enable),
    .w_addr(ram_write_addr),
    .r_addr(ram_read_addr),
    .w_data(ram_write_data),
    .r_data(ram_read_data)
);

/*
 * Default configuration for drivers
 * To change the default configuration, please go to drivers_conf.sv
 */
`include "drivers_conf.sv"

// Driver output
driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk_hse(clock_66),
    .clk_lse(clock_33),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_dat),
    .framebuffer_sync(framebuffer_sync),
    .driver_sclk(sclk),
    .driver_gclk(gclk),
    .driver_lat(lat),
    .drivers_sin(sin),
    .driver_sout(sout),
    .driver_sout_mux(sout_mux),
    .serialized_conf(serialized_conf)
);

endmodule
