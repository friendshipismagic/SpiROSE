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

logic        nrst                   ;
logic        drv_gclk               ;
logic        drv_sclk               ;
logic        drv_lat                ;
logic [29:0] framebuffer_data       ;
logic        position_sync          ;
logic        column_ready           ;
logic        driver_ready           ;
logic        rgb_enable             ;
`include "drivers_conf.svh"
logic        new_configuration_ready;
logic [31:0] ram_raddr              ;
logic [15:0] ram_rdata              ;
logic        w_enable               ;
logic        stream_ready           ;
logic [7:0]  mux_out                ;

assign drv_gclk_a = drv_gclk;
assign drv_gclk_b = drv_gclk;
assign drv_sclk_a = drv_sclk;
assign drv_sclk_b = drv_sclk;
assign drv_lat_a = drv_lat;
assign drv_lat_b = drv_lat;

assign fpga_mul_a = mux_out;
assign fpga_mul_b = mux_out;

assign pt_6 = drv_gclk;

// 66 MHz clock generator
logic clk, locked;
clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    .c0(clk),
    .locked(locked)
);

// Divider used by driver_controller
logic clk_enable;
clock_enable main_clk_enable (
    .clk(clk),
    .nrst(nrst),
    .clk_enable(clk_enable)
);

framebuffer #(.SLICES_IN_RAM(1)) main_fb (
    .clk(clk),
    .nrst(nrst),
    .data(framebuffer_data),
    .stream_ready(stream_ready),
    .driver_ready(driver_ready),
    .position_sync(position_sync),
    .ram_addr(ram_raddr),
    .ram_data(ram_rdata)
);

// Light only the led number 20
assign ram_rdata = (ram_raddr == 20) ? '1 : '0;

logic [29:0] drv_sin_tolut;
always_comb begin
   drv_sin[0] = drv_sin_tolut[0];
   drv_sin[27] = drv_sin_tolut[1];
   drv_sin[3] = drv_sin_tolut[2];
   drv_sin[25] = drv_sin_tolut[3];
   drv_sin[8] = drv_sin_tolut[4];
   drv_sin[24] = drv_sin_tolut[5];
   drv_sin[7] = drv_sin_tolut[6];
   drv_sin[18] = drv_sin_tolut[7];
   drv_sin[11] = drv_sin_tolut[8];
   drv_sin[19] = drv_sin_tolut[9];
   drv_sin[4] = drv_sin_tolut[10];
   drv_sin[28] = drv_sin_tolut[11];
   drv_sin[1] = drv_sin_tolut[12];
   drv_sin[29] = drv_sin_tolut[13];
   drv_sin[13] = drv_sin_tolut[14];
   drv_sin[22] = drv_sin_tolut[15];
   drv_sin[9] = drv_sin_tolut[16];
   drv_sin[16] = drv_sin_tolut[17];
   drv_sin[10] = drv_sin_tolut[18];
   drv_sin[15] = drv_sin_tolut[19];
   drv_sin[5] = drv_sin_tolut[20];
   drv_sin[23] = drv_sin_tolut[21];
   drv_sin[2] = drv_sin_tolut[22];
   drv_sin[21] = drv_sin_tolut[23];
   drv_sin[6] = drv_sin_tolut[24];
   drv_sin[26] = drv_sin_tolut[25];
   drv_sin[12] = drv_sin_tolut[26];
   drv_sin[17] = drv_sin_tolut[27];
   drv_sin[14] = drv_sin_tolut[28];
   drv_sin[20] = drv_sin_tolut[29];
end

driver_controller #(.BLANKING_TIME(72)) main_driver_controller (
    .clk(clk),
    .clk_enable(clk_enable),
    .nrst(nrst),
    .framebuffer_dat(framebuffer_data),
    .driver_sclk(drv_sclk),
    .driver_gclk(drv_gclk),
    .driver_lat(drv_lat),
    .drivers_sin(drv_sin_tolut),
    .position_sync(position_sync),
    .driver_ready(driver_ready),
    .serialized_conf(serialized_conf),
    .new_configuration_ready(new_configuration_ready),
    .column_ready(column_ready)
);

column_mux main_column_mux (
    .clk(clk),
    .nrst(nrst),
    .column_ready(column_ready),
    .mux_out(mux_out)
);

assign nrst = locked;
assign rgb_enable = '1;
assign stream_ready = '1;

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

integer position_sync_cnt;
integer light_pixel_index;
always_ff @(posedge clk_enable or negedge nrst)
    if(~nrst) begin
        position_sync_cnt <= '0;
        position_sync <= '0;
    end else begin
        position_sync <= '0;
        position_sync_cnt <= position_sync_cnt + 1'b1;
        if(caterpillar_cnt == 4096 + 2349) begin
           position_sync <= '1;
           position_sync_cnt <= '0;
        end
     end

endmodule
