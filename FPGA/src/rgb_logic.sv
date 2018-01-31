`default_nettype none
module rgb_logic (
    input logic        rgb_clk,
    input logic        nrst,

    input logic [23:0] rgb,
    input logic        hsync,
    input logic        vsync,

    // Pixel output
    output logic [23:0] pixel_data,
    output logic [31:0] pixel_idx,
    output logic        pixel_valid,

    // Coordinates of the pixels in a µblock
    output logic  [3:0] pixel_col,
    output logic  [4:0] pixel_line,
    // Coordinates of the µblock
    output logic  [2:0] block_col,
    output logic  [1:0] block_line,

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

// Coordinate counters
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) begin
        pixel_col <= 0;
        pixel_line <= 0;
        block_col <= 0;
        block_line <= 0;
        internal_rgb_enable <= 0;
    end else begin
        // Start of image
        if (~vsync_r && vsync) begin
            pixel_col <= 0;
            pixel_line <= 0;
            block_col <= 0;
            block_line <= 0;
            internal_rgb_enable <= rgb_enable;
        end else if (vsync && hsync) begin
            pixel_col <= pixel_col + 1;

            if (pixel_col == 7) begin
                pixel_col <= 0;
                block_col <= block_col + 1;

                if (block_col == 4) begin
                    block_col <= 0;
                    pixel_line <= pixel_line + 1;

                    if (pixel_line == 15) begin
                        pixel_line <= 0;
                        block_line <= block_line + 1;

                        if (block_line == 3)
                            block_line <= 0;
                    end
                end
            end
        end
    end

// Pixel data latcher
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) pixel_data <= 0;
    else       pixel_data <= rgb;

// Pixel valid latcher
logic internal_pixel_valid, internal_rgb_enable;
assign pixel_valid = internal_rgb_enable & internal_pixel_valid;
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) internal_pixel_valid <= 0;
    else       internal_pixel_valid <= hsync & vsync;

endmodule

