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
    output logic  [3:0] pixel_x,
    output logic  [4:0] pixel_y,
    // Coordinates of the µblock
    output logic  [2:0] block_x,
    output logic  [1:0] block_y,

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
        pixel_x <= 0;
        pixel_y <= 0;
        block_x <= 0;
        block_y <= 0;
    end else begin
        // Start of image
        if (~vsync_r && vsync) begin
            pixel_x <= 0;
            pixel_y <= 0;
            block_x <= 0;
            block_y <= 0;
        end else if (vsync && hsync) begin
            pixel_x <= pixel_x + 1;

            if (pixel_x == 7) begin
                pixel_x <= 0;
                block_x <= block_x + 1;

                if (block_x == 4) begin
                    block_x <= 0;
                    pixel_y <= pixel_y + 1;

                    if (pixel_y == 15) begin
                        pixel_y <= 0;
                        block_y <= block_y + 1;

                        if (block_y == 3)
                            block_y <= 0;
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
always_ff @(posedge rgb_clk or negedge nrst)
    if (~nrst) pixel_valid <= 0;
    else       pixel_valid <= hsync & vsync;

endmodule

