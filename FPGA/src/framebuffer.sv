module framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_BASE=0,
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=72,
    parameter SLICES_IN_RAM=18
)(
    input clk_33,
    input nrst,

    // Data signal for the driver main controller
    output [29:0] data,

    /*
     * Sync signal indicating the beginning of the stream. Since we have to
     * wait for the rgb logic to write enough data in the ram before beginning
     * the stream, we need this signal to start/stop sending data to the
     * driver controller.
     */
    input stream,

    // Ram access
    output [RAM_ADDR_WIDTH-1:0] ram_addr,
    input  [RAM_DATA_WIDTH-1:0] ram_data,

    // Position sync signal, indicates that the position has changed
    input position_sync
);

localparam MULTIPLEXING = 8;
localparam LED_PER_DRIVER = 16;
/*
 * As explained below, the drivers of one panel faces the ones on the other
 * panel, thus we only need 40 columns at a time.
 */
localparam ROW_SIZE = 40;
localparam COLUMN_SIZE = 48;
localparam IMAGE_SIZE = ROW_SIZE*COLUMN_SIZE;
// We use 16-bits rgb : 5 bits red, 6 bits green, 5 bit blue.
localparam [2:0] [15:0] COLOR_BASE = '{0,5,11};
/*
 * The drivers are layout as follow:
 * |++++++++++++++++++++++||++++++++++++++++++++++|     |+++++++++++++++++++++++|
 * | driver 1/2 (8*16 led)|| driver 3/4 (8*16 led)| ... | driver 9/10 (8*16 led)|
 * |++++++++++++++++++++++||++++++++++++++++++++++|     |+++++++++++++++++++++++|
 *          ...
 * |++++++++++++++++++++++++||++++++++++++++++++++++++|     |++++++++++++++++++++++++|
 * | driver 21/22 (8*16 led)|| driver 23/24 (8*16 led)| ... | driver 29/30 (8*16 led)|
 * |++++++++++++++++++++++++||++++++++++++++++++++++++|     |++++++++++++++++++++++++|
 *
 * Driver 1 and 2 are NOT intertwined, they are facing each other as follow:
 *
 * d1_pixel1/d2_pixel1  ... d1_pixel8/d2 pixel_8
 *                       ...
 * d1_pixel16/d2_pixel16 ... d1_pixel128/d2 pixel_128
 *
 * Driver 1 and 2 will display the same pixel at the same time. Thus we
 * display only 40 columns out of 80 at a time, and half a turn later we need
 * to display the other 40. In order for the framebuffer to remain position
 * agnostic, the SBC will handle this problem when generating the slices : it
 * will send the even columns during 128 slices (hence a half turn), then it
 * will send the odd columns (actually it needs to reverse those columns
 * because the panel will have turn by 180°).
 *
 * In the buffers we will store only a column at a time for each driver, hence
 * we have the following layout for the buffers' data:
 *
 * d1_pixel1   d3_pixel1   ... d9_pixel1
 *                         ...
 * d1_pixel16  d3_pixel16  ... d9_pixel16
 *
 * d11_pixel1  d13_pixel1  ... d19_pixel1
 *                         ...
 * d11_pixel16 d13_pixel16 ... d19_pixel16
 *
 * d21_pixel1  d23_pixel1  ... d29_pixel1
 *                         ...
 * d21_pixel16 d23_pixel16 ... d29_pixel16
 *
 * We need to precompute the base read address for each driver in order to
 * send the right data easily and in one cycle:
 *
 * - The base addresses for driver 1,3,5,7,9 are 0,2,4,6,8.
 * - For driver 11 the base address is 5*LED_PER_DRIVER. Thus on each
 *   line of driver the offset increases by 5*LED_PER_DRIVER.
 * - For even drivers, the base adress is the same as the related odd driver:
 *   driver 1 and 2 share the same base address, thus the same data, because
 *   as said above they are facing each other.
 */
