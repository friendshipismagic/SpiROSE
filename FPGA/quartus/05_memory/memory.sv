module memory
(
    input       pt_39,
    input       som_cs,
    output      pt_6
);

wire  nrst = som_cs;
logic clk;

// the PT output is 1 if there was an error in the RAM value verification
assign pt_6 = error;

logic locked;

clock_66 main_clock_66 (
    .inclk0(pt_39),
    // Main 33 MHz clock
    .c0(clk),
    .locked(locked)
);

logic [15:0] wdata;
logic [15:0] raddr;
logic [15:0] waddr;
logic [15:0] rdata;
logic write_enable;

ram main_ram (
    .clock(clk),
    .data(wdata),
    .rdaddress(raddr),
    .wraddress(waddr),
    .q(rdata),
    .wren(write_enable)
);

integer ram_count;
logic is_ram_written;
logic error;

assign waddr = is_ram_written ? '0 : ram_count;
assign wdata = is_ram_written ? '0 : ram_count;
assign raddr = is_ram_written ? ram_count : '0;

// Tests: write in whole RAM then tests the values that are written
always_ff @(posedge clk or negedge nrst)
if (!nrst)
begin
    write_enable <= 1'b0;
    ram_count    <= '0;
    error <= 1'b0;
    is_ram_written <= 1'b0;
end
else
begin
    if (~is_ram_written) begin
        write_enable <= 1;
        if (write_enable) begin
            ram_count <= ram_count + 1;
        end
        if (ram_count == 'hffff) begin
            ram_count <= 0;
            is_ram_written <= 1;
            write_enable <= 0;
        end
    end else begin
        ram_count <= ram_count + 1;
        if (ram_count > 0 && ram_count < 'hffff) begin
            if (rdata != ram_count - 1) begin
                error <= 1;
            end
        end
    end
end

endmodule

