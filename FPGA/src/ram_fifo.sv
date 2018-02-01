module ram_fifo (
    input clk,
    input nrst,
    input [6:0] raddr,
    input [6:0] waddr,
    output [23:0] rdata,
    input [23:0] wdata,
    input wenable,
    input [6:0] wslice_number,
    input [6:0] rslice_number,
    input SOF_in,
    output SOF_out,
    input EOS
);

localparam STRIPE = 7'(31);

logic full, empty;
logic [2:0] write_idx;
logic [2:0] read_idx;
logic [6:0] current_slice_to_write;
logic [6:0] next_slice_to_read;

assign empty = (read_idx + 1) == write_idx;
assign full = (write_idx + 1) == read_idx;

logic can_write;
assign can_write = (~full) && (wslice_number == current_slice_to_write) && (EOS);
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        write_idx <= '0;
        current_slice_to_write <= '0;
    end else begin
        if(can_write) begin
            write_idx <= write_idx + 1'b1;
            current_slice_to_write <= current_slice_to_write + STRIPE;
        end
    end

logic can_read;
assign can_read = (~empty) & (rslice_number == 1) & (SOF_in);
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        read_idx <= '1;
        next_slice_to_read <= '0;
    end else begin
        if(can_read) begin
            read_idx <= read_idx + 1'b1;
            next_slice_to_read <= next_slice_to_read + STRIPE;
        end
    end

logic [23:0] mux_rdata [7:0];
generate
genvar slice;
for(slice = 0; slice < 8; slice++) begin: for_slice
    wire write_enable = (~full) && (slice == write_idx) && wenable && (wslice_number == current_slice_to_write);
    ram ram(
        .clock(clk),
        .data(wdata),
        .rdaddress(raddr),
        .wraddress(waddr),
        .wren(write_enable),
        .q(mux_rdata[slice])
    );
end
endgenerate

assign rdata = mux_rdata[read_idx];
assign SOF_out = can_read;

endmodule
