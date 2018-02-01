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

   // Framebuffer outputs
   output [431:0] data_pokered [14:0],
   output drivers_SOF
);

/* verilator lint_off UNUSED */
logic [14:0] drivers_SOF_array;
/* verilator lint_on UNUSED */
assign drivers_SOF = drivers_SOF_array[0];

logic [4:0] slice_shifter;
wire [7:0] write_idx = (wslice_cnt-slice_shifter) % 32 == 0 ? (wslice_cnt-slice_shifter)/32 : 10;
wire [7:0] read_idx = (rslice_cnt/32);
logic end_of_read, end_of_write;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        slice_shifter <= '0;
        end_of_read <= '0;
        end_of_write <= '0;
    end else begin
        if(read_idx == 7) begin
            end_of_read <= '1;
        end
        if(write_idx == 7) begin
            end_of_write <= '1;
        end
        if(end_of_read && end_of_write) begin
            end_of_read <= '0;
            end_of_write <= '0;
            slice_shifter <= slice_shifter + 1'b1;
        end
    end

generate
genvar ram_number, slice;
for(ram_number = 0; ram_number < 15; ram_number++) begin: for_ram
    wire [23:0] ram_read_data [15:0];
    wire [6:0] ram_read_addr;
    for(slice = 0; slice < 7; slice++) begin: for_slice
        wire write_enable = (ram_number == block_number) && block_write_enable && write_idx == slice;
        ram ram(
            .clock(clk),
            .data(ram_data),
            .rdaddress(ram_read_addr),
            .wraddress(pixel_number),
            .wren(write_enable),
            .q(ram_read_data[slice])
        );
    end

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
        .SOF(SOF),
        .driver_SOF(drivers_SOF_array[ram_number]),
        .ram_addr(ram_read_addr),
        .ram_data(ram_read_data[rslice_cnt/32]),
        .EOR(EOR)
    );

    poker_formatter poker_formatter (
        .data_in(framebuffer_data),
        .data_out(data_pokered[ram_number])
    );
   end
endgenerate

endmodule
