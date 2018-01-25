module framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_BASE=0,
    parameter POKER_MODE=9,
    parameter SLICES_IN_RAM=18
)(
    input clk,
    input nrst,

    // Data signal for the driver main controller
    output [29:0] data,

    /*
     * Sync signal indicating the beginning of the stream. Since we have to
     * wait for the rgb logic to write enough data in the ram before beginning
     * the stream, we need this signal to start/stop sending data to the
     * driver controller.
     */
    input stream_ready,
    /*
     * Sync signal indicating that the driver is ready to receive data,
     * meaning that it has been configured and is not in a blanking cycle.
     */
    input driver_ready,
    // Position sync signal, indicates that the position has changed
    input position_sync,

    // Ram access
    output [RAM_ADDR_WIDTH-1:0] ram_addr,
    input  [RAM_DATA_WIDTH-1:0] ram_data
);

localparam MULTIPLEXING = 8;
localparam LED_PER_DRIVER = 16;
localparam BUFF_SIZE = 15*LED_PER_DRIVER;
localparam BUFF_SIZE_LOG = $clog2(BUFF_SIZE);

/*
 * As explained below, the drivers of one panel faces the ones on the other
 * panel, thus we only need 40 columns at a time.
 */
localparam ROW_SIZE = 40;
localparam COLUMN_SIZE = 48;
localparam IMAGE_SIZE = ROW_SIZE*COLUMN_SIZE;
// We use 15-bits rgb : 5 bits red, 5 bits green, 5 bit blue.
localparam [2:0] [15:0] COLOR_BASE = '{0,6,11};
/*
 * The drivers are layout as follow (driver 1 and 2 are at the smae place, so
 * they should receive the same data):
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
/* verilator lint_off LITENDIAN */
localparam [0:29] [BUFF_SIZE_LOG-1:0] DRIVER_BASE = '{
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
 * Drivers' LUT.
 *
 * There are two types of driver and for each one a LUT for red and green, and
 * a LUT for blue. Drivers 1 to 20 are part of group 1, drivers 21 to 30 are
 * part of group 0.
 *
 * If a driver starts at address n, his first voxel is at address n, the second
 * one is at address n+5 because of the buffers' layout described above, hence
 * we multiply the index by 5 in the following LUTs.
 */

// UB*D0 and UB*D2
// Red-Green
localparam [0:15] [BUFF_SIZE_LOG-1:0] DRIVER_LUT0_RG = '{
    5*6 ,
    5*7 ,
    5*9 ,
    5*8 ,
    5*10,
    5*11,
    5*13,
    5*12,
    5*14,
    5*15,
    5*1 ,
    5*0 ,
    5*2 ,
    5*3 ,
    5*5 ,
    5*4
};

//Blue
localparam [0:15] [BUFF_SIZE_LOG-1:0] DRIVER_LUT0_B = '{
    5*8 ,
    5*9 ,
    5*14,
    5*15,
    5*12,
    5*13,
    5*2 ,
    5*3 ,
    5*0 ,
    5*1 ,
    5*6 ,
    5*7 ,
    5*4 ,
    5*5 ,
    5*10,
    5*11
};

// UB*D1
// Red-Green
localparam [0:15] [BUFF_SIZE_LOG-1:0] DRIVER_LUT1_RG = '{
    5*2 ,
    5*3 ,
    5*5 ,
    5*4 ,
    5*6 ,
    5*7 ,
    5*9 ,
    5*8 ,
    5*10,
    5*11,
    5*13,
    5*12,
    5*14,
    5*15,
    5*1 ,
    5*0
};

//Blue
localparam [0:15] [BUFF_SIZE_LOG-1:0] DRIVER_LUT1_B = '{
    5*0 ,
    5*1 ,
    5*6 ,
    5*7 ,
    5*4 ,
    5*5 ,
    5*9 ,
    5*11,
    5*8 ,
    5*10,
    5*14,
    5*15,
    5*12,
    5*13,
    5*2 ,
    5*3
};

/* verilator lint_on LITENDIAN */

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller. In the buffers we store only a column
 * for each driver, hence we have to swap buffer when we change the
 * multiplexing.
 */
logic [RAM_DATA_WIDTH-1:0] buffer1 [BUFF_SIZE-1:0];
logic [RAM_DATA_WIDTH-1:0] buffer2 [BUFF_SIZE-1:0];

// The index of the buffer we are currently using
logic current_buffer;
// The write index of the buffer reading the ram
integer write_idx;
// The column we are currently sending (relatively to a driver)
integer mul_idx;
// The led we are currently sending data to
integer led_idx;
// The current bit to send to the driver main controller
integer bit_idx;
// The color (red green or blue) we are currently sending
integer rgb_idx;

// The three following logics help to compute the correct voxel and bit address
/* verilator lint_off UNUSED */
integer color_addr;
/* verilator lint_on UNUSED */
logic [29:0] [BUFF_SIZE_LOG-1:0] voxel_addr;
integer color_bit_idx;
// Indicates that we have written a whole slice in the buffer
logic has_reached_end;
// Start address of the next image to display
integer image_start_addr;
// Indicates which slice we need to read from the ram
integer slice_cnt;
// Indicates that we have sent a column, so we need to fill a new buffer
logic column_sent;

