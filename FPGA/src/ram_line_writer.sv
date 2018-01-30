`default_nettype none
module ram_line_writer (
    input clk,
    input nrst,
    input SOL,
    input [7:0] offset,
    input [191:0] pixels,
    output [31:0] ram_waddr,
    output [31:0] ram_wdata,
    output ram_write_enable
);

logic [191:0] wdata;
integer pixel_counter;

assign ram_write_enable = pixel_counter > 0;

always @(posedge clk or negedge nrst)
    if(~nrst) begin
        pixel_counter <= '0;
    end else begin
        if(pixel_counter == 0) begin
            pixel_counter <= pixel_counter + 32'(SOL);
            wdata <= pixels;
            ram_waddr <= offset*8;
        end else if(pixel_counter > 0) begin
            ram_waddr <= ram_waddr + 1'b1;
            ram_wdata <= {8'b0, wdata[191:168]};
            wdata <= {wdata[167:0], 24'b0};
            pixel_counter <= pixel_counter + 1'b1;
            if(pixel_counter ==  8) begin
                pixel_counter <= '0;
            end
        end

    end

endmodule
