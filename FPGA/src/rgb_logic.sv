module rgb_logic #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16
)(
    input rgbClk,
    input nrst,
    // We won't use every bits of the rgb because of driver bandwidth issue
    /* verilator lint_off UNUSED */
    input [23:0] rgb,
    /* verilator lint_on UNUSED */
    input hsync,
    input vsync,

    // TODO Check RAM Address is on 16b
    output [RAM_ADDR_WIDTH-1:0] ramAddr,
    output [RAM_DATA_WIDTH-1:0] ramData,
    output writeEnable
);

localparam IMAGE_SIZE = 80*48;

logic isBlanking;
assign isBlanking = hsync || vsync;

always_ff @(posedge rgbClk)
    if(~nrst) begin
        ramAddr <= '0;
        ramData <= '0;
        writeEnable <= '0;
    end else begin
        // We don't write anything in blanking area
        writeEnable <= '0;
        if(~isBlanking) begin
            writeEnable <= 1'b1;
            // We use 5 bits for the red, 6 for the green, and 5 for the blue
            ramData <= {rgb[23:19], rgb[15:10], rgb[7:3]};
            // TODO: handle write address
            ramAddr <= ramAddr + 1'b1;
        end
    end

endmodule

