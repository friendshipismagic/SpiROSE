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
    output logic writeEnable
);

localparam IMAGE_SIZE = 80*48;

logic isBlanking;
assign isBlanking = hsync | vsync;

logic isNewFrame;
assign isNewFrame = hsync & vsync;

always_ff @(posedge rgbClk)
    if(~nrst)
        ramData <= '0;
    else
        // We don't write anything in blanking area but it is controlled by writeEnable signal
        // We use 5 bits for the red, 6 for the green, and 5 for the blue
        ramData <= {rgb[23:19], rgb[15:10], rgb[7:3]};

always_ff @(posedge rgbClk or negedge nrst)
    if(~nrst)
        ramAddr <= '0;
    else begin
        if(isNewFrame)
            ramAddr <= '0;
        if(~isBlanking)
            ramAddr <= ramAddr + 1'b1;
    end

always_ff @(posedge rgbClk or negedge nrst)
    if(~nrst)
        writeEnable <= '0;
    else
        writeEnable <= ~isBlanking;

endmodule

