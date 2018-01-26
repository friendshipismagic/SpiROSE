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

logic [29:0] drv_sin_tolut;
driver_sin_lut main_drv_sin_lut (
    .drv_sin_tolut(drv_sin_tolut),
    .drv_sin(drv_sin)
);

logic [47:0] data_in [29:0];
driver_controller_spi #(.BLANKING_TIME(72)) main_driver_controller (
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
    .data_in(data_in),
    .new_configuration_ready(new_configuration_ready),
    .column_ready(column_ready)
);

column_mux main_column_mux (
    .clk(clk),
    .nrst(nrst),
    .column_ready(column_ready),
    .mux_out(mux_out)
);

hall_sensor_emulator main_hs_emulator (
    .clk(clk_enable),
    .nrst(nrst),
    .position_sync(position_sync)
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

integer caterpillar_cnt;
integer light_pixel_index;
always_comb begin
    for(int i = 0; i < 30; i++) begin
        data_in[i] = 1'b1 << light_pixel_index;
    end
end

always_ff @(posedge clk_enable or negedge nrst)
    if(~nrst) begin
        caterpillar_cnt <= '0;
        light_pixel_index <= 0;
    end else if(position_sync) begin
        caterpillar_cnt <= caterpillar_cnt + 1'b1;
        if(caterpillar_cnt == 256) begin
            caterpillar_cnt <= '0;
            light_pixel_index <= light_pixel_index + 1'b1;
            if(light_pixel_index == 47) begin
                light_pixel_index <= '0;
            end
        end
    end

endmodule
