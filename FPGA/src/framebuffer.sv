module  framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16
)(
    input clk_33,
    input nrst,

    // Data and sync signal for the driver main controller
    output[29:0] data,
    output       sync,

    // Ram access
    output[RAM_ADDR_WIDTH-1:0] ram_addr,
    input [RAM_DATA_WIDTH-1:0] ram_data,

    // Encoder position and sync signal
    input[7:0] enc_position,
    input      enc_sync
);

localparam IMAGE_SIZE = 80*48;

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller.
 */
logic [RAM_DATA_WIDTH-1:0] buffer1 [IMAGE_SIZE-1:0];
logic [RAM_DATA_WIDTH-1:0] buffer2 [IMAGE_SIZE-1:0];
wire  [RAM_DATA_WIDTH-1:0] reading_buffer [IMAGE_SIZE-1:0];

logic[RAM_ADDR_WIDTH-1:0] image_start_addr;
// The index of the buffer we are currently using
logic current_buffer;
// The write index of the buffer reading the ram
logic [$clog2(IMAGE_SIZE)-1:0] write_idx;
// The read index of the buffer sending the data
logic [$clog2(IMAGE_SIZE)-1:0] pixel_idx;
// Indicates that we have written a whole slice in the buffer
wire has_reached_end;
// Indicates that the buffer needs to be swapped
wire new_image;

assign reading_buffer = current_buffer ? buffer1 : buffer2;
assign has_reached_end = write_idx == IMAGE_SIZE-1;
assign new_image = enc_sync;

//Read ram to fill the reading buffer
always_ff@(posedge clk_33)
    if(~nrst) begin
        for(int i = 0; i < IMAGE_SIZE; ++i) begin
            buffer1[i] <= 0;
            buffer2[i] <= 0;
        end
        write_idx <= 0;
    end else begin
        if(new_image) begin
            ram_addr <= image_start_addr;
            write_idx <= 0;
        end else if(~has_reached_end) begin
            ram_addr <= ram_addr + 1;
            write_idx <= write_idx + 1;
            reading_buffer[write_idx] <= ram_data;
        end
    end

always_ff @(posedge clk_33)
    if(~nrst) begin
        data <= 0;
    end else begin
    end

endmodule