localparam BUFF_SIZE = 15*LED_PER_DRIVER;
localparam BUFF_SIZE_LOG = $clog2(BUFF_SIZE);
localparam [29:0] [BUFF_SIZE_LOG-1:0] DRIVER_BASE = '{
    0 + 0*5*LED_PER_DRIVER,
    0 + 0*5*LED_PER_DRIVER,
    1 + 0*5*LED_PER_DRIVER,
    1 + 0*5*LED_PER_DRIVER,
    2 + 0*5*LED_PER_DRIVER,
    2 + 0*5*LED_PER_DRIVER,
    3 + 0*5*LED_PER_DRIVER,
    3 + 0*5*LED_PER_DRIVER,
    4 + 0*5*LED_PER_DRIVER,
    4 + 0*5*LED_PER_DRIVER,
    0 + 1*5*LED_PER_DRIVER,
    0 + 1*5*LED_PER_DRIVER,
    1 + 1*5*LED_PER_DRIVER,
    1 + 1*5*LED_PER_DRIVER,
    2 + 1*5*LED_PER_DRIVER,
    2 + 1*5*LED_PER_DRIVER,
    3 + 1*5*LED_PER_DRIVER,
    3 + 1*5*LED_PER_DRIVER,
    4 + 1*5*LED_PER_DRIVER,
    4 + 1*5*LED_PER_DRIVER,
    0 + 2*5*LED_PER_DRIVER,
    0 + 2*5*LED_PER_DRIVER,
    1 + 2*5*LED_PER_DRIVER,
    1 + 2*5*LED_PER_DRIVER,
    2 + 2*5*LED_PER_DRIVER,
    2 + 2*5*LED_PER_DRIVER,
    3 + 2*5*LED_PER_DRIVER,
    3 + 2*5*LED_PER_DRIVER,
    4 + 2*5*LED_PER_DRIVER,
    4 + 2*5*LED_PER_DRIVER
};

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller. In the buffers we store only a column
 * for each driver, hence we have to swap buffer when we change the
 * multiplexing.
 */
logic [RAM_DATA_WIDTH-1:0] buffer1 [BUFF_SIZE-1:0];
logic [RAM_DATA_WIDTH-1:0] buffer2 [BUFF_SIZE-1:0];
/*
 * CAUTION: Fill the buffers with 0 at runtime. This remove the verilator error
 * about large for loop but means that they won't be initialized again at
 * reset, thus this have to be removed in the latest design.
 */
initial begin
    for(int i = 0; i < BUFF_SIZE; i++) begin
        buffer1[i] = '0;
        buffer2[i] = '0;
    end
end

// The index of the buffer we are currently using
logic current_buffer;
// The write index of the buffer reading the ram
logic [BUFF_SIZE_LOG-1:0] write_idx;
// The column we are currently sending (relatively to a driver)
logic [$clog2(MULTIPLEXING)-1:0] mul_idx;
// The led we are currently sending data to
logic [$clog2(LED_PER_DRIVER)-1:0] led_idx;
// The current bit to send to the driver main controller
logic [$clog2(POKER_MODE)-1:0] bit_idx;
// The color (red green or blue) we are currently sending
logic [1:0] rgb_idx;

// We need to do BLANKING_CYCLES cycles of blanking each time we change column
logic blanking;
logic [$clog2(BLANKING_CYCLES)-1:0] blanking_cnt;

// The three following logics help to compute the correct voxel and bit address
logic [$clog2(RAM_DATA_WIDTH)-1:0] color_addr;
logic [BUFF_SIZE_LOG-1:0] voxel_addr;
logic [$clog2(POKER_MODE)-1:0] color_bit_idx;
// Indicates that we have written a whole slice in the buffer
logic has_reached_end;
// Start address of the next image to display
logic [RAM_ADDR_WIDTH-1:0] image_start_addr;
// Indicates which slice we need to read from the ram
logic [$clog2(SLICES_IN_RAM)-1:0] slice_cnt;


/*
 * Read ram to fill the reading buffer.
 *
 * We need to read only a column per driver, thus if we are at column i for the
 * driver j, if we add MULTIPLEXING from here we access column i+MULTIPLEXING
 * which is part of driver j+2.
 */
