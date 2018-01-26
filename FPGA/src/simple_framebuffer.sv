module simple_framebuffer (
    input clk,
    input nrst,

    // Data signal for the driver main controller
    output data_out,
    input [47:0] data_in,
    input valid,
    /*
     * Sync signal indicating that the driver is ready to receive data,
     * meaning that it has been configured and is not in a blanking cycle.
     */
    input driver_ready,
    // Position sync signal, indicates that the position has changed
    input position_sync
);

localparam MULTIPLEXING = 8;
localparam POKER_MODE = 9;
localparam LED_PER_DRIVER = 16;
localparam BUFF_SIZE = 15*LED_PER_DRIVER;
localparam BUFF_SIZE_LOG = $clog2(BUFF_SIZE);

/* verilator lint_off LITENDIAN */
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

// The led we are currently sending data to
integer led_idx;
// The current bit to send to the driver main controller
integer bit_idx;
// The color (red green or blue) we are currently sending
integer rgb_idx;

// The three following logics help to compute the correct voxel and bit address
/* verilator lint_off UNUSED */
integer voxel_addr;
/* verilator lint_on UNUSED */

/* verilator lint_off WIDTH */
assign voxel_addr = (rgb_idx == 0) ? DRIVER_LUT0_B[led_idx] : DRIVER_LUT0_RG[led_idx];
/* verilator lint_on WIDTH */

always_comb begin
    if(bit_idx > 3) begin
        data_out = data_in[voxel_addr];
    end else begin
        data_out = '0;
    end
end

/*
 * Generate counters to send the right data.
 *
 * - led_idx is the current led
 * - bit_idx is the current bit
 * - rgb_idx is the current color
 *
 * In poker mode we send the MSB of each led first, thus bit_idx is decreased
 * every 16 cycles. When it reaches 0 we change the current column.
 */
logic wait_valid;
logic wait_position_sync;
always_ff @(posedge clk or negedge nrst)
    if(~nrst) begin
        rgb_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= LED_PER_DRIVER-1;
        wait_valid <= '1;
        wait_position_sync <= '1;
    end else begin
        if(wait_valid) begin
             rgb_idx <= '0;
             bit_idx <= POKER_MODE-1;
             led_idx <= LED_PER_DRIVER-1;
             wait_valid <= ~valid;
         end else if (wait_position_sync) begin
             wait_position_sync <= ~position_sync;
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
                         wait_valid <= '1;
                         wait_position_sync <= '1;
                     end
                 end
             end
         end
     end

endmodule
