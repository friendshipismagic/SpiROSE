`default_nettype none
module rgb_logic (
    input logic        clk,
    input logic        nrst,

    input logic [23:0] rgb,
    input logic        hsync,
    input logic        vsync,
    input logic        empty,

    // Pixel output
    output logic [23:0] pixel_data,
    output logic        pixel_valid,

    // Coordinates of the pixels in a µblock
    output logic  [2:0] pixel_col,
    output logic  [3:0] pixel_line,
    // Coordinates of the µblock
    output logic  [2:0] block_col,
    output logic  [1:0] block_line,

    // Signal sent by SPI to tell the RGB logic to mark incoming pixels as valid
    input logic         rgb_enable
);

// Coordinate counters
always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        pixel_col <= 0;
        pixel_line <= 0;
        block_col <= 0;
        block_line <= 0;
    end else if (!empty) begin
        // Start of image
        if (~vsync_r && vsync) begin
            pixel_col <= 0;
            pixel_line <= 0;
            block_col <= 0;
            block_line <= 0;
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

                        if (block_line == 2)
                            block_line <= 0;
                    end
                end
            end
        end
    end

// Vsync edge detector
logic vsync_r;
always_ff @(posedge clk or negedge nrst)
    if (~nrst) begin
        vsync_r <= 0;
    end else if (!empty) begin
        vsync_r <= vsync;
    end


// Internal RGB enable latcher
always_ff @(posedge clk or negedge nrst)
    if (~nrst)
        internal_rgb_enable <= 0;
    else if (!empty && ~vsync_r && vsync)
        internal_rgb_enable <= rgb_enable;

// Pixel data latcher
assign pixel_data = {rgb[7:0], rgb[15:8], rgb[23:16]};

// Pixel valid latcher
logic internal_rgb_enable;
assign pixel_valid = internal_rgb_enable & hsync & vsync;

endmodule