// State entered by the framebuffer when it has sent the whole slice
logic wait_for_next_slice;

/*
 * Read ram to fill the reading buffer.
 *
 * We need to read only a column per driver, thus if we are at column i for the
 * driver j, if we add MULTIPLEXING from here we access column i+MULTIPLEXING
 * which is part of driver j+2.
 */
assign has_reached_end = write_idx == BUFF_SIZE;
assign image_start_addr = slice_cnt*IMAGE_SIZE + RAM_BASE;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        write_idx <= '0;
        ram_addr <= RAM_BASE;
    end else if(stream_ready) begin
        if(~has_reached_end) begin
                ram_addr <= ram_addr + MULTIPLEXING;
                write_idx <= write_idx + 1'b1;
                if(current_buffer) begin
                    buffer1[write_idx] <= ram_data;
                end else begin
                    buffer2[write_idx] <= ram_data;
                end
            // We have sent all data so we fill a new buffer
            end else if(column_sent) begin
                // We will fill the new buffer with the next column
                ram_addr <= image_start_addr + 32'(mul_idx);
                write_idx <= '0;
            end
        //end
    end else begin
        write_idx <= '0;
        ram_addr <= RAM_BASE;
    end

/*
 * There are two types of driver and for each one a LUT for red and green, and
 * a LUT for blue. Drivers 1 to 20 are part of group 1, drivers 21 to 30 are
 * part of group 0. rgb_idx == 0 means that we are sending blue color.
 */
always_comb begin
    for(int i = 0; i < 30; ++i) begin
        if(i < 10 && i >= 20) begin
            voxel_addr[i] = (rgb_idx == 0) ? DRIVER_LUT0_B[led_idx]
                                           : DRIVER_LUT0_RG[led_idx];
        end else begin
            voxel_addr[i] = (rgb_idx == 0) ? DRIVER_LUT1_B[led_idx]
                                           : DRIVER_LUT1_RG[led_idx];
        end
    end
end

/*
 * The color_bit_idx goes from 4 to 0, thus if we add the base address for the
 * green color for instance we get bits 9 to 5.
 */
assign color_bit_idx = (bit_idx > 3) ? bit_idx - 4 : 0;
assign color_addr = color_bit_idx + 32'(COLOR_BASE[rgb_idx]);

always_comb begin
    /*
     * Since we only have 16 bit per led, but the poker mode ask for 27
     * bits, we have to pad with 0.
     */
    data = '0;
    /*
     * If we haven't sent 16 bit yet we don't pad with 0.
     * bit_idx > 3 means that we don't send the 4 first LSB.
     */
    if(stream_ready && driver_ready && bit_idx > 3) begin
        for(int i = 0; i < 30; ++i) begin
            if(current_buffer) begin
                data[i] = buffer2[DRIVER_BASE[i] + voxel_addr[i]][color_addr];
            end else begin
                data[i] = buffer1[DRIVER_BASE[i] + voxel_addr[i]][color_addr];
            end
        end
    end
end

// column_sent indicates that we need to fill a new buffer
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        column_sent <= '0;
    end else begin
        column_sent <= driver_ready && rgb_idx == 2
                                    && led_idx == 0
                                    && bit_idx == 0;
    end

/*
 * Generate counters to send the right data.
 *
 * - mul_idx is the current column
 * - led_idx is the current led
 * - bit_idx is the current bit
 * - rgb_idx is the current color
 *
 * In poker mode we send the MSB of each led first, thus bit_idx is decreased
 * every 16 cycles. When it reaches 0 we change the current column.
 */
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        rgb_idx <= '0;
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= LED_PER_DRIVER-1;
        current_buffer <= '0;
        wait_for_next_slice <= 1'b1;
        slice_cnt <= '0;
    end else if(stream_ready) begin
        if(wait_for_next_slice) begin
             rgb_idx <= '0;
             mul_idx <= '0;
             bit_idx <= POKER_MODE-1;
             led_idx <= LED_PER_DRIVER-1;
             current_buffer <= '0;
             wait_for_next_slice <= ~position_sync;
         end else if(driver_ready) begin
             rgb_idx <= rgb_idx + 1'b1;
             // We have sent the three colors, time to go to the next led
             if(rgb_idx == 2) begin
                 rgb_idx <= '0;
                 led_idx <= led_idx - 1'b1;
                 // We have sent the right bit for each leds in the column
                 if(led_idx == 0) begin
                     led_idx <= LED_PER_DRIVER-1;
                     bit_idx <= bit_idx - 1'b1;
                     // We have sent all the bits for each led
                     if(bit_idx == 0) begin
                         bit_idx <= POKER_MODE-1;
                         // Go to next column, swap buffers
                         mul_idx <= mul_idx + 1'b1;
                         current_buffer <= ~current_buffer;
                         // We have sent the whole slice
                         if(mul_idx == MULTIPLEXING-1) begin
                             mul_idx <= '0;
                             wait_for_next_slice <= 1'b1;
                             /*
                              * Count the number of slices read so far, so we
                              * assert the correct ram address.
                              */
                             slice_cnt <= slice_cnt + 1'b1;
                             if(slice_cnt == SLICES_IN_RAM-1) begin
                                 slice_cnt <= 0;
                             end
                         end
                     end
                 end
             end
         end
     end

endmodule
