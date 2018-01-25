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
logic clk_enable;

logic locked;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    .c0(clk),
    .locked(locked)
);

clock_enable main_clock_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

// Reset bridge
always_ff @(posedge clk)
    nrst <= locked;

`include "drivers_conf.svh"

logic [29:0]    framebuffer_dat;
logic           driver_sout;
logic [4:0]     driver_sout_mux;
logic drv_sclk;
logic drv_gclk;
logic drv_lat;
logic           position_sync;
logic           column_ready;
logic           driver_ready;
logic           new_configuration_ready;

/*
 * Send the new_configuration_ready after some time to get
 * to the stream state
 */
integer first_conf_counter;
always_ff @(posedge clk_enable or negedge nrst)
   if(~nrst) begin
      new_configuration_ready <= '0;
      first_conf_counter <= 0;
   end else begin
      new_configuration_ready <= '0;
      if(first_conf_counter < 10) begin
         first_conf_counter <= first_conf_counter + 1;
         new_configuration_ready <= '1;
      end
   end

driver_controller main_driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_dat),
    .driver_sclk(drv_sclk),
    .driver_gclk(drv_gclk),
    .driver_lat(drv_lat),
    .drivers_sin(drv_sin),
    .driver_sout(driver_sout),
    .driver_sout_mux(driver_sout_mux),
    .position_sync(position_sync),
    .column_ready(column_ready),
    .driver_ready(driver_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready)
);

assign drv_sclk_a = drv_sclk;
assign drv_gclk_a = drv_gclk;
assign drv_lat_a = drv_lat;
assign drv_sclk_b = drv_sclk;
assign drv_gclk_b = drv_gclk;
assign drv_lat_b = drv_lat;
assign fpga_mul_a = mux_out;
assign fpga_mul_b = mux_out;

assign framebuffer_dat = '1;

integer position_sync_cnt;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        position_sync_cnt <= '0;
        position_sync <= '0;
    end else begin
        position_sync <= '0;
        position_sync_cnt <= position_sync_cnt + 1'b1;
        if(position_sync_cnt == 4096*30) begin
            position_sync_cnt <= '0;
            position_sync <= '1;
        end
    end

logic [7:0] mux_out;
column_mux main_column_mux (
    .clk(clk),
    .nrst(nrst),
    .column_ready(column_ready),
    .mux_out(mux_out)
);

endmodule
