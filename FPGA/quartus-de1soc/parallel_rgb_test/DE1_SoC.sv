`default_nettype none

module DE1_SoC(
      ///////// CLOCK /////////
      input  logic       clock_50,
      ///////// GPIO /////////
      inout  logic [35:0] gpio_0,
      inout  logic [35:0] gpio_1,
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
      input  logic [3:0]  key,
      ///////// ledr /////////
      output logic[9:0]  ledr,
      ///////// sw /////////
      input  logic [9:0]  sw,
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

logic nrst;
// Choose between RGB output direct to VGA or RAM dump to VGA
logic rgb_or_ram = key[1];
// RGB input
logic disp_clk;
logic disp_hsync;
logic disp_vsync;
logic [2:0] disp_r;
logic [2:0] disp_g;
logic [3:0] disp_b = rgb[23:20];
logic [23:0] rgb;
logic stream_ready;
logic rgb_enable;
// RAM VGA dumper
logic ram_vga_clk;
logic ram_vga_hs;
logic ram_vga_vs;
logic ram_vga_blank;
logic ram_vga_sync;
logic [7:0] ram_vga_r;
logic [7:0] ram_vga_g;
logic [7:0] ram_vga_b;
// RAM Signals
logic w_enable;
logic [31:0] w_addr;
logic [31:0] r_addr;
logic [15:0] w_data;
logic [15:0] r_data;

heartbeat #(.COUNTER(27_000_000)) hb_27 (
    .clk(clk),
    .nrst(nrst),
    .toggle(ledr[0])
);

always_comb begin
      vga_clk     = disp_clk;
      vga_hs      = disp_hsync;
      vga_vs      = disp_vsync;
      vga_sync_n  = '0;
      vga_blank_n = disp_vsync || disp_hsync;
   if (~rgb_or_ram) begin
      vga_r[7:5]  = disp_r;
      vga_g[7:5]  = disp_g;
      vga_b[7:4]  = disp_b;
   end else begin
      vga_r[7:5]  = ram_vga_r[7:5];
      vga_g[7:5]  = ram_vga_g[7:5];
      vga_b[7:4]  = ram_vga_b[7:4];
   end
end

vga_dumper vga (
    .vga_clk(disp_clk),
    .nrst(nrst),
    .vga_blank_n(vga_blank_n),
    .vga_r(ram_vga_r),
    .vga_g(ram_vga_g),
    .vga_b(ram_vga_b),
    .raddr(r_addr),
    .rdata(r_data),
    .stream_ready(stream_ready)
);

// RAM Module
ram main_ram (
    .clk(disp_clk),
    .w_enable(w_enable),
    .w_addr(w_addr),
    .r_addr(r_addr),
    .w_data(w_data),
    .r_data(r_data)
);

// Device Under Test
rgb_logic #(.IMAGE_IN_RAM(16)) dut (
    .rgb_clk(disp_clk),
    .nrst(nrst),
    .rgb(rgb),
    .hsync(disp_hsync),
    .vsync(disp_vsync),
    .ram_addr(w_addr),
    .ram_data(w_data),
    .write_enable(w_enable),
    .rgb_enable(rgb_enable),
    .stream_ready(stream_ready)
);

// Project pins assignment
assign nrst = key[0];
assign rgb_enable = '1;

// RGB
assign rgb[23]    = gpio_0[7]   ;
assign rgb[22]    = gpio_0[5]   ;
assign rgb[21]    = gpio_0[3]   ;
assign rgb[20]    = gpio_0[1]   ;
assign rgb[19:0]  = 0           ;
assign disp_hsync = gpio_0[4]   ;
assign disp_vsync = gpio_0[2]   ;
assign disp_clk   = gpio_0[0]   ;

endmodule
