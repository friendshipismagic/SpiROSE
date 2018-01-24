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
 input logic [7:0]   fpga_mul_a,
 input logic [7:0]   fpga_mul_b,

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

logic nrst;
logic clk;

// the PT output is 1 if there was an error in the RAM value verification
assign pt_6 = r_error;

logic locked;

clock_66 main_clock_66 (
    .inclk0(rgb_clk),
    .c0(clk),
    .locked(locked)
);

// Resynchronize the locked signal to be used as a reset
always @(posedge clk)
    nrst <= locked;

 logic [15:0] w_data;
 logic [15:0] r_addr;
 logic [15:0] w_addr;
 logic [15:0] r_data;
 logic write_enable;

 ram_dual_port main_ram (
    .data(w_data),
    .rdaddress(r_addr),
    .rdclock(clk),
    .wraddress(w_addr),
    .wrclock(rgb_clk),
    .wren(write_enable),
    .q(r_data)
 );

 logic is_ram_written;
 logic r_error;

 assign w_addr = 3;
 assign w_data = 3;
 assign write_enable = '1;

 assign r_addr = 3;
 always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
       r_error <= 1'b0;
    end else begin
       if (r_data != w_data) begin
          r_error <= 1;
       end
    end

endmodule
