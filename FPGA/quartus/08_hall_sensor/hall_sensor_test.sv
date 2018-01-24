module hall_sensor_test
(
    input          rgb_clk,
    input  [1:0]   hall,

    output [29:0]  drv_sin,
    output         fpga_sclk_a,
    output         fpga_gclk_a,
    output         fpga_lat_a,
    output [7:0]   fpga_mul_a
);

logic clk;
logic nrst;
logic locked;
logic clk_enable;

logic [29:0]    framebuffer_dat;
logic           driver_sout;
logic [4:0]     driver_sout_mux;
logic           position_sync;
logic           column_ready;
logic           driver_ready;
logic           new_configuration_ready;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    // Main 33 MHz clock
    .c0(clk),
    .locked(locked)
);

`include "drivers_conf.svh"

clock_enable main_clock_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
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

logic [7:0]     slice_cnt;
logic [15:0]    speed_data;

hall_sensor main_hall_sensor (
    .clk(clk),
    .nrst(nrst),
    .hall_1(hall[0]),
    .hall_2(hall[1]),
    .slice_cnt(slice_cnt),
    .speed_data(speed_data)
);

assign position_sync = '1;
assign framebuffer_dat = '1;

always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        fpga_mul_a <= '0;
    end else begin
        case (slice_cnt%8)
            0: fpga_mul_a <= 8'b1000_0000;
            1: fpga_mul_a <= 8'b0000_0001;
            2: fpga_mul_a <= 8'b0000_0010;
            3: fpga_mul_a <= 8'b0000_0100;
            4: fpga_mul_a <= 8'b0000_1000;
            5: fpga_mul_a <= 8'b0001_0000;
            6: fpga_mul_a <= 8'b0010_0000;
            7: fpga_mul_a <= 8'b0100_0000;
        endcase
    end

endmodule

