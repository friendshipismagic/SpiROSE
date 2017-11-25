module framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_BASE=0,
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=80
)(
    input clk_33,
    input nrst,

    // Data and sync signal for the driver main controller
    output reg [29:0] data,
    output reg        sync,

    // Ram access
    output reg [RAM_ADDR_WIDTH-1:0] ram_addr,
    input      [RAM_DATA_WIDTH-1:0] ram_data,

    // Encoder position and sync signal
    input[7:0] enc_position,
    input      enc_sync
);

localparam MULTIPLEXING = 8;
localparam LED_PER_DRIVER = 16;
localparam ROW_SIZE = 80;
localparam COLUMN_SIZE = 48;
localparam IMAGE_SIZE = ROW_SIZE*COLUMN_SIZE;
// We use 16-bits rgb : 5 bits red, 6 bits green, 5 bit blue.
localparam [2:0] [15:0] COLOR_BASE = '{0,5,11};
/*
 * The drivers are layout as follow:
 * |++++++++++++++++++++||++++++++++++++++++++|     |++++++++++++++++++++|
 * | driver 1 (8*16 led)|| driver 3 (8*16 led)| ... | driver 9 (8*16 led)|
 * |++++++++++++++++++++||++++++++++++++++++++|     |++++++++++++++++++++|
 *          ...
 * |++++++++++++++++++++||++++++++++++++++++++|     |++++++++++++++++++++|
 * | driver21 (8*16 led)|| driver23 (8*16 led)| ... | driver30 (8*16 led)|
 * |++++++++++++++++++++||++++++++++++++++++++|     |++++++++++++++++++++|
 *
 * Driver 1 and 2 are intertwined as follow:
 * d1_pixel1  d2_pixel1  ... d1_pixel8  d2 pixel_8
 *                       ...
 * d1_pixel73 d2_pixel73 ... d1_pixel80 d2 pixel_80
 *
 * - The base address for driver 2 is the same as driver 1 plus one.
 * - For driver 3 the base address is 2*MULTIPLEXING.
 * - For driver 10 the base address is ROW_SIZE*LED_PER_DRIVER. Thus on each
 *   line of driver the offset increases by ROW_SIZE*LED_PER_DRIVER.
 */
localparam IMAGE_SIZE_LOG = $clog2(IMAGE_SIZE);
localparam [29:0] [IMAGE_SIZE_LOG-1:0] DRIVER_BASE = '{
    0*2*MULTIPLEXING + 0 + 0*ROW_SIZE*LED_PER_DRIVER,
    0*2*MULTIPLEXING + 1 + 0*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 0 + 0*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 1 + 0*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 0 + 0*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 1 + 0*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 0 + 0*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 1 + 0*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 0 + 0*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 1 + 0*ROW_SIZE*LED_PER_DRIVER,
    0*2*MULTIPLEXING + 0 + 1*ROW_SIZE*LED_PER_DRIVER,
    0*2*MULTIPLEXING + 1 + 1*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 0 + 1*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 1 + 1*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 0 + 1*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 1 + 1*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 0 + 1*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 1 + 1*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 0 + 1*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 1 + 1*ROW_SIZE*LED_PER_DRIVER,
    0*2*MULTIPLEXING + 0 + 2*ROW_SIZE*LED_PER_DRIVER,
    0*2*MULTIPLEXING + 1 + 2*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 0 + 2*ROW_SIZE*LED_PER_DRIVER,
    1*2*MULTIPLEXING + 1 + 2*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 0 + 2*ROW_SIZE*LED_PER_DRIVER,
    2*2*MULTIPLEXING + 1 + 2*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 0 + 2*ROW_SIZE*LED_PER_DRIVER,
    3*2*MULTIPLEXING + 1 + 2*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 0 + 2*ROW_SIZE*LED_PER_DRIVER,
    4*2*MULTIPLEXING + 1 + 2*ROW_SIZE*LED_PER_DRIVER
};

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller.
 */
logic [RAM_DATA_WIDTH-1:0] buffer1 [IMAGE_SIZE-1:0];
logic [RAM_DATA_WIDTH-1:0] buffer2 [IMAGE_SIZE-1:0];
/*
 * CAUTION: Fill the buffers with 0 at runtime. This remove the verilator error
 * about large for loop but means that they won't be initialized again at
 * reset, thus this have to be removed in the latets design.
 */
initial begin
    for(int i = 0; i < IMAGE_SIZE; i++) begin
        buffer1[i] = '0;
        buffer2[i] = '0;
    end
end

// The index of the buffer we are currently using
logic current_buffer;
// The write index of the buffer reading the ram
logic [IMAGE_SIZE_LOG-1:0] write_idx;
// The column we are currently sending
logic [$clog2(MULTIPLEXING)-1:0] mul_idx;
// The led we are currently sending data to
logic [$clog2(LED_PER_DRIVER)-1:0] led_idx;
// The current bit to send to the driver main controller
logic [$clog2(POKER_MODE)-1:0] bit_idx;
// The color we are currently sending
logic [1:0] rgb_idx;

