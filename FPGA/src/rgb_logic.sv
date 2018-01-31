`default_nettype none
module rgb_logic (
    input logic        rgb_clk,
    input logic        nrst,

    input logic [23:0] rgb,
    input logic        hsync,
    input logic        vsync,

    output logic [23:0] pixel_data,
    output logic [31:0] pixel_idx,
    output logic        pixel_valid,

    // Signal sent by SPI to tell the RGB logic to mark incoming pixels as valid
    input logic         rgb_enable
);

// index position counter
logic vsync_r;
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) begin
        vsync_r <= 0;
        pixel_idx <= 0;
    end else begin
        vsync_r <= vsync;

        // Start of image
        if (~vsync_r && vsync)
            pixel_idx <= 0;

        // Normal pixels
        if (vsync_r && vsync && hsync)
            pixel_idx <= pixel_idx + 1;
    end

// Pixel data latcher
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) pixel_data <= 0;
    else       pixel_data <= rgb;

// Pixel valid latcher
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) pixel_valid <= 0;
    else       pixel_valid <= hsync & vsync;

endmodule