assign has_reached_end = write_idx == BUFF_SIZE-1;
assign image_start_addr = slice_cnt*IMAGE_SIZE + RAM_BASE;

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        write_idx <= '0;
        ram_addr <= RAM_BASE;
        slice_cnt <= '0;
    end else if(stream) begin
        // The position has changed hence we read a new slice
        if(position_sync) begin
            write_idx <= '0;
            slice_cnt <= slice_cnt + 1'b1;
            ram_addr <= (32'(slice_cnt)+1'b1)*IMAGE_SIZE + RAM_BASE;
            if(slice_cnt == SLICES_IN_RAM) begin
                slice_cnt <= '0;
                ram_addr <= RAM_BASE;
            end
        end else if(~has_reached_end) begin
            ram_addr <= ram_addr + MULTIPLEXING;
            write_idx <= write_idx + 1'b1;
            if(current_buffer) begin
                buffer1[write_idx] <= ram_data;
            end else begin
                buffer2[write_idx] <= ram_data;
            end
        // We have sent all data so we fill a new buffer
        end else if(bit_idx == 0) begin
            // We will fill the new buffer with the next column
            ram_addr <= image_start_addr + 32'(mul_idx);
            write_idx <= '0;
        end
    end else begin
        write_idx <= '0;
        ram_addr <= RAM_BASE;
        slice_cnt <= '0;
    end

/*
 * Read the writing_buffer to send data to the driver main controller.
 *
 * If a driver starts at address n, his first voxel is at address n, the second
 * one is at address n+5 because of the buffers' layout described above, hence
 * we add 5*led_idx to the base address to get the right line.
 *
 * The color_bit_idx goes from 5 to 0, thus if we add the base address for the
 * green color for instance we get bits 10 to 5. The red and blue color have
 * 5 bits instead of 6, hence we need to substract 1 to color_addr.
 */
assign voxel_addr = 5*led_idx;
assign color_bit_idx = (bit_idx >= 3) ? bit_idx - 3 : 0;
assign color_addr = color_bit_idx + 4'(COLOR_BASE[rgb_idx]) - 4'(rgb_idx != 1);
assign blanking = (blanking_cnt != 0);

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        data <= '0;
    end else if(stream) begin
        /*
         * Since we only have 16 bit per led, but the poker mode ask for 27
         * bits, we have to pad with 0.
         */
        data <= '0;
        /*
         * If we haven't sent 16 bit yet we don't pad with 0.
         * bit_idx > 3 means that we don't send the 4 first LSB.
         * rgb_idx == 1 means we are sending the green color which has 6 bits
         * instead of 5.
         */
        if(stream &&
            ~blanking && (bit_idx > 3 || (rgb_idx == 1 && bit_idx == 3))) begin
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
always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        rgb_idx <= '0;
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= '0;
        blanking_cnt <= BLANKING_CYCLES-1;
        current_buffer <= '0;
    end else if(stream) begin
        if(blanking_cnt == 0) begin
            rgb_idx <= rgb_idx + 1'b1;
            // We have sent the three colors, time to go to the next led
            if(rgb_idx == 2) begin
                rgb_idx <= '0;
                led_idx <= led_idx + 1'b1;
                // We have sent the right bit for each leds in the column
                if(led_idx == 4'(LED_PER_DRIVER-1)) begin
                    led_idx <= '0;
                    bit_idx <= bit_idx - 1'b1;
                    // We need to wait one cycle because of driver timing issue
                    blanking_cnt <= 7'b1;
                    // We have sent all the bits for each led
                    if(bit_idx == 0) begin
                        bit_idx <= POKER_MODE-1;
                        // Go to next column, swap buffers and do blanking
                        mul_idx <= mul_idx + 1'b1;
                        current_buffer <= ~current_buffer;
                        blanking_cnt <= BLANKING_CYCLES-1;
                        // We have sent the whole slice
                        if(mul_idx == 3'(MULTIPLEXING-1)) begin
                            mul_idx <= '0;
                        end
                    end
                end
            end
        end else begin
            blanking_cnt <= blanking_cnt - 1'b1;
        end
    end else begin
        rgb_idx <= '0;
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= '0;
        blanking_cnt <= BLANKING_CYCLES-1;
        current_buffer <= '0;
    end

endmodule