// We need to do BLANKING_CYCLES cycles of blanking each time we change column
wire blanking;
logic [$clog2(BLANKING_CYCLES)-1:0] blanking_cnt;

// The three following wires help to compute the correct voxel and bit address
wire [$clog2(RAM_DATA_WIDTH)-1:0] color_addr;
wire [IMAGE_SIZE_LOG-1:0] voxel_addr;
wire [$clog2(POKER_MODE)-1:0] color_bit_idx;
// Indicates that we have written a whole slice in the buffer
wire has_reached_end;
// Indicates that the buffers need to be swapped
wire new_image;
// Start address of the next image to display
wire[RAM_ADDR_WIDTH-1:0] image_start_addr;

// Tells the driver that we start a new slice
assign sync = (blanking_cnt == BLANKING_CYCLES-2) && (mul_idx == 0);

// Read ram to fill the reading buffer
assign has_reached_end = write_idx == IMAGE_SIZE-1;
assign image_start_addr = enc_position*IMAGE_SIZE + RAM_BASE;
assign new_image = enc_sync;

always_ff @(posedge clk_33)
    if(~nrst) begin
        write_idx <= '0;
    end else begin
        if(new_image) begin
            current_buffer <= ~current_buffer;
            ram_addr <= image_start_addr;
            write_idx <= '0;
        end else if(~has_reached_end) begin
            ram_addr <= ram_addr + 1'b1;
            write_idx <= write_idx + 1'b1;
            if(current_buffer) begin
                buffer1[write_idx] <= ram_data;
            end else begin
                buffer2[write_idx] <= ram_data;
            end
        end
    end

/*
 * Read the writing_buffer to send data to the driver main controller.
 *
 * If a driver start at address n, his first voxel is at address n, the second
 * one is at address n+2 becasue of the interleaving described above, hence we
 * add 2*mul_idx to the base address to get the right column. Then we add
 * led_idx*ROW_SIZE to get the right line.
 *
 * The color_bit_idx goes from 5 to 0, thus if we add the base address for the
 * green color for instance we get bits 10 to 5. The red and blue color have
 * 5 bits instead of 6, hence we need to substract 1 to color_addr.
 */
assign voxel_addr = 2*mul_idx + led_idx*ROW_SIZE;
assign color_bit_idx = (bit_idx >= 3) ? bit_idx - 3 : 0;
assign color_addr = color_bit_idx + 4'(COLOR_BASE[rgb_idx]) - 4'(rgb_idx != 1);
assign blanking = (blanking_cnt != 0);

always_ff @(posedge clk_33)
    if(~nrst) begin
        data <= '0;
    end else begin
        // Since we only have 16 bit per led we have to pad with 0.
        data <= '0;
        /*
         * If we haven't sent 16 bit yet we don't pad with 0.
         * rgb_idx == 1 means we are sending the green color which has 6 bits
         * instead of 5.
         */
        if(~blanking
            && (bit_idx > 3 || (rgb_idx == 1 && bit_idx == 3))) begin
            for(int i = 0; i < 30; ++i) begin
                if(current_buffer) begin
                    data[i] <= buffer2[DRIVER_BASE[i] + voxel_addr][color_addr];
                end else begin
                    data[i] <= buffer1[DRIVER_BASE[i] + voxel_addr][color_addr];
                end
            end
        end
    end

/*
 * Generate counters to send the right data.
 *
 * - mul_idx is the current column
 * - led_idx is the current led
 * - bit_idx is the current bit
 *
 * In poker mode we send the MSB of each led first, thus bit_idx is decreased
 * every 16 cycles. When it reaches 0 we change the current column.
 */
always_ff @(posedge clk_33)
    if(~nrst) begin
        rgb_idx <= '0;
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= '0;
        blanking_cnt <= BLANKING_CYCLES-1;
    end else begin
        if(blanking_cnt == 0) begin
            rgb_idx <= rgb_idx + 1'b1;
            if(rgb_idx == 2) begin
                led_idx <= led_idx + 1'b1;
                if(led_idx == 4'(LED_PER_DRIVER-1)) begin
                    led_idx <= '0;
                    bit_idx <= bit_idx - 1'b1;
                    if(bit_idx == 0) begin
                        bit_idx <= POKER_MODE-1;
                        mul_idx <= mul_idx + 1'b1;
                        if(mul_idx == 3'(MULTIPLEXING-1)) begin
                            mul_idx <= '0;
                            blanking_cnt <= BLANKING_CYCLES-1;
                        end
                    end
                end
            end
        end else begin
            blanking_cnt <= blanking_cnt - 1'b1;
        end
    end

endmodule
