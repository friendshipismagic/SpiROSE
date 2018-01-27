module framebuffer #(
    parameter RAM_ADDR_WIDTH=32,
    parameter RAM_DATA_WIDTH=16,
    parameter RAM_BASE=0,
    parameter SLICES_IN_RAM=18
)(
    input clk,
    input nrst,

    // Data signal for the driver main controller
    output [47:0] data_out [29:0],

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

localparam POKER_MODE = 9;
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
localparam integer DRIVER_BASE [0:29] = '{
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
// The current bit to send to the driver main controller
integer bit_idx;

integer color_bit_idx;
// Start address of the next image to display
integer image_start_addr;
// Indicates which slice we need to read from the ram
integer slice_cnt;
// Indicates that we have sent a column, so we need to fill a new buffer
logic column_sent;
// Indicates that we have written a whole slice in the buffer
logic has_reached_end;
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
        end else if(column_sent) begin
            /*
             * We have sent all data so we fill a new buffer
             * We will fill the new buffer with the next column
             */
            ram_addr <= image_start_addr + 32'(mul_idx);
            write_idx <= '0;
        end
    end else begin
        write_idx <= '0;
        ram_addr <= RAM_BASE;
    end

/*
 * The color_bit_idx goes from 4 to 0, thus if we add the base address for the
 * green color for instance we get bits 9 to 5.
 */
assign color_bit_idx = (bit_idx > 3) ? bit_idx - 4 : 0;

always_comb
    for(int i = 0; i < 30; ++i) begin
        data_out[i] = '0;
        if(bit_idx > 3) begin
            for(int led = 0; led < 16; ++led) begin
                data_out[i][3*led]   = buffer1[DRIVER_BASE[i]+5*led][0  + color_bit_idx];
                data_out[i][3*led+1] = buffer1[DRIVER_BASE[i]+5*led][6  + color_bit_idx];
                data_out[i][3*led+2] = buffer1[DRIVER_BASE[i]+5*led][11 + color_bit_idx];
                if(current_buffer) begin
                    data_out[i][3*led]   = buffer2[DRIVER_BASE[i]+5*led][0  + color_bit_idx];
                    data_out[i][3*led+1] = buffer2[DRIVER_BASE[i]+5*led][6  + color_bit_idx];
                    data_out[i][3*led+2] = buffer2[DRIVER_BASE[i]+5*led][11 + color_bit_idx];
                end
            end
        end
    end

// column_sent indicates that we need to fill a new buffer
assign column_sent = driver_ready && bit_idx == 0;

/*
 * Generate counters to send the right data.
 */
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        current_buffer <= '0;
        wait_for_next_slice <= 1'b1;
        slice_cnt <= '0;
    end else if(stream_ready) begin
        if(wait_for_next_slice) begin
             mul_idx <= '0;
             bit_idx <= POKER_MODE-1;
             current_buffer <= '0;
             wait_for_next_slice <= ~position_sync;
         end else if(driver_ready) begin
             bit_idx <= bit_idx - 1'b1;
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
                     if(slice_cnt == SLICES_IN_RAM) begin
                         slice_cnt <= 0;
                     end
                 end
             end
         end
     end

endmodule
