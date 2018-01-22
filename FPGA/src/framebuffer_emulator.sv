module framebuffer_emulator #(
    parameter POKER_MODE=9,
    parameter BLANKING_CYCLES=72
)(
    input clk_33,
    input nrst,

    // Data signal for the driver main controller
    output [29:0] data,

    // Sync signals
    input driver_ready,
    input new_configuration_ready
);

localparam BUFF_SIZE = 15*LED_PER_DRIVER;
localparam LED_PER_DRIVER = 16;
localparam BUFF_SIZE_LOG = $clog2(BUFF_SIZE);

logic [3:0] led_cnt;
logic [3:0] bit_cnt;
logic [2:0] color_cnt;

logic [15:0] red   = 16'b00000_000000_10000;
logic [15:0] green = 16'b00000_100000_00000;
logic [15:0] blue  = 16'b10000_000000_00000;
logic [15:0] rgb_image [15*16-1:0] = '{
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red
};
logic [15:0] brg_image [15*16-1:0] = '{
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue
};
logic [15:0] gbr_image [15*16-1:0] = '{
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green,
    red  , red  , red  , red  , red  ,
    blue , blue , blue , blue , blue ,
    green, green, green, green, green
};

localparam [2:0] [15:0] COLOR_BASE = '{0,6,11};
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

// The column we are currently sending (relatively to a driver)
logic [2:0] mul_idx;
// The led we are currently sending data to
logic [$clog2(LED_PER_DRIVER)-1:0] led_idx;
// The current bit to send to the driver main controller
logic [$clog2(POKER_MODE)-1:0] bit_idx;
// The color (red green or blue) we are currently sending
logic [1:0] rgb_idx;

// The three following logics help to compute the correct voxel and bit address
logic [15:0] color_addr;
logic [29:0] [BUFF_SIZE_LOG-1:0] voxel_addr;
logic [$clog2(POKER_MODE)-1:0] color_bit_idx;

integer animation_cnt;
always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        animation_cnt <= '0;
    end else begin
        animation_cnt <= animation_cnt + 1'b1;
        if (animation_cnt == 33_000_000) begin
            animation_cnt <= '0;
        end
    end
/*
 * There are two types of driver and for each one a LUT for red and green, and
 * a LUT for blue. Drivers 1 to 20 are part of group 1, drivers 21 to 30 are
 * part of group 0. rgb_idx == 0 means that we are sending blue color.
 */
always_comb begin
    for(int i = 0; i < 30; ++i) begin
        if(i < 20) begin
            voxel_addr[i] = (rgb_idx == 0) ? DRIVER_LUT1_B[led_idx]
                                           : DRIVER_LUT1_RG[led_idx];
        end else begin
            voxel_addr[i] = (rgb_idx == 0) ? DRIVER_LUT0_B[led_idx]
                                           : DRIVER_LUT0_RG[led_idx];
        end
    end
end

/*
 * The color_bit_idx goes from 4 to 0, thus if we add the base address for the
 * green color for instance we get bits 9 to 5.
 */
assign color_bit_idx = (bit_idx > 3) ? bit_idx - 4 : 0;
assign color_addr = color_bit_idx + 4'(COLOR_BASE[rgb_idx]);

always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        data <= '0;
    end else begin
        /*
         * Since we only have 16 bit per led, but the poker mode ask for 27
         * bits, we have to pad with 0.
         */
        data <= '0;
        /*
         * If we haven't sent 16 bit yet we don't pad with 0.
         * bit_idx > 3 means that we don't send the 4 first LSB.
         */
        if(driver_ready && bit_idx > 3) begin
            for(int i = 0; i < 30; ++i) begin
                if(animation_cnt < 11_000_000) begin
                    data[i] <= rgb_image[DRIVER_BASE[i] + voxel_addr[i]][color_addr];
                end else if (animation_cnt > 11_000_000 && animation_cnt < 22_000_000) begin
                    data[i] <= brg_image[DRIVER_BASE[i] + voxel_addr[i]][color_addr];
                end else begin
                    data[i] <= gbr_image[DRIVER_BASE[i] + voxel_addr[i]][color_addr];
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
 * - rgb_idx is the current color
 *
 * In poker mode we send the MSB of each led first, thus bit_idx is decreased
 * every 16 cycles. When it reaches 0 we change the current column.
 */
always_ff @(posedge clk_33 or negedge nrst)
    if(~nrst) begin
        rgb_idx <= '0;
        mul_idx <= '0;
        bit_idx <= POKER_MODE-1;
        led_idx <= 4'(LED_PER_DRIVER-1);
    end else if(driver_ready) begin
        rgb_idx <= rgb_idx + 1'b1;
        // We have sent the three colors, time to go to the next led
        if(rgb_idx == 2) begin
            rgb_idx <= '0;
            led_idx <= led_idx - 1'b1;
            // We have sent the right bit for each leds in the column
            if(led_idx == 0) begin
                led_idx <= 4'(LED_PER_DRIVER-1);
                bit_idx <= bit_idx - 1'b1;
                // We have sent all the bits for each led
                if(bit_idx == 0) begin
                    bit_idx <= POKER_MODE-1;
                    // Go to next column, swap buffers
                    mul_idx <= mul_idx + 1'b1;
                    // We have sent the whole slice
                    if(mul_idx == 8) begin
                        mul_idx <= '0;
                    end
                end
            end
        end
    end


endmodule
