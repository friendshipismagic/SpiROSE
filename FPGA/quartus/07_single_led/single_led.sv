module single_led
(
    input           rgb_clk,
    output [29:0]   drv_sin,
    output          fpga_gclk_a,
    output          fpga_sclk_a,
    output          fpga_lat_a,
    output [7:0]    fpga_mul_a
);

logic clk;
logic nrst;
logic clk_enable;

logic locked;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    // Main 33 MHz clock
    .c0(clk),
    .locked(locked)
);

clock_enable main_clock_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

logic [29:0]    framebuffer_dat;
logic           driver_sout;
logic [4:0]     driver_sout_mux;
logic           position_sync;
logic           column_ready;
logic           driver_ready;
logic [47:0]    serialized_conf;
logic           new_configuration_ready;

driver_controller main_driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_dat),
    .driver_sclk(fpga_sclk_a),
    .driver_gclk(fpga_gclk_a),
    .driver_lat(fpga_lat_a),
    .drivers_sin(drv_sin),
    .driver_sout(driver_sout),
    .driver_sout_mux(driver_sout_mux),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .driver_ready(driver_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);

assign framebuffer_dat = '1;
assign fpga_mul_a = 8'b10000000;
assign position_sync = '1;

endmodule

