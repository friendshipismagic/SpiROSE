module Top
(
 // RGB
 input logic         rgb_clk,
 input logic         rgb_clk2,
 input logic         rgb_hsync,
 input logic         rgb_vsync,
 input logic [23:0]  rgb_d,

 // LVDS
 input logic [3:0]   lvds_tx_p,
 input logic [3:0]   lvds_tx_n,
 input logic         lvds_clk_p,
 input logic         lvds_clk_n,

 // Drivers
 output logic        drv_gclk_a,
 output logic        drv_gclk_b,
 output logic        drv_sclk_a,
 output logic        drv_sclk_b,
 output logic        drv_lat_a,
 output logic        drv_lat_b,
 output logic [29:0] drv_sin,
 output logic [7:0]   fpga_mul_a,
 output logic [7:0]   fpga_mul_b,

 // SPI
 input logic         som_cs,
 input logic         som_sclk,
 input logic         som_mosi,
 output logic        som_miso,

 // Hall sensors
 input logic [1:0]   hall,

 // Encoder
 input logic         encoder_A,
 input logic         encoder_B,
 input logic         encoder_C,
 input logic         encoder_D,

 // Test points
 output logic        pt_6,
 input logic         pt_39,
 output logic        pt_23,
 output logic        pt_24,
 output logic        pt_26,
 output logic        pt_27
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

always_ff @(posedge clk)
    nrst <= locked;

driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_dat),
    .driver_sclk(drv_sclk_a),
    .driver_gclk(drv_gclk_a),
    .driver_lat(drv_lat_a),
    .drivers_sin(drv_sin),
    .driver_sout(driver_sout),
    .driver_sout_mux(driver_sout_mux),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .driver_ready(driver_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);

integer count;
always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        count <= 0;
    end else begin
        count <= count + 1;
        if (count == 50000) begin
            new_configuration_ready <= 1;
        end else begin
            new_configuration_ready <= 0;
        end
    end

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

assign drv_sclk_b = drv_sclk_a;
assign drv_gclk_b = drv_gclk_a;
assign drv_lat_b = drv_lat_a;
assign fpga_mul_b = fpga_mul_a;

endmodule

