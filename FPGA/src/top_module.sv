module top_module (
    input clk_50,
    input nrst,

    // RGB bus
    input [23:0] rgb,
    input hsync, vsync, rgb_clk,

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

    // UART
    input rx,
    output tx,

    // Encoder
    input enc0, enc1
);

// 33 MHz clock
logic clk_33;

// Framebuffer signals
logic framebuffer_sync;
logic [29:0] framebuffer_dat;

// Driver output
driver_controller #(.BLANKING_TIME(80)) main_driver_controller (
   .clk_33(clk_33),
   .nrst(nrst),
   .framebuffer_dat(framebuffer_dat),
   .framebuffer_sync(framebuffer_sync),
   .driver_sclk(sclk),
   .driver_gclk(gclk),
   .driver_lat(lat),
   .drivers_sin(sin),
   .driver_sout(sout),
   .driver_sout_mux(sout_mux)
);

endmodule
