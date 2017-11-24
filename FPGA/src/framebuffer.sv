module  framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_BASE=0,
    parameter POKER_MODE=9
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

localparam MULTIPLEXING = 8;
localparam LED_PER_DRIVER = 16;
localparam DRIVER_IMAGE_SIZE = LED_PER_DRIVER*MULTIPLEXING;
localparam ROW_SIZE = 80;
localparam COLUMN_SIZE = 48;
localparam IMAGE_SIZE = ROW_SIZE*COLUMN_SIZE;

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller.
 */
logic [RAM_DATA_WIDTH-1:0] buffer1 [IMAGE_SIZE-1:0];
logic [RAM_DATA_WIDTH-1:0] buffer2 [IMAGE_SIZE-1:0];
wire  [RAM_DATA_WIDTH-1:0] reading_buffer [IMAGE_SIZE-1:0];
wire  [RAM_DATA_WIDTH-1:0] writing_buffer [IMAGE_SIZE-1:0];

// The index of the buffer we are currently using
logic current_buffer;
// The write index of the buffer reading the ram
logic [$clog2(IMAGE_SIZE)-1:0] write_idx;
// The column we are currently sending
logic [$clog2(MULTIPLEXING)-1:0] mul_idx;
// The led we are currently sending data to
logic [$clog2(LED_PER_DRIVER)-1:0] led_idx;
// The current bit to send to the driver main controller
logic [$clog2(POKER_MODE)-1:0] bit_idx;
// Indicates that we have written a whole slice in the buffer
wire has_reached_end;
// Indicates that the buffer needs to be swapped
wire new_image;
// Start address of the next image to display
wire[RAM_ADDR_WIDTH-1:0] image_start_addr;

assign reading_buffer = current_buffer ? buffer1 : buffer2;
assign writing_buffer = current_buffer ? buffer2 : buffer1;
assign has_reached_end = write_idx == IMAGE_SIZE-1;
assign image_start_addr = enc_position*IMAGE_SIZE + RAM_BASE;
assign new_image = enc_sync;

// Read ram to fill the reading buffer
always_ff @(posedge clk_33)
    if(~nrst) begin
        for(int i = 0; i < IMAGE_SIZE; ++i) begin
            buffer1[i] = '0;
            buffer2[i] = '0;
        end
        write_idx <= '0;
    end else begin
        if(new_image) begin
            current_buffer <= ~current_buffer;
            ram_addr <= image_start_addr;
            write_idx <= '0;
        end else if(~has_reached_end) begin
            ram_addr <= ram_addr + 1'b1;
            write_idx <= write_idx + 1'b1;
            reading_buffer[write_idx] <= ram_data;
        end
    end

// Read the buffer to send data to the driver main controller
always_ff @(posedge clk_33)
    if(~nrst) begin
        data <= '0;
    end else begin
        for(int i = 0; i < 30; ++i) begin
            data[i] <= writing_buffer[ROW_SIZE*led_idx + mul_idx][bit_idx];
        end
    end

/*
 * Generate counters to read the right data.
 *
 * - mul_idx is the current column
 * - led_idx is the current led
 * - bit_idx is the current bit
 *
 * In poker mode we send the MSB of each led first, thus bit_idx is decreased
 * every 16 cycles. When it reaches 0 we change the current column.
 */
always_ff @(posedge clk_33)
    if(nrst) begin
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= '0;
    end else begin
        led_idx <= led_idx + 1'b1;
        if(led_idx == LED_PER_DRIVER-1) begin
            led_idx <= '0;
            bit_idx <= bit_idx - 1'b1;
            if(bit_idx == 0) begin
                bit_idx <= POKER_MODE-1;
                mul_idx <= mul_idx + 1'b1;
                if(mul_idx == MULTIPLEXING-1) begin
                    mul_idx <= '0;
                end
            end
        end
    end

endmodule
