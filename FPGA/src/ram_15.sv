`default_nettype none
module ram_15 (
   input clk,
   input nrst,
   input clk_enable,

   // RAM input
   input [3:0] block_number,
   input [6:0] pixel_number,
   input [23:0] ram_data,
   input block_write_enable,
   input [7:0] wslice_cnt,
   input [7:0] rslice_cnt,

   // Control inputs
   input EOC,
   input SOF,
   input EOS,

   // Framebuffer outputs
   output [431:0] data_pokered [14:0],
   output drivers_SOF
);

/* verilator lint_off UNUSED */
logic [14:0] drivers_SOF_array;
/* verilator lint_on UNUSED */
assign drivers_SOF = drivers_SOF_array[0];

generate
genvar ram_number, slice_block;
for(ram_number = 0; ram_number < 15; ram_number++) begin: for_ram
    wire [23:0] ram_read_data;
    wire [6:0] ram_read_addr;
    logic SOF_fifo;
    wire write_enable = (ram_number == block_number);
    ram_fifo rf (
        .clk(clk),
        .nrst(nrst),
        .raddr(ram_read_addr),
        .waddr(pixel_number),
        .rdata(ram_read_data),
        .wdata(ram_data),
        .wenable(write_enable),
        .wslice_number(wslice_cnt),
        .rslice_number(rslice_cnt),
        .SOF_in(SOF),
        .SOF_out(SOF_fifo),
        .EOS(EOS)
    );

    wire [383:0] framebuffer_data;
    /* verilator lint_off UNUSED */
    wire EOR;
    /* verilator lint_on UNUSED */
    framebuffer framebuffer(
        .clk(clk),
        .clk_enable(clk_enable),
        .nrst(nrst),
        .data_out(framebuffer_data),
        .EOC(EOC),
        .SOF(SOF_fifo),
        .driver_SOF(drivers_SOF_array[ram_number]),
        .ram_addr(ram_read_addr),
        .ram_data(ram_read_data),
        .EOR(EOR)
    );

    poker_formatter poker_formatter (
        .data_in(framebuffer_data),
        .data_out(data_pokered[ram_number])
    );
   end
endgenerate

endmodule
