module rgb_logic #(parameter RAM_SIZE = 10)
(
   input [23:0] rgb,
   input hsync,
   input vsync,
   input rgb_clk,

   // TODO Check RAM Address is on 16b
   output [15:0] ram_address,
   output [15:0] ram_data
);

endmodule
