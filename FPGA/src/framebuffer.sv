`default_nettype none
module framebuffer (
    input clk,
    input nrst,

    // Data signal for the driver main controller
    output [383:0] data_out,

    /*
     * Sync signal indicating that the driver has sent the data for a whole
     * column, so here we need to swap our buffers.
     */
    input EOC,
    // Position sync signal, indicates that the position has changed
    input SOF,
    output driver_SOF,

    // Ram access
    output [6:0] ram_addr,
    input  [23:0] ram_data,
    output EOR
);

/*
 * The two framebuffers, while one is reading the ram the other is sending
 * data to the driver_main_controller. In the buffers we store only a column
 * for each driver, hence we have to swap buffer when we change the
 * multiplexing.
 */
logic [383:0] buffer1;
logic [383:0] buffer2;

/*
 * Read ram to fill the reading buffer.
 *
 * We need to read only a column per driver, thus if we are at column i for the
 * driver j, if we add MULTIPLEXING from here we access column i+MULTIPLEXING
 * which is part of driver j+2.
 */

// The pixel index of the buffer reading the ram
integer pixel_idx;
// Indicates that we have written a whole column in the buffer
logic has_reached_end;

assign has_reached_end = pixel_idx == 16;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        ram_addr <= '0;
        buffer1 <= '0;
        buffer2 <= '0;
    end else begin
        if(SOF) begin
            ram_addr <= '0;
        end
        if(~has_reached_end) begin
            // We read a column, hence the + 8
            ram_addr <= ram_addr + 8;
            if(write_buffer == 1) begin
                buffer1[383:24] <= buffer1[383-24:0];
                buffer1[23:0] <= ram_data;
            end else begin
                buffer2[383:24] <= buffer2[383-24:0];
                buffer2[23:0] <= ram_data;
            end
        end else begin
            // We want to read the next column
            ram_addr <= mux_cnt[6:0];
        end
    end

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        EOR <= '0;
    end else begin
        EOR <= 0;
        if(has_reached_end && mux_cnt == 8) begin
            EOR <= 1;
        end
    end

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        pixel_idx <= '0;
    end else begin
        if(SOF) begin
            pixel_idx <= '0;
        end
        if(~has_reached_end) begin
            pixel_idx <= pixel_idx + 1'b1;
        end else if(EOC || (pixel_idx == 16 && mux_cnt == 1)) begin
            /*
             * We have sent all data so we fill a new buffer
             * We will fill the new buffer with the next column
             */
            pixel_idx <= '0;
        end
    end

// The index of the buffer we are currently using
logic write_buffer;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        write_buffer <= '0;
    end else if(EOC || (mux_cnt == 0 && pixel_idx == 15)) begin
        write_buffer <= ~write_buffer;
    end

integer mux_cnt;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        mux_cnt <= '0;
    end else begin
        if(SOF) begin
            mux_cnt <= '0;
        end
        if(pixel_idx == 15) begin
            mux_cnt <= mux_cnt + 1;
        end
    end

assign data_out = write_buffer == 1 ? buffer2 : buffer1;

always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        driver_SOF <= '0;
    end else begin
        driver_SOF <= '0;
        if(mux_cnt == 0 && pixel_idx == 15) begin
            driver_SOF <= 1;
        end
    end

endmodule
