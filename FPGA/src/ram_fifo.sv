module ram_fifo (
    input clk,
    input nrst,
    input [7:0] raddr,
    input [7:0] waddr,
    output [23:0] rdata,
    input [23:0] wdata,
    input wenable,
    input [7:0] wslice_number,
    input [7:0] rslice_number,
    input SOF_in,
    output SOF_out,
    input EOS
);

logic full, empty;
integer write_idx;
integer read_idx;
integer next_slice_to_write;
integer next_slice_to_read;

assign empty = (write_idx == read_idx);
assign full = (write_idx == read_idx - 1);

logic can_write;
assign can_write = (~full) & (wslice_number == next_slice_to_write) & EOS;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        write_idx <= '0;
        next_slice_to_write <= '0;
    end else begin
        if(can_write) begin
            write_idx <= write_idx + 1'b1;
            if(write_idx == 7) begin
                write_idx <= '0;
            end
            next_slice_to_write <= next_slice_to_write + 1'b1;
            if(next_slice_to_write == 127) begin
                next_slice_to_write <= '0;
            end
        end
    end

logic can_read;
assign can_read = (~empty) & (rslice_number == next_slice_to_read) & (SOF_in);
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        read_idx <= 0;
        next_slice_to_read <= '0;
    end else begin
        if(can_read) begin
            read_idx <= read_idx + 1'b1;
            if(read_idx == 7) begin
                read_idx <= '0;
            end
            next_slice_to_read <= next_slice_to_read + 1'b1;
            if(next_slice_to_read == 127) begin
                next_slice_to_read <= '0;
            end
        end
    end

logic [23:0] mux_rdata [7:0];
generate
genvar slice;
for(slice = 0; slice < 8; slice++) begin: for_slice
    wire write_enable = slice == write_idx;
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
assign SOF_out = SOF_in & can_read;

endmodule
